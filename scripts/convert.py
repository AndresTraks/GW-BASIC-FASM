"""Translate the MASM sources to fasm, overwriting the .ASM files and headers
in the repository root, and write the two generated files that let fasm build
the image on its own: GWBASIC.ASM (the master, which INCLUDEs every module in
link order) and GWSTUB.INC (the OEM stubs and counter seeds).

After this has run, assemble.sh / assemble.bat build the image with fasm alone;
Python is only needed to redo the conversion.

The originals are read out of git (common.BASELINE), not from the working tree,
so this is re-runnable and does not depend on the tree's current state.
"""
import io, json, os, re, sys
from common import SRC, OUT, HEADERS, BASELINE, pristine_dir, translate, need_src
import headers, units

def esc(n): return "@" + n.replace("@", "@@").replace("$", "@S").replace("?", "@Q")

def segment_blocks(txt):
    """Turn the translator's ";;;SEG" markers into "if @GW_PASS" guards.

    The image is CSEG followed by DSEG, so every DSEG byte has to be emitted
    after every CSEG byte -- fasm writes its binary output in emission order,
    and org only changes label values.  But the modules have to be processed in
    document order for their "=" assignments to come out right.  Both hold if
    each module is INCLUDEd twice: once with @GW_PASS = 1, which emits only its
    code, and once with @GW_PASS = 2, which emits only its data at org 0 so the
    data labels are segment-relative.

    Macro definitions and calls are preprocessor-level in fasm, so they are
    processed in both passes regardless of which branch the assembler takes;
    only the emitting lines and the "=" assignments are actually skipped.
    """
    out, buf, seg = [], [], "CSEG"
    def flush():
        if any(l.strip() and not l.lstrip().startswith(";") for l in buf):
            out.append("if @GW_PASS = %d" % (1 if seg == "CSEG" else 2))
            out.extend(buf)
            out.append("end if")
        else:
            out.extend(buf)
    for l in txt.split("\n"):
        if l.startswith(";;;SEG "):
            flush(); seg = l.split()[1]; buf = []
            continue
        buf.append(l)
    flush()
    return "\n".join(out)

# Two references cannot be expressed the way LINK expressed them, and are
# rewritten here.  Both are documented in scripts/README.md.
PATCH = {
 # GWINIT declares BEGDSG as EXTRN :NEAR although it lives in the data segment,
 # so that "OFFSET BEGDSG" yields the distance from the start of CSEG to the
 # start of DSEG -- one symbol with two values, which LINK's separate frames
 # allowed and a single flat address space cannot.  Point it at the real
 # distance instead.
 "GWINIT.ASM": [("@INS86\t272,,@BEGDSG", "@INS86\t272,,@GWBASIC_DSEG_BASE")],
 # RAMLOW is assigned in both of GWDATA's phases: once in CSEG, marking the
 # master copy of the constants, and once in DSEG, marking where GWINIT copies
 # them to.  GWINIT wants the DSEG one, so drop the CSEG assignment (the first
 # of the two) and let the reference resolve forward to the DSEG value.
 "GWDATA.ASM": [("once", "\t@RAMLOW=$", "")],
 # The last entry of the DERMAK chain is followed by "ORG $-1", which in MASM
 # overwrites the chain's final skip byte with the JMP after it.  fasm cannot
 # rewind its output -- it would emit both, leaving a stray 0B9h and shifting
 # every later byte -- so the last entry uses a variant macro that does not emit
 # the byte at all, and the ORG goes away.
 "GWMAIN.ASM": [("\t@DERMAK\t,FAE", "\t@DERMAK_END\t,FAE"), ("\tORG\t$-1\n", "")],
 # GWRAM's R1 defines its label one byte BEFORE the storage it reserves, by
 # MASM's "ORG $-1 / LABEL / ORG $+1".  The translator drops ORG from macro
 # bodies, which left R1 textually identical to R and put MAXUPD and MINUPD one
 # byte too high; both are read by other modules.  State the offset directly.
 # FKYFMT has to hand GETFMT a pointer GETFMT then reads through DS, so the
 # three bytes of soft-key display format belong in GWRAM, beside the rest of
 # the key line's state.  Nothing in the original reserved them: they are what
 # the reconstructed OEM layer needs, and a hand edit here would be lost the
 # next time this script ran.
 "GWRAM.ASM": [("re", r"(macro @R1 NAME,SIZE \{(?:[^}]*?))  label NAME word",
                r"\1  NAME = $ - 1"),
               ("\t@RINIT\tACTPAG,1  ;Active page",
                "\t@RINIT\t@FKYFMB,3  ;Soft-key display format, filled in by the OEM\n"
                "\tDB\t6,10,1  ;  routine FKYFMT: chars/key, keys, first key.  It\n"
                "\t;  lives here because GETFMT reads it through DS.\n"
                "\t@RINIT\tACTPAG,1  ;Active page")],
}

