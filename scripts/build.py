"""Per-module regression build: translate each GW-BASIC module on its own and
assemble it.  Every module must assemble independently before the single-unit
link in link.py is worth attempting; this is the regression harness."""
import io, os, re, subprocess, sys
from common import OUT as W, fasm, run, translate, need_src, pristine_dir
FASM = fasm()

# Macros whose MASM text machinery (IRPC, IFB/IFNB, IFDIF, & name building)
# has no mechanical fasm equivalent: stripped and written by hand below.
HAND = {
 "OEM.H": (["INS86", "DC"], r"""
macro @INS86 A,B,C,D {
  db A#o
  match any, B \{ db B#o \}
  match any, D \{ db C#o
                  db D#o \}
  match , D \{ match any, C \\{ dw C \\} \}
}
macro @DC ARG { db ARG }
"""),
 "MSDOSU": (["CALLOS"], r"""
macro @CALLOS FUNC { match any, FUNC \{ mov ah, FUNC \}
  int 21h }
"""),
 "BINTRP.H": (["T", "Q", "QF", "R", "R2", "un_def", "DERMAK"], None),
 "IBMRES.H": (["T", "Q", "QF", "R", "R2", "un_def"], None),
}
# Reserved-word table macros.  Arguments pass RAW; the macro applies the naming
# function itself, because the same parameter is used both as a name fragment
# (@@S#RESWRD = the token value $RESWRD) and as a symbol (@#RESDSP = an address).
TABLE = r"""
macro @un_def dummy,RESWRD { display "+++ Undefined reserved word", 10 }

; Emits the word with its FIRST CHARACTER DROPPED and the high bit set on the
; last -- the GW-BASIC table is indexed by initial letter.  MASM does the same
; via "IF $F", which is false on the first IRPC iteration.  TXT is the original
; MASM token as a string literal: the escaped symbol name must never be the
; source of the emitted characters ($CHR$ -> @@SCHR@S would spell "HR@S").
macro @RESCHARS TXT {
  local len, c
  virtual at 0
    db TXT
    len = $
  end virtual
  repeat len - 1
    virtual at 0
      db TXT
      load c byte from %
    end virtual
    if % = len - 1
      db c or 128
    else
      db c
    end if
  end repeat
}
macro @T dummy,RESWRD { @QQ = @QQ + 1
  @@S#RESWRD = @QQ }
macro @Q dummy,RESWRD,TXT {
  if defined @@S#RESWRD
    @RESCHARS TXT
    db @@S#RESWRD
  else
    @un_def ,RESWRD
  end if }
macro @QF dummy,RESWRD,TXT {
  if defined @@S#RESWRD
    @RESCHARS TXT
    db @@S#RESWRD - 128
  else
    @un_def ,RESWRD
  end if }
macro @R dummy,RESWRD { dw @#RESWRD
  @QQ = @QQ + 1
  @@S#RESWRD = @QQ }
macro @R2 dummy,RESWRD,RESDSP { dw @#RESDSP
  @QQ = @QQ + 1
  @@S#RESWRD = @QQ }
"""
DERMAK = r"""
macro @DERMAK dummy,X { @DER#X: mov dl, @ERR#X
  db 271o }
"""

def strip_macros(path, names):
    t = io.open(path, encoding="latin-1").read().split("\n")
    out, drop, depth = [], False, 0
    low = {n.lower() for n in names}
    for l in t:
        m = re.match(r"^macro\s+@?([A-Za-z_$?@@][\w$?@@]*)", l)
        if m and m.group(1).lstrip("@").lower() in low:
            drop, depth = True, l.count("{") - l.count("}")
            if depth <= 0: drop = False
            continue
        if drop:
            depth += l.count("{") - l.count("}")
            if depth <= 0: drop = False
            continue
        out.append(l)
    io.open(path, "w", encoding="latin-1").write("\n".join(out))

need_src()
G = pristine_dir()        # the .ASM files in the root are fasm now
for f in os.listdir(G):
    if f.endswith(".ASM"): io.open(W + "/" + f, "wb").write(io.open(G + "/" + f, "rb").read())
for h in ("OEM.H", "GIO86U", "MSDOSU", "BINTRP.H", "IBMRES.H"):
    io.open(W + "/" + h + ".src", "wb").write(io.open(G + "/" + h, "rb").read())
    r = translate(G + "/" + h, W + "/" + h, "header", env={"M2F_HDRS": G})
    if r.returncode: print(h, "TRANSLATE FAIL", r.stderr.strip()[-200:]); sys.exit(1)
    if h in HAND:
        names, tail = HAND[h]
        strip_macros(W + "/" + h, names)
        extra = tail if tail else (TABLE + (DERMAK if h == "BINTRP.H" else ""))
        io.open(W + "/" + h, "a", encoding="latin-1").write(extra)

# A module with no INCLUDE and no .RADIX of its own is not a translation unit:
# it is a continuation of the preceding file, sharing its symbols and radix
# (MATH2 references $DP06, which MATH1 defines, with no EXTRN).  Join it on.
units = []
for f in sorted(x for x in os.listdir(W) if x.endswith(".ASM")):
    head = io.open(W + "/" + f, encoding="latin-1").read()
    cont = not re.search(r"(?im)^\s*(INCLUDE|\.RADIX)\b", head)
    if cont and units: units[-1][1].append(f)
    else: units.append((f[:-4], [f]))
for m, fs in units:
    if len(fs) > 1:
        io.open(W + "/" + m + ".joined", "w", encoding="latin-1").write(
            "".join(io.open(W + "/" + x, encoding="latin-1").read() for x in fs))

ok, bad, okbytes, total = [], [], 0, 0
for m, fs in units:
    f = (m + ".joined") if len(fs) > 1 else fs[0]
    total += sum(os.path.getsize(G + "/" + x) for x in fs)
    r = translate(W + "/" + f, W + "/" + m + ".fasm", env={"M2F_HDRS": G})
    if r.returncode: bad.append((m, "translate: " + r.stderr.strip().splitlines()[-1][:60])); continue
    a = run(FASM + [m + ".fasm", m + ".out"], cwd=W)
    txt = (a.stdout or "") + (a.stderr or "")
    if "passes," in txt:
        ok.append(m); okbytes += sum(os.path.getsize(G + "/" + x) for x in fs)
    else:
        e = [l for l in txt.splitlines() if "error:" in l]
        bad.append((m, e[-1].strip()[:70] if e else txt.strip().splitlines()[-1][:70]))
print("assembled: %d / %d units, %d / %d files   (%.1f%% by volume)"
      % (len(ok), len(units), sum(len(d) for n, d in units if n in ok),
         sum(len(d) for n, d in units), 100.0 * okbytes / total))
for m, e in bad: print("  %-9s %s" % (m, e))
