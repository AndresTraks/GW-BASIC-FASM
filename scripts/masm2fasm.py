"""MASM (GW-BASIC 1983) -> fasm.  Total, context-free symbol naming."""
import io, os, re, sys, json

src, dst, tabf, HEADER = sys.argv[1], sys.argv[2], sys.argv[3], (len(sys.argv) > 4 and sys.argv[4] == "header")
D = os.path.dirname(dst)
SYM = {k.upper(): v for k, v in json.load(io.open(tabf)).items()}
MACROS = {m.upper() for m in json.load(io.open(os.path.join(os.path.dirname(tabf), "macros.json")))}
REGS = set("AX BX CX DX SI DI BP SP AL AH BL BH CL CH DL DH ES CS SS DS".split())
JUMPS = re.compile(r"(?i)^(jmp|call|loop|loope|loopne|loopz|loopnz|jcxz|j[a-z]{1,3})$")
DATADEF = re.compile(r"(?i)^(db|dw|dd|dq|dt)$")
COMMA = {'Q', 'QF', 'T', 'R', 'R2', 'UN_DEF', 'RESCHARS', 'DERMAK'}
FRAG = {'Q': {0}, 'QF': {0}, 'T': {0}, 'R': {0}, 'R2': {0, 1},
        'UN_DEF': {0}, 'RESCHARS': {0}, 'DERMAK': {0}}
# Fragment positions the macro also emits as a whole symbol ("dw @#RESWRD"):
# the name itself is a forward reference into another module and needs a seed.
VALFRAG = {'R': {0}, 'R2': {1}}
# Macros that emit the word's characters: they get the original MASM token
# appended as a string literal, because the escaped name is not the text.
TEXTARG = {'Q': 0, 'QF': 0}
NOOP = ("ADD_EXT", "DO_EXT", "DEF_MAC", "EXPAND_MAC", "?Z0")

# --- the one naming rule -----------------------------------------------------
# Every symbol becomes "@"+escape(name).  '@' occurs in no GW-BASIC identifier,
# so the map is injective, and every result starts with '@', so no symbol can
# ever be a fasm keyword.  One MASM token -> exactly one fasm name, always.
UNIT = os.environ.get("M2F_UNIT")
MOD  = os.environ.get("M2F_MOD", "")
# Where the ORIGINAL MASM headers live.  Their "=" constants and ROFFST record
# offsets have to be known before a module can be translated, and in-place
# conversion overwrites the copies next to the output, so the pristine ones are
# read from here instead.
HDRS = os.environ.get("M2F_HDRS")
def _hdrsrc(h):
    return os.path.join(HDRS, h) if HDRS else os.path.join(D, h + ".src")

CSDATA = set()
if os.environ.get("M2F_CSDATA") and os.path.exists(os.environ["M2F_CSDATA"]):
    CSDATA = {n.upper() for n in json.load(io.open(os.environ["M2F_CSDATA"]))}

GLOB = set()
if UNIT:
    GLOB = {n.upper() for n in json.load(io.open(os.environ["M2F_GLOBALS"]))[MOD]}

def ESC(n):
    return n.replace("@", "@@").replace("$", "@S").replace("?", "@Q")

def FNAME(n):
    e = ESC(n)
    if not UNIT: return "@" + e
    u = n.upper()
    # Assembly-time names, not linked symbols: macros, "=" counters and the
    # ROFFST record offsets.  Every module re-INCLUDEs the headers that define
    # them, and the hand-written header macros reference them unqualified.
    if u in MACROS or u in NOMANGLE: return "@" + e
    if u in GLOB: return "@" + e
    # MASM scopes every other label to its file.  "??Lnnn" (emitted by
    # Microsoft's 8080->8086 translator, numbered from 000 per file) land here.
    # "@_" cannot occur in ESC output -- it only ever emits "@@", "@S" or "@Q"
    # after an "@" -- so a tagged local can never collide with a global.
    return "@%s@_%s" % (MOD, e)

def split_comment(l):
    q = None
    for i, c in enumerate(l):
        if q:
            if c == q: q = None
        elif c in "'\"": q = c
        elif c == ';': return l[:i], l[i+1:]
    return l, ""

def strings_out(s):
    lits = []
    def grab(m):
        lits.append(m.group(0)); return "\x01%d\x01" % (len(lits) - 1)
    return re.sub(r"'[^']*'|\"[^\"]*\"", grab, s), lits