def patch(name, text):
    for item in PATCH.get(name, []):
        if len(item) == 2:
            a, b = item
            if a not in text: sys.exit("%s: nothing to patch for %r" % (name, a))
            text = text.replace(a, b)
        elif item[0] == "re":
            _, a, b = item
            text, n = re.subn(a, b, text, count=1)
            if n != 1: sys.exit("%s: regex patch %r matched %d times" % (name, a, n))
        else:
            _, a, b = item
            if text.count(a) != 2:
                sys.exit("%s: expected %r twice, found %d" % (name, a, text.count(a)))
            text = text.replace(a, b, 1)        # drop the CSEG-phase one only
    return text

need_src()
orig = pristine_dir()
print("originals from %s" % BASELINE)

# Headers first: every module INCLUDEs them.
for h in HEADERS:
    dst = os.path.join(SRC, h)
    r = translate(os.path.join(orig, h), dst, "header", env={"M2F_HDRS": orig})
    if r.returncode: sys.exit("%s: %s" % (h, r.stderr.strip()[-300:]))
    headers.finish(dst, h)
print("headers:  %s" % " ".join(HEADERS))

# MASM macros are file-scoped.  Concatenating the modules would let one module's
# macro shadow a same-named label in another (GENGRP's NEGHL), so each unit ends
# by purging them; the next module's own INCLUDE redefines what it needs.
MACROS = [x for x in json.load(io.open(os.path.join(OUT, "macros.json")))
          if re.match(r"^[A-Za-z_$?@][\w$?@]*$", x)]
BARRIER = ["purge " + esc(v) for x in MACROS for v in sorted({x, x.upper(), x.lower()})]

def emit(path, text, last):
    text = patch(os.path.basename(path), segment_blocks(text)).strip("\n")
    if last:
        text += "\n\n; ---- end of translation unit: drop its file-scoped macros ----\n"
        text += "\n".join(BARRIER)
    io.open(path, "w", encoding="latin-1").write(text + "\n")

# Modules, in single-unit mode: locals carry a module tag so that concatenating
# them cannot merge two different MASM symbols that share a name.
n = 0
for unit, files in units.units(orig):
    env = dict(M2F_UNIT="1", M2F_MOD=unit, M2F_HDRS=orig,
               M2F_GLOBALS=os.path.join(OUT, "globals.json"))
    if len(files) == 1:
        dst = os.path.join(SRC, files[0])
        r = translate(os.path.join(orig, files[0]), dst, "header", env=env)
        if r.returncode: sys.exit("%s: %s" % (files[0], r.stderr.strip()[-300:]))
        emit(dst, io.open(dst, encoding="latin-1").read(), last=True)
        n += 1
        continue
    # A joined unit is translated as one stream, then cut back apart, so that
    # the later files see the symbols and radix the earlier ones establish.
    # SUBTTL survives translation as a comment, which makes it a usable marker.
    joined = os.path.join(OUT, unit + ".joined")
    parts = [io.open(os.path.join(orig, f), encoding="latin-1").read() for f in files]
    io.open(joined, "w", encoding="latin-1").write(
        ("\n\tSUBTTL\t" + units.SPLIT + "\n").join(parts))
    out = os.path.join(OUT, unit + ".joined.fasm")
    r = translate(joined, out, "header", env=env)
    if r.returncode: sys.exit("%s: %s" % (unit, r.stderr.strip()[-300:]))
    chunks = io.open(out, encoding="latin-1").read().split(units.SPLIT)
    if len(chunks) != len(files):
        sys.exit("%s: split marker produced %d chunks, expected %d"
                 % (unit, len(chunks), len(files)))
    for i, (f, c) in enumerate(zip(files, chunks)):
        if i < len(chunks) - 1:                    # drop the dangling marker comment
            c = re.sub(r"\n;\s*SUBTTL\s*$", "", c)
        emit(os.path.join(SRC, f), c, last=(i == len(chunks) - 1))
        n += 1
