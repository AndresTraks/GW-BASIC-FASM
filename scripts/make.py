"""Convert the MASM sources to fasm in place, then assemble and verify.

  python3 make.py              convert, link, verify
  python3 make.py --check      also run the per-module regression build

The originals are read from git (common.BASELINE), so converting is re-runnable
and does not depend on the working tree's state.

Environment:
  GWBASIC_SRC       sources (default: the parent directory)
  GWBASIC_OUT       intermediates (default: ./build)
  GWBASIC_BIN       image output (default: ../bin)
  GWBASIC_BASELINE  git revision holding the original MASM (default: edf82c2)
  FASM              how to run fasm (default: native fasm, else wine + FASM.EXE)
"""
import os, subprocess, sys
from common import SRC, OUT, BIN, ROOT, need_src

need_src()
P = sys.executable

def step(title, args, isolated=True):
    print("==> " + title, flush=True)
    # -I for the analysis steps: they only read the sources as data.  The build
    # steps import local modules, which isolated mode would hide.
    r = subprocess.run(([P, "-I"] if isolated else [P]) + args, cwd=ROOT)
    if r.returncode: sys.exit(r.returncode)

orig = os.path.join(OUT, "orig")
step("symbol table",   [ROOT + "/mksymtab.py", orig, OUT + "/symtab.json"], isolated=False)
step("macro list",     [ROOT + "/mkmacros.py", orig, OUT + "/macros.json"])
step("module globals", [ROOT + "/mkglobals.py", orig, OUT + "/globals.json"])
step("CSEG data labels", [ROOT + "/mkcsdata.py", orig, OUT + "/csdata.json"])
if "--check" in sys.argv:
    step("per-module regression build", [ROOT + "/build.py"], isolated=False)
step("convert in place", [ROOT + "/convert.py"], isolated=False)
step("link",             [ROOT + "/link.py"], isolated=False)
step("verify reserved-word table", [ROOT + "/checktable.py"], isolated=False)
step("verify INS86 encodings",      [ROOT + "/checkins86.py"], isolated=False)
step("verify DSEG placement",       [ROOT + "/checkdseg.py"], isolated=False)
print("\n%s written." % os.path.join(BIN, "GWBASIC.COM"))
print("Runs under MS-DOS 1.25; see README.md for what is and is not exercised.")