def strings_in(s, lits):
    return re.sub(r"\x01(\d+)\x01", lambda m: lits[int(m.group(1))], s)

t = io.open(src, "rb").read().replace(b"\x00", b"").replace(b"\x1a", b"").decode("latin-1").replace("\r", "")
def _as_comment(m):
    return "\n".join(("; " + l.rstrip()) if l.strip() else ";" for l in m.group(0).split("\n"))
# COMMENT blocks hold the copyright notices; keep them as fasm comments
t = re.sub(r"(?mi)^\s*COMMENT\s*(\S).*?\1", _as_comment, t, flags=re.S)

# everything this file defines, so references to it get renamed too
NOMANGLE = set()
HDRCOUNT = set()          # "=" names the headers define; every module re-INCLUDEs them
LOCALDEF, COUNTERS = set(), set()
for _l in t.split("\n"):
    _b = split_comment(_l)[0]
    for _p in (r'^\s*([A-Za-z_$?@][\w$?@]*)\s*:', r'^\s*([A-Za-z_$?@][\w$?@]*)\s*=[^=]',
               r'^\s*([A-Za-z_$?@][\w$?@]*)\s+(?:DB|DW|DD|DQ|DT|LABEL|EQU|MACRO)\b',
               r'^\s*R\s+([A-Za-z_$?@][\w$?@]*)\s*,', r'^\s*EXTRN\s+(.*)$'):
        _m = re.match(_p, _b, re.I)
        if _m:
            for _n in re.split(r'[\s,:]+', _m.group(1)):
                if _n and _n.upper() not in ("NEAR", "FAR", "WORD", "BYTE", "ABS"):
                    LOCALDEF.add(_n.upper())
            break
    _m = re.match(r'^\s*([A-Za-z_$?@][\w$?@]*)\s*=[^=]', _b)
    if _m: COUNTERS.add(_m.group(1))
# counters assigned only inside header macros are read before first assignment
for _h in ("OEM.H", "GIO86U", "MSDOSU", "BINTRP.H", "IBMRES.H"):
    _p = _hdrsrc(_h)
    if not os.path.exists(_p): continue
    _tx = io.open(_p, "rb").read().replace(b"\x00", b"").replace(b"\x1a", b"").decode("latin-1")
    # ROFFST's parameter is literally named NAME and its body says "NAME=_OFFST";
    # a parameter is substituted at expansion, so it is never a counter.
    _params = set()
    for _m in re.finditer(r"(?im)^\s*[A-Za-z_$?@][\w$?@]*\s+MACRO\s*(.*)$", _tx):
        for _q in re.split(r"[,\s]+", split_comment(_m.group(1))[0].strip()):
            if _q: _params.add(_q.upper())
    for _m in re.finditer(r"(?im)^\s*([A-Za-z_$?@][\w$?@]*)\s*=[^=]", _tx):
        if _m.group(1).upper() not in _params:
            COUNTERS.add(_m.group(1)); HDRCOUNT.add(_m.group(1).upper())
# names this module defines for real (label, LABEL, data) -- as opposed to
# names it merely assigns with '=', which do need a 0 seed.
LABELDEF = set()
for _l in t.split("\n"):
    _b = split_comment(_l)[0]
    for _p2 in (r'^\s*([A-Za-z_$?@][\w$?@]*)\s*:',
                r'^\s*([A-Za-z_$?@][\w$?@]*)\s+(?:DB|DW|DD|DQ|DT|LABEL)\b'):
        _m = re.match(_p2, _b, re.I)
        if _m: LABELDEF.add(_m.group(1).upper()); break

HDRDEF = set()
for _h in ("OEM.H", "GIO86U", "MSDOSU", "BINTRP.H", "IBMRES.H"):
    _p = _hdrsrc(_h)
    if os.path.exists(_p):
        _tx = io.open(_p, "rb").read().replace(b"\x00", b"").replace(b"\x1a", b"").decode("latin-1")
        for _m in re.finditer(r"(?im)^\s*ROFFST\s+([A-Za-z_$?@][\w$?@]*)", _tx):
            HDRDEF.add(_m.group(1).upper())
RENAMESET = set(SYM) | MACROS | LOCALDEF | HDRDEF | {c.upper() for c in COUNTERS}
NOMANGLE |= HDRDEF | HDRCOUNT | {"CPM86"}

