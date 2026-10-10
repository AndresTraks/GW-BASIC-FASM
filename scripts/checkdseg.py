"""Check that DSEG's initialisers landed at the right place in the image.

CSEG and DSEG are emitted in two passes, with DSEG at org 0 so its labels are
segment relative while its bytes follow the code in the file.  That makes the
mapping from a DSEG label to a file offset indirect:

    file offset = (DSEG base - 100h) + label

where the 100h is the program segment prefix, which occupies the start of CSEG
in the image and the start of DSEG at run time.  Getting that wrong shifts the
whole data segment, which no amount of assembling would catch, so a few
initialisers with distinctive values are read back out of the image here.
"""
import io, os, re, sys
from common import SRC, BIN, fasm, run, pristine_dir

# label, expected initial byte, where the source sets it
PROBES = [("@FKCNUM", 6,    "GWRAM: RINIT FKCNUM,1 / DB 6D"),
          ("@F_CRET", 0xFF, "GWRAM: RINIT F_CRET,1 / DB 377O"),
          ("@OCTAVE", 4,    "GWRAM: RINIT OCTAVE,1 / DB 4D"),
          ("@BEATS",  120,  "GWRAM: RINIT BEATS,1 / DB 120D, the default PLAY tempo")]
SYMS = ["@GWBASIC_DSEG_BASE"] + [p[0] for p in PROBES]

FASM = fasm()
RB = os.path.relpath(BIN, SRC)
io.open(os.path.join(BIN, "GWDSEG.ASM"), "w", encoding="latin-1").write(
    "include 'GWBASIC.ASM'\n" + "\n".join("dw " + s for s in SYMS) + "\n")
a = run(FASM + [RB + "/GWDSEG.ASM", RB + "/GWDSEG.bin"], cwd=SRC, env={"INCLUDE": SRC})
if "passes," not in (a.stdout or "") + (a.stderr or ""):
    sys.exit("probe build failed:\n" + ((a.stdout or "") + (a.stderr or ""))[-400:])
b = io.open(os.path.join(BIN, "GWDSEG.bin"), "rb").read()
v = {s: b[len(b) - 2 * (len(SYMS) - k)] | (b[len(b) - 2 * (len(SYMS) - k) + 1] << 8)
     for k, s in enumerate(SYMS)}
img = io.open(os.path.join(BIN, "GWBASIC.COM"), "rb").read()
base = v["@GWBASIC_DSEG_BASE"] - 0x100
print("DSEG base 0x%04X -> file offset 0x%04X" % (v["@GWBASIC_DSEG_BASE"], base))
bad = 0
for name, want, where in PROBES:
    off = base + v[name]
    got = img[off] if off < len(img) else None
    ok = got == want
    bad += not ok
    print("  %-9s DSEG 0x%04X -> file 0x%04X = %s  want 0x%02X  %-7s %s"
          % (name, v[name], off, "0x%02X" % got if got is not None else "past EOF",
             want, "OK" if ok else "<-- BAD", where))
sys.exit(1 if bad else 0)