print("modules:  %d files converted in place" % n)

# ---------------------------------------------------------------------------
# The two generated files that let fasm build the image unaided.

def oem_missing():
    """EXTRNs that no module makes PUBLIC: the OEM-supplied driver layer, which
    this repository does not contain.  An EXTRN is satisfied only by a PUBLIC --
    a private label of the same name in some other module does not satisfy it,
    which is exactly the TRMCOM case (GIOCOM imports the OEM routine, GWSTS has
    an unrelated private label)."""
    pub, ext, built = set(), set(), set()
    for f in sorted(x for x in os.listdir(orig) if x.endswith(".ASM")):
        for l in io.open(os.path.join(orig, f), encoding="latin-1"):
            l = l.replace("\r", "").split(";")[0]
            m = re.match(r"^\s*(PUBLIC|EXTRN)\s+(.*)$", l, re.I)
            if m:
                for it in m.group(2).split(","):
                    nm = it.split(":")[0].strip().upper()
                    if nm: (pub if m.group(1).upper() == "PUBLIC" else ext).add(nm)
                continue
            # GIOTBL's DEV/NDEV macros define the device ids ($_KYBD, $_LPT1,
            # ...) as "$_&NAM = NUM", numbering down from 377o.  Stubbing those
            # to 0 would silently give every device the disk's id.
            m = re.match(r"^\s*DEV\s+([A-Za-z][\w]*)\s*,", l)
            if m: built.add("$_" + m.group(1).upper())
            m = re.match(r"^\s*NDEV\s+([A-Za-z][\w]*)\s*,", l)
            if m:
                for k in range(1, 5): built.add("$_%s%d" % (m.group(1).upper(), k))
            # names the table macros declare PUBLIC inside their own bodies
            for pat, pre in ((r"^\s*(?:T|Q|QF|R|R2)\s+([^\s,]+)", "$"),
                             (r"^\s*(?:T|Q|QF|R|R2)\s+([^\s,]+)", ""),
                             (r"^\s*(?:R|R1|RINIT)\s+([A-Za-z_$?@][\w$?@]*)\s*,", ""),
                             (r"^\s*DERMAK\s+([A-Za-z_$?@][\w$?@]*)", "DER")):
                m = re.match(pat, l)
                if m: built.add(pre + m.group(1).strip().upper())
    return sorted(n for n in ext if n not in (pub | built))

# GWOEM.ASM is hand written, not translated: it is the text-mode part of the
# OEM-supplied layer, which is absent from the released source.  Whatever it
# defines must not also be stubbed.
OEMSRC = os.path.join(SRC, "GWOEM.ASM")
provided = set()
if os.path.exists(OEMSRC):
    for l in io.open(OEMSRC, encoding="latin-1"):
        m = re.match(r"^@([A-Za-z_$?@][\w$?@]*):", l) or \
            re.match(r"^@([A-Za-z_$?@][\w$?@]*)\s+d[bwd]\b", l)
        if m: provided.add(m.group(1).upper())

OEM = [n for n in oem_missing() if n not in provided]
order = [f for _, fs in units.units(orig) for f in fs]
# GWOEM holds resident drivers, so it goes before the discardable tail.
if os.path.exists(OEMSRC):
    order.insert(order.index(units.TAIL[0] + ".ASM"), "GWOEM.ASM")
alltext = "\n".join(io.open(os.path.join(SRC, f), encoding="latin-1").read() for f in order)
alltext += "\n".join(io.open(os.path.join(SRC, h), encoding="latin-1").read() for h in HEADERS)
# MASM lets "X=X+1" run before any plain "X=", so a counter that accumulates
# has to start somewhere.  Only those are seeded: seeding a name that is merely
# assigned would DEFINE it as 0, and fasm's "=" is positional, so an earlier
# reference would read the 0 instead of resolving forward to the real value on
# a later pass.  GWDATA computes "CNSLEN = ENDCNS - CONSTR" before either exists
# -- seeding those gave a constants block of length zero.
seeds = set()
for m in re.finditer(r"(?m)^\s*(@[\w@$?]*)\s*=([^=].*)$", alltext):
    name, rhs = m.group(1), m.group(2)
    if re.search(r"(?<![\w@$?])" + re.escape(name) + r"(?![\w@$?])", rhs):
        seeds.add(name)                 # self-referential: needs a starting value