def _want(n, skip):
    if n.upper() in skip: return False
    # A token carrying '$' or '?' can only be a GW-BASIC identifier: MASM uses
    # them bare as location counter / uninitialised, never inside a keyword.
    # Renaming these unconditionally picks up the names the T/Q/R table macros
    # build by concatenation, which no textual scan of the source can see.
    if len(n) > 1 and ("$" in n or "?" in n): return True
    return n.upper() in RENAMESET and n != n.lower()

def rename(txt, skip=()):
    return re.sub(r'[A-Za-z_$?@][A-Za-z0-9_$?@]*',
                  lambda m: FNAME(m.group(0)) if _want(m.group(0), skip) else m.group(0), txt)

NEEDSTUB, CONSTS = set(), {}
for _h in ("OEM.H", "GIO86U", "MSDOSU"):
    _p = os.path.join(D, _h)
    if os.path.exists(_p):
        for _l in io.open(_p, encoding="latin-1"):
            _m = re.match(r'^\s*@?([A-Za-z_][\w]*)\s*=\s*(-?\d+)\s*$', split_comment(_l)[0])
            if _m: CONSTS[_m.group(1).upper()] = _m.group(2)

def stub(n):
    if n.upper() not in LOCALDEF: NEEDSTUB.add(n)

def mem(op):
    """Bracket a memory operand, adding the CS: override that MASM's ASSUME
    would have supplied for data that lives in the code segment."""
    base = re.match(r"^([A-Za-z_$?@][\w$?@]*)", op)
    if base and base.group(1).upper() in CSDATA:
        return "[cs:%s]" % op
    return "[%s]" % op

def operand(op, allow_mem):
    op = op.strip()
    if not op: return op
    pre = ""
    m = re.match(r"(?i)^(BYTE|WORD|DWORD)\s+(?:PTR\s+)?(.*)$", op)
    if m:
        pre, op = m.group(1).lower() + " ", m.group(2).strip()
        # An explicit size override always denotes memory in MASM, including on
        # a jump or call -- "JMP WORD PTR IOJUMP" is an indirect jump through
        # that word.  Jump operands are otherwise labels, so bracketing is off
        # for them; without this they become DIRECT jumps to the variable's
        # address, which still assembles and lands in the middle of whatever is
        # at that offset.
        allow_mem = True
    m = re.match(r"(?i)^OFFSET\s+(.*)$", op)
    if m:
        _t = m.group(1).strip()
        if re.match(r"^[A-Za-z_$?@][\w$?@]*$", _t) and _t.upper() in SYM: stub(_t)
        return pre + _t
    m = re.match(r"(?i)^LOW\s+(.*)$", op)
    if m: return pre + "((%s) and 0FFh)" % operand(m.group(1), False)
    m = re.match(r"(?i)^HIGH\s+(.*)$", op)
    if m: return pre + "(((%s) shr 8) and 0FFh)" % operand(m.group(1), False)
    if op.startswith("[") or op.startswith("\x01"): return pre + op
    m = re.match(r"(?i)^(CS|DS|ES|SS):(.*)$", op)
    if m:
        seg, rest = m.group(1).lower(), m.group(2).strip()
        mm = re.match(r"^(.*?)\s*\[(.+)\]$", rest)
        if mm and mm.group(1).strip():
            d, r = mm.group(1).strip(), mm.group(2).strip()
            if d.startswith("-"): return pre + "[%s:%s%s]" % (seg, r, d)
            if d[0].isdigit():    return pre + "[%s:%s+%s]" % (seg, r, d)
            return pre + "[%s:%s+%s]" % (seg, d, r)
        if rest.startswith("["): return pre + "[%s:%s" % (seg, rest[1:])
        return pre + "[%s:%s]" % (seg, rest)
    m = re.match(r"^(.*?)\s*\[(.+)\]$", op)
    if m and m.group(1).strip():
        base, idx = m.group(1).strip(), m.group(2).strip()
        if base.startswith("-"): return pre + mem("%s%s" % (idx, base))
        if base[0].isdigit():    return pre + mem("%s+%s" % (idx, base))
        return pre + mem("%s+%s" % (base, idx))
    if re.match(r"^[A-Za-z_$?@][\w$?@]*$", op):
        kind = SYM.get(op.upper())
        if pre and allow_mem:            stub(op); return pre + mem(op)
        if kind == 'data' and allow_mem: stub(op); return pre + mem(op)
        if op.upper() in SYM:            stub(op)
        return pre + op
    m = re.match(r"^([A-Za-z_$?@][\w$?@]*)\s*[-+]", op)
    if m and allow_mem and (pre or SYM.get(m.group(1).upper()) == 'data'):
        stub(m.group(1)); return pre + mem(op)
    return pre + op

