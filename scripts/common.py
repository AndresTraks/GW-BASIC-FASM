"""Shared paths and fasm invocation."""
import io, os, shutil, subprocess, sys

ROOT = os.path.dirname(os.path.abspath(__file__))
SRC = os.path.abspath(os.environ.get("GWBASIC_SRC", os.path.join(ROOT, os.pardir)))
OUT = os.path.abspath(os.environ.get("GWBASIC_OUT", os.path.join(ROOT, "build")))
BIN = os.path.abspath(os.environ.get("GWBASIC_BIN", os.path.join(ROOT, os.pardir, "bin")))
TRANSLATOR = os.path.join(ROOT, "masm2fasm.py")
# The converted .ASM files in the repository root are fasm, so the analysis
# steps cannot parse them any more.  They read the original MASM instead, out of
# the last commit that predates the conversion.
BASELINE = os.environ.get("GWBASIC_BASELINE", "edf82c2")
HEADERS = ("OEM.H", "GIO86U", "MSDOSU", "BINTRP.H", "IBMRES.H")

def fasm():
    """The same fasm assemble.sh picks: the copy vendored for this machine,
    then anything on PATH, then the Windows build under wine."""
    if os.environ.get("FASM"): return os.environ["FASM"].split()
    import platform
    m, lx = platform.machine(), os.path.join(SRC, "fasm-1.73.35")
    for cond, exe in ((m == "x86_64", "fasm.x64"), (m in ("i686", "i386"), "fasm")):
        p = os.path.join(lx, exe)
        if cond and os.access(p, os.X_OK): return [p]
    if shutil.which("fasm"): return ["fasm"]
    exe = os.path.join(lx, "FASM.EXE")
    if os.path.exists(exe) and shutil.which("wine"): return ["wine", exe]
    sys.exit("fasm not found: install it, or set FASM='wine /path/to/FASM.EXE'")

def run(args, cwd=None, env=None):
    e = dict(os.environ, WINEDEBUG=os.environ.get("WINEDEBUG", "-all"))
    if env: e.update(env)
    return subprocess.run(args, cwd=cwd, capture_output=True, text=True, env=e)

def translate(src, dst, extra=None, env=None):
    env = dict(env or {}, M2F_CSDATA=os.path.join(OUT, "csdata.json"))
    a = [sys.executable, "-I", TRANSLATOR, src, dst, os.path.join(OUT, "symtab.json")]
    if extra: a.append(extra)
    return run(a, env=env)

def need_src():
    if not os.path.isdir(SRC):
        sys.exit("GW-BASIC sources not found at %s\nSet GWBASIC_SRC=/path/to/GW-BASIC" % SRC)
    os.makedirs(OUT, exist_ok=True)


def pristine_dir():
    """Extract the original MASM sources from BASELINE into OUT/orig."""
    d = os.path.join(OUT, "orig")
    os.makedirs(d, exist_ok=True)
    names = subprocess.run(["git", "ls-tree", "--name-only", BASELINE],
                           cwd=SRC, capture_output=True, text=True)
    if names.returncode:
        sys.exit("cannot read baseline %s from git in %s" % (BASELINE, SRC))
    want = [n for n in names.stdout.split() if n.endswith(".ASM") or n in HEADERS]
    if not want:
        sys.exit("baseline %s contains no .ASM files" % BASELINE)
    for n in want:
        b = subprocess.run(["git", "show", "%s:%s" % (BASELINE, n)],
                           cwd=SRC, capture_output=True)
        if b.returncode: sys.exit("cannot read %s:%s" % (BASELINE, n))
        # DOS EOF markers stop fasm reading a file; NULs defeat text tools
        io.open(os.path.join(d, n), "wb").write(
            b.stdout.replace(b"\x1a", b"").replace(b"\x00", b""))
    return d