seeds = sorted(seeds - {"@GWBASIC_CSEG_END", "@GWBASIC_DSEG_SIZE",
                        "@GWBASIC_DSEG_BASE", "@GW_PASS"})

io.open(os.path.join(SRC, "GWSTUB.INC"), "w", encoding="latin-1").write(
    "; Generated by scripts/convert.py -- do not edit.\n"
    "\n; The OEM-supplied driver layer is not part of this repository: %d symbols\n"
    "; that the sources themselves label as OEM supplied have no definition.\n"
    "; Stubbed to 0, so every call into the driver targets offset 0.\n"
    "; scripts/README.md lists them by group.\n\n" % len(OEM)
    + "\n".join("%s = 0" % esc(n) for n in OEM)
    + "\n\n; Assembly-time counters, seeded because MASM allows a read before the\n"
      "; first assignment.  Each module reassigns the ones it uses.\n\n"
    + "\n".join("%s = 0" % s for s in seeds) + "\n")

io.open(os.path.join(SRC, "GWBASIC.ASM"), "w", encoding="latin-1").write(
    "; Generated by scripts/convert.py -- do not edit.\n"
    ";\n"
    "; GW-BASIC, assembled as one translation unit.  fasm has no linker, so the\n"
    "; modules are INCLUDEd here in link order rather than assembled separately:\n"
    "; GWDATA first, because it opens the code segment at offset 0 with BEGCSG\n"
    "; and does the \"ORG 400O\" that leaves room for the OS control block, with\n"
    "; START right after.\n"
    ";\n"
    "; ITSA86, GWINIT and BIBOOT last, in that order, because MAPINI moves the\n"
    "; data segment on top of everything that follows ITSA86's CSEND -- that is\n"
    "; how GW-BASIC reclaims the memory its initialisation code occupies -- so\n"
    "; only initialisation code may be linked there.  See scripts/units.py.\n"
    ";\n"
    "; The image is one flat CSEG followed by DSEG.  GWINIT derives DS from CS at\n"
    "; run time (DS = CS + offset(BEGDSG)/16), so both have to live in one 64K\n"
    "; segment; they measure about 44K and 2K respectively.\n"
    ";\n"
    "; Build with assemble.sh or assemble.bat.\n\n"
    "format binary as 'com'\n"
    "use16\n"
    "org 0\n\n"
    "@CPM86 = 0\n\n"
    "include 'GWSTUB.INC'\n\n"
    "; Pass 1 emits the code segment.  Every module is INCLUDEd again below for\n"
    "; pass 2, which emits the data segment: fasm writes its output in emission\n"
    "; order, so all of CSEG has to be emitted before any of DSEG, while the\n"
    "; modules still have to be processed in document order for their \"=\"\n"
    "; assignments to resolve the way MASM resolved them.\n\n"
    "@GW_PASS = 1\n\n"
    + "\n".join("include '%s'" % f for f in order)
    + "\n\n"
      "; DSEG starts at the next paragraph, because GWINIT computes DS as\n"
      "; CS + offset(BEGDSG)/16 and that division has to be exact.\n"
      "align 16\n"
      "@GWBASIC_CSEG_END = $\n"
      "@GWBASIC_DSEG_BASE = @GWBASIC_CSEG_END\n\n"
      "; Pass 2 emits the data segment at org 0, so its labels are segment\n"
      "; relative while its bytes land after the code in the file.\n"
      ";\n"
      "; The first 100h bytes of DSEG are the program segment prefix that GWINIT\n"
      "; has MS-DOS copy there (INT 21h, AH=26h), so nothing is assembled into\n"
      "; them -- but they still occupy space, and fasm does not pad for an org\n"
      "; jump, so they are reserved explicitly.  org is then reset to 0 to put\n"
      "; BEGDSG at the start of the segment, where GWINIT expects it.\n"
      "@GW_PASS = 2\n"
      "org 0\n"
      "db 100h dup 0\n"
      "org 0\n\n"
    + "\n".join("include '%s'" % f for f in order)
    + "\n\n@GWBASIC_DSEG_SIZE = $\n")
print("generated: GWBASIC.ASM (%d includes), GWSTUB.INC (%d OEM stubs, %d counters)"
      % (len(order), len(OEM), len(seeds)))
print("GWOEM.ASM provides %d of the OEM symbols" % len(provided & set(oem_missing())))