# --- main pass ---------------------------------------------------------------
out, externs, radix, depth, swallow, blocks, toplevel = [], [], 10, 0, 0, [], []
segstack = ["CSEG"]
CURPARAMS, DEFMACRO, CURMACRO = [], {}, ''
LOCALMACROS = set()
FRAGSEEN = {}

def valfragof(nm):
    return set() if nm in LOCALMACROS else VALFRAG.get(nm, set())

def fragof(nm):
    # A module that defines its own macro of this name sets its own convention;
    # the header's FRAG table must not leak in (GWRAM's R *defines* its
    # argument, IBMRES.H's R builds a name fragment from it).
    if nm in LOCALMACROS: return FRAGSEEN.get(nm, set())
    return FRAGSEEN.get(nm, FRAG.get(nm, set()))
if not re.search(r'(?im)^\s*\.RADIX', t) and not re.search(r'(?im)^\s*INCLUDE', t):
    radix = 8                      # a continuation file inherits OEM.H's radix

def num(v):
    if v[-1] in "Dd": return str(int(v[:-1], 10))
    if v[-1] in "Oo": return str(int(v[:-1], 8))
    return str(int(v, radix))
NUMRE = r"(?<![\w.$#])\d+[DdOo](?![\w])|(?<![\w.$#])\d+(?![\w])"

