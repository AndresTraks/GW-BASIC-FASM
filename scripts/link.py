"""Assemble GWBASIC.ASM and report the image layout.

This does the same thing assemble.sh does -- it is a plain fasm run over the
generated master file -- and then measures the result and checks it against the
layout the sources document.

Model, as documented in BIBOOT.ASM and GWINIT.ASM: a single flat image, CSEG
then DSEG, with DS computed at run time as CS + offset(BEGDSG)/16.

CSEG and DSEG are emitted in two passes over the same modules, because fasm
writes its output in emission order: all of the code first, then the data at
org 0 so that its labels are segment relative.  DSEG's initialisers are in the
image; its trailing uninitialised bytes are not, which costs nothing because a
.COM is given the whole segment.
"""
import io, os, sys
from common import SRC, BIN, fasm, run, need_src

FASM = fasm()
need_src()
os.makedirs(BIN, exist_ok=True)
RB = os.path.relpath(BIN, SRC)
MASTER = "GWBASIC.ASM"
if not os.path.exists(os.path.join(SRC, MASTER)):
    sys.exit("%s not found; run convert.py first" % MASTER)

a = run(FASM + [MASTER, RB + "/GWBASIC.COM"], cwd=SRC, env={"INCLUDE": SRC})
o = (a.stdout or "") + (a.stderr or "")
if "passes," not in o:
    sys.exit("FAILED:\n" + "\n".join(o.strip().splitlines()[-6:]))
print("assembled: %s" % o.strip().splitlines()[-1])

# Measure by assembling a probe that includes the master and appends the symbols
# as data, then reading them back out of the tail of the binary.
PROBE = ["@GWBASIC_CSEG_END", "@GWBASIC_DSEG_SIZE", "@BEGCSG", "@CPMENT",
         "@START", "@BEGDSG", "@CPMMEM", "@LSTVAR"]
io.open(os.path.join(BIN, "GWSIZE.ASM"), "w", encoding="latin-1").write(
    "include '%s'\n" % MASTER + "\n".join("dw " + s for s in PROBE) + "\n")
a = run(FASM + [RB + "/GWSIZE.ASM", RB + "/GWSIZE.bin"], cwd=SRC, env={"INCLUDE": SRC})
if "passes," not in (a.stdout or "") + (a.stderr or ""):
    sys.exit("probe build failed:\n" + ((a.stdout or "") + (a.stderr or ""))[-400:])
b = io.open(os.path.join(BIN, "GWSIZE.bin"), "rb").read()
v = {s: b[len(b) - 2 * (len(PROBE) - k)] | (b[len(b) - 2 * (len(PROBE) - k) + 1] << 8)
     for k, s in enumerate(PROBE)}
ce, ds = v["@GWBASIC_CSEG_END"], v["@GWBASIC_DSEG_SIZE"]
img = os.path.getsize(os.path.join(BIN, "GWBASIC.COM"))

print("\n  layout invariants, against what the sources document:")
bad = 0
for s, want, why in (("@BEGCSG", 0x000, "first label in CSEG (SYSTEM jumps here)"),
                     ("@CPMENT", 0x005, "CP/M-style entry, GWDATA ORG 5O"),
                     ("@START",  0x100, "GWDATA ORG 400O, past the PSP area"),
                     ("@BEGDSG", 0x000, "first label in DSEG"),
                     ("@CPMMEM", 0x002, "GWDATA DSEG ORG 2D"),
                     ("@LSTVAR", ds,    "last label in DSEG == DSEG size")):
    ok = v[s] == want
    bad += not ok
    print("    %-9s = 0x%04X  %-7s %s" % (s, v[s], "OK" if ok else "<-- BAD", why))
top = ((ce + 15) & ~15) + ds
print("\n  CSEG  code+tables   0x0100 .. 0x%04X   %6d bytes" % (ce, ce - 0x100))
print("  DSEG  variables     0x0000 .. 0x%04X   %6d bytes" % (ds, ds))
print("  image               %6d bytes on disk (DSEG's uninitialised tail is not stored)" % img)
print("  top of DSEG from CS:0 = 0x%04X   headroom in the 64K segment: %d bytes" % (top, 0x10000 - top))
sys.exit(1 if bad else 0)
