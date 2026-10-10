"""Which source files form one translation unit, and in what order they link.

MATH2 has no EXTRN, no segment header and no .RADIX of its own, starts
mid-routine, references $DP06 which MATH1 defines, and MATH1 declares
PUBLIC DMULT for a label MATH2 defines.  The original build was
"MASM MATH1+MATH2;" -- they are one assembly, not two.

GWDATA links first: it opens the code segment at offset 0 with BEGCSG and does
the "ORG 400O" that leaves room for the OS control block, with START right
after.  BIBOOT links last, because it is the entry point and its own comment
says it "is included in the linker file list AFTER all others".
"""
import os

JOINED = {"MATH1": ["MATH1.ASM", "MATH2.ASM"]}
FIRST, LAST = "GWDATA", "BIBOOT"
SPLIT = "@@@SPLIT@@@"          # marker used to cut a joined translation apart

def units(d):
    """[(unit name, [files])] for a directory of .ASM files, in link order."""
    mods = sorted(f[:-4] for f in os.listdir(d) if f.endswith(".ASM"))
    second = {f[:-4] for fs in JOINED.values() for f in fs[1:]}
    names = [m for m in mods if m not in second]
    order = ([FIRST] + [m for m in names if m not in (FIRST, LAST)] +
             ([LAST] if LAST in names else []))
    return [(m, JOINED.get(m, [m + ".ASM"])) for m in order]

def unit_of(mod):
    for u, fs in JOINED.items():
        if mod + ".ASM" in fs: return u
    return mod