for line in t.split("\n"):
    body, cmt = split_comment(line)
    body = body.rstrip()
    mdef = re.match(r"(?i)^\s*([A-Za-z_$?@][\w$?@&%]*)\s+MACRO\s*(.*)$", body)
    if depth == 0 and not swallow and mdef and mdef.group(1).upper() in NOOP:
        swallow = 1
        # sorted, not set order: Python randomises that per process and the
        # converted files must be reproducible
        for _nm in sorted({FNAME(mdef.group(1)), FNAME(mdef.group(1).upper())}):
            out.append("macro %s {}" % _nm)
        continue
    if swallow:
        if re.match(r"(?i)^\s*[A-Za-z_$?@&%][\w$?@&%]*\s+MACRO\b", body) or \
           re.match(r"(?i)^\s*(REPT|IRP|IRPC)\b", body): swallow += 1
        elif re.match(r"(?i)^\s*&?ENDM\b", body): swallow -= 1
        continue
    if depth == 0 and mdef:
        args = split_comment(mdef.group(2))[0].strip()
        CURMACRO, CURPARAMS = mdef.group(1), [p.strip().upper() for p in re.split(r'[,\s]+', args) if p.strip()]
        out.append("macro %s %s{" % (FNAME(CURMACRO), (args + " ") if args else ""))
        LOCALMACROS.add(CURMACRO.upper())
        blocks, depth = ["macro"], 1
        continue
    if depth:
        rep = re.match(r"(?i)^\s*(REPT|IRP|IRPC)\s+(.*)$", body)
        if rep:
            k, a = rep.group(1).upper(), split_comment(rep.group(2))[0].strip()
            out.append("  rept %s RPTN \\{" % CONSTS.get(a.upper(), a) if k == "REPT"
                       else "  %s %s \\{" % ("irp" if k == "IRP" else "irps", a.replace("<", "").replace(">", "")))
            blocks.append("irp"); depth += 1; continue
        if re.match(r"(?i)^\s*ENDM\b", body):
            depth -= 1
            out.append("}" if (blocks.pop() if blocks else "macro") == "macro" else "  \\}")
            continue
        if not body.strip(): continue
        body = re.sub(r"\"&([A-Za-z_$?@][\w$?@]*)&?\"", lambda m: "`" + m.group(1), body)
        mb, ml = strings_out(body)
        mb = mb.replace("&", "#")
        # The prefix of a name built by concatenation ("$_&NAM" in GIOTBL's DEV
        # macro, "$&RESWRD" in the reserved-word macros) must never carry a
        # module tag: the macro supplies the prefix while consumers in other
        # modules reference the finished name, so a tag here would build a
        # local symbol that nothing else can see.
        mb = re.sub(r"(?<![\w$?@#])([$?][\w$?@]*)(?=#)", lambda m: "@" + ESC(m.group(1)), mb)
        mb = re.sub(r"(?i)^\s*%OUT\s+(.*)$", lambda m: '  display "%s"' % m.group(1).strip().strip("*"), mb)
        mb = re.sub(r"(?i)^\s*\.(LIST|XLIST|SALL|XALL|LALL)\s*$", "", mb)
        mb = re.sub(r"%(?!OUT)[A-Za-z_$?@][\w$?@]*", "RPTN", mb)
        mb = re.sub(r"(?i)^\s*(PUBLIC|ORG|EXTRN)\b.*$", "", mb)
        mb = re.sub(r"(?i)^(\s*)(\S+)\s+LABEL\s+(\w+)",
                    lambda m: "%slabel %s %s" % (m.group(1), m.group(2), m.group(3).lower()), mb)
        mb = re.sub(r"(?i)^\s*ENDIF\s*$", "  end if", mb)
        mb = re.sub(r"(?i)^\s*ELSE\s*$", "  else", mb)
        mb = re.sub(r"(?i)^\s*IFDEF\s+(\S+)\s*$", lambda m: "  if defined %s" % m.group(1), mb)
        mb = re.sub(r"(?i)^\s*IFNDEF\s+(\S+)\s*$", lambda m: "  if ~ defined %s" % m.group(1), mb)
        mb = re.sub(r"(?i)^\s*IFE\s+(.+)$", lambda m: "  if (%s) = 0" % m.group(1), mb)
        mb = re.sub(r"(?i)^\s*IF\s+(.+)$", lambda m: "  if %s" % m.group(1), mb)
        mb = re.sub(r"(?i)\bOFFSET\s+", "", mb)
        mb = re.sub(r"(?i)\bLOW\s+([#\w$?@]+)",  lambda m: "((%s) and 0FFh)" % m.group(1), mb)
        mb = re.sub(r"(?i)\bHIGH\s+([#\w$?@]+)", lambda m: "(((%s) shr 8) and 0FFh)" % m.group(1), mb)
        mb = re.sub(r"(?i)\bDUP\s*\(", "dup (", mb)
        mb = re.sub(r"(?i)\b(DB|DW|DD)([\x01\"'])", lambda m: m.group(1) + " " + m.group(2), mb)
        if not re.match(r"(?i)^\s*INS86\b", mb): mb = re.sub(NUMRE, lambda m: num(m.group(0)), mb)
        for _i, _p in enumerate(CURPARAMS):
            if re.search(r'(?i)\blabel\s+' + re.escape(_p) + r'\b', mb):
                DEFMACRO.setdefault(CURMACRO.upper(), set()).add(_i)
            if re.search(r'(?i)#\s*' + re.escape(_p) + r'\b|\b' + re.escape(_p) + r'\s*#', mb):
                FRAGSEEN.setdefault(CURMACRO.upper(), set()).add(_i)
        _mm = re.match(r'^(\s*(?:[A-Za-z_$?@][\w$?@]*:)?\s*)([A-Za-z_$?@][\w$?@]*)(.*)$', mb)
        if _mm and _mm.group(2).upper() not in MACROS and _mm.group(2) == _mm.group(2).upper() \
                and not re.match(r'\s*=[^=]', _mm.group(3)):
            mb = rename(_mm.group(1), skip=set(CURPARAMS)) + _mm.group(2) + \
                 rename(_mm.group(3), skip=set(CURPARAMS))
        else:
            mb = rename(mb, skip=set(CURPARAMS))
        mb = strings_in(mb, ml)
        if mb.strip(): out.append("  " + mb.strip())
        continue
    if not body.strip():
        if cmt.strip(): out.append(";" + cmt.rstrip())
        elif out and out[-1].strip(): out.append("")       # collapse blank runs
        continue
    m = re.match(r"(?i)^\s*\.RADIX\s+(\d+)", body)
    if m: radix = int(m.group(1)); continue
    if re.match(r"(?i)^\s*(TITLE|SUBTTL|PUBLIC)\b", body):
        out.append("; " + body.strip()); continue          # documents the module
    if re.match(r"(?i)^\s*(PAGE|\.SALL|\.XALL|\.LIST|\.XLIST|%OUT)\b", body): continue
    sg = re.match(r"(?i)^\s*([A-Za-z_$?@][\w$?@]*)\s+(SEGMENT|ENDS)\b", body)
    if sg:
        if sg.group(2).upper() == "SEGMENT": segstack.append(sg.group(1).upper())
        elif len(segstack) > 1: segstack.pop()
        mk = ";;;SEG " + segstack[-1]
        if mk not in out[-1:]: out.append(mk)
        continue
    if re.match(r"(?i)^\s*\S*\s*(SEGMENT|ENDS)\b", body) or re.match(r"(?i)^\s*(ASSUME|GROUP)\b", body): continue
    if re.match(r"(?i)^\s*\S+\s+PROC\b", body) or re.match(r"(?i)^\s*\S*\s*ENDP\b", body):
        out.append("; " + body.strip()); continue
    if re.match(r"(?i)^\s*END\b", body) and not re.match(r"(?i)^\s*ENDIF", body): continue
    rep0 = re.match(r"(?i)^\s*(REPT|IRP|IRPC)\s+(.*)$", body)
    if rep0:
        k, a = rep0.group(1).upper(), split_comment(rep0.group(2))[0].strip()
        out.append("repeat %s" % CONSTS.get(a.upper(), a) if k == "REPT"
                   else "%s %s {" % ("irp" if k == "IRP" else "irps", a.replace("<", "").replace(">", "")))
        toplevel.append("repeat" if k == "REPT" else "irp"); continue
    if toplevel and re.match(r"(?i)^\s*ENDM\s*$", body):
        out.append("end repeat" if toplevel.pop() == "repeat" else "}"); continue
    m = re.match(r"(?i)^\s*EXTRN\s+(.*)$", body)
    if m:
        for item in m.group(1).split(","):
            n = item.split(":")[0].strip()
            if n: externs.append(n)
        out.append("; " + body.strip()); continue          # records the imports
    if re.match(r"(?i)^\s*INCLUDE\s+CPM86U", body): continue
    b, lits = strings_out(body)
    b = re.sub(r"(?i)^(\s*[A-Za-z_$?@][\w$?@]*)\s+EQU\s+(.+)$", lambda m: "%s = %s" % (m.group(1), m.group(2)), b)
    b = re.sub(r"(?i)^\s*INCLUDE\s+(\S+)", lambda m: "include '%s'" % m.group(1), b)
    b = re.sub(r"(?i)\b(BYTE|WORD|DWORD)\s+PTR\b", lambda m: m.group(1).lower(), b)
    b = re.sub(r"(?i)^(\s*)(\S+)\s+LABEL\s+(\w+)",
               lambda m: "%slabel %s %s" % (m.group(1), m.group(2), m.group(3).lower()), b)
    b = re.sub(r"(?i)^\s*ENDIF\s*$", "end if", b)
    b = re.sub(r"(?i)^\s*ELSE\s*$", "else", b)
    b = re.sub(r"(?i)^\s*IF1\s*$", "if 1", b)
    b = re.sub(r"(?i)^\s*IF2\s*$", "if 0", b)
    b = re.sub(r"(?i)^\s*IFDEF\s+(\S+)\s*$", lambda m: "if defined %s" % m.group(1), b)
    b = re.sub(r"(?i)^\s*IFNDEF\s+(\S+)\s*$", lambda m: "if ~ defined %s" % m.group(1), b)
    b = re.sub(r"(?i)^\s*IFE\s+(.+)$", lambda m: "if (%s) = 0" % m.group(1), b)
    b = re.sub(r"(?i)^\s*IF\s+(.+)$", lambda m: "if %s" % m.group(1), b)
    b = re.sub(r"(?i)^(\s*(?:[A-Za-z_$?@][\w$?@]*:)?\s*)(J[A-Z]{1,3}|JMP|CALL|LOOP[A-Z]*)(\s+)SHORT\s+",
               lambda m: m.group(1) + m.group(2) + m.group(3), b)
    b = re.sub(r"(?i)\bDUP\s*\(", "dup (", b)
    b = re.sub(r"(?i)\b(DB|DW|DD)([\x01\"'])", lambda m: m.group(1) + " " + m.group(2), b)
    if not re.match(r"(?i)^\s*INS86\b", b): b = re.sub(NUMRE, lambda m: num(m.group(0)), b)
    b = re.sub(r"(?i)^(\s*(?:[A-Za-z_$?@][\w$?@]*:)?\s*)XLAT\s+.*$", lambda m: m.group(1) + "xlatb", b)
    b = re.sub(r"(?i)^(\s*(?:[A-Za-z_$?@][\w$?@]*:)?\s*)(LODS|STOS|SCAS|MOVS|CMPS)\s+(.*)$",
               lambda m: m.group(1) + m.group(2).lower() + ("b" if re.search(r"(?i)\bbyte\b", m.group(3)) else "w"), b)

    m = re.match(r"^(\s*(?:[A-Za-z_$?@][\w$?@]*:)?\s*)([A-Za-z_$?@][\w$?@]*)(\s+)(.*)$", b)
    if m and m.group(2).upper() in MACROS:                       # macro call
        _frag0 = fragof(m.group(2).upper())
        for _i, _a in enumerate([x for x in re.split(r'[,\s]+', m.group(4)) if x.strip()]):
            if _i in DEFMACRO.get(m.group(2).upper(), set()): continue
            if _i in _frag0 and _i not in valfragof(m.group(2).upper()): continue
            if re.match(r'^[A-Za-z_$?@][\w$?@]*$', _a) and _a.upper() in SYM: stub(_a)
        _nm = m.group(2).upper()
        _frag = fragof(_nm)
        _usecomma = _nm in COMMA and _nm not in LOCALMACROS
        _parts = [x for x in re.split(r'(,)', m.group(4))]
        _res, _idx = [], 0
        for _tok in _parts:
            if _tok == ',': _res.append(_tok); _idx += 1; continue
            _res.append(re.sub(r'[A-Za-z_$?@][\w$?@]*', lambda mm: ESC(mm.group(0)), _tok)
                        if _idx in _frag else rename(_tok))
        _pfx = ',' if _usecomma else ''
        _tail = ''
        if _nm in TEXTARG and _nm not in LOCALMACROS:
            _w = [x for x in re.split(r'[,\s]+', m.group(4)) if x.strip()]
            _i = TEXTARG[_nm]
            if _i < len(_w): _tail = ",'%s'" % _w[_i]
        b = rename(m.group(1)) + FNAME(_nm if _nm in MACROS and m.group(2).isupper() else m.group(2)) + m.group(3) + _pfx + ''.join(_res) + _tail
    elif m and not re.match(r"(?i)^(if|else|end|include|label|macro|equ|dup|repeat|rept|irp|irps)$", m.group(2)) \
            and not m.group(4).lstrip().startswith('=') \
            and not re.match(r"(?i)^(DB|DW|DD|DQ|DT)\b", m.group(4)):
        head, mnem, gap, rest = m.groups()                       # instruction
        allow = not JUMPS.match(mnem) and not DATADEF.match(mnem)
        parts, dep, cur = [], 0, ""
        for ch in rest:
            if ch in "([": dep += 1
            elif ch in ")]": dep -= 1
            if ch == "," and dep == 0: parts.append(cur); cur = ""
            else: cur += ch
        parts.append(cur)
        if JUMPS.match(mnem) and len(parts) == 1:
            _t = parts[0].strip()
            if re.match(r"^[A-Za-z_$?@][\w$?@]*$", _t) and _t.upper() not in REGS: stub(_t)
        if re.match(r"(?i)^lea$", mnem) and len(parts) == 2: parts[1] = operand(parts[1], True)
        else: parts = [operand(p, allow) for p in parts]
        b = rename(head) + (FNAME(mnem) if mnem.upper() in MACROS else mnem) + gap + rename(",".join(parts))
    else:
        m0 = re.match(r"^(\s*(?:[A-Za-z_$?@][\w$?@]*:)?\s*)([A-Za-z_$?@][\w$?@]*)(\s*)$", b)
        if m0 and m0.group(2).upper() not in MACROS and m0.group(2) == m0.group(2).upper():
            b = rename(m0.group(1)) + m0.group(2) + m0.group(3)
        else:
            b = rename(b)
    out.append(strings_in(b, lits) + ("  ;" + cmt if cmt else ""))

hdr = [] if HEADER else (["format binary as 'bin'", "use16", "org 100h", "CPM86 = 0", ""]
       + ["%s = 0" % FNAME(c) for c in sorted(COUNTERS) if c.upper() not in LABELDEF]
       + ["%s = 0" % FNAME(n) for n in sorted(set(externs) | NEEDSTUB)] + [""])
io.open(dst, "w", encoding="latin-1").write("\n".join(hdr + out) + "\n")
