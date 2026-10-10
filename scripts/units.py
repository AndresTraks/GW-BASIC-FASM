"""Which source files form one translation unit, and in what order they link.

MATH2 has no EXTRN, no segment header and no .RADIX of its own, starts
mid-routine, references $DP06 which MATH1 defines, and MATH1 declares
PUBLIC DMULT for a label MATH2 defines.  The original build was
"MASM MATH1+MATH2;" -- they are one assembly, not two.

GWDATA links first: it opens the code segment at offset 0 with BEGCSG and does
the "ORG 400O" that leaves room for the OS control block, with START right
after.

The tail is forced, and getting it wrong destroys the program at run time.
ITSA86 carries the label CSEND, with the comment "All code loaded after this
label is resident only until routine MAPINI initializes the new memory map":
MAPCLC computes NEWDS = CS + paragraphs(CSEND), and MAPINI then moves the data
segment there, deliberately overlaying everything linked after CSEND to reclaim
the initialisation code.  So only initialisation code may follow it.  Nothing
calls into ITSA86's own tail (MAPCLC and SEGOFF) or into GWINIT (whose only
entry points are INIT and CMDERR) except during startup, and BIBOOT is the
EXE entry point, which a .COM image never uses -- its own comment says it "is
included in the linker file list AFTER all others", and GWINIT ends with
"$LAST=$ / LASTWR=$", so this is the original order too.  BIBOOT stays last of
the three because LSTVAR, which BASIC reads as the end of its data segment, is
the last label in its DSEG.
"""
import os

JOINED = {"MATH1": ["MATH1.ASM", "MATH2.ASM"]}
FIRST = "GWDATA"
TAIL = ("ITSA86", "GWINIT", "BIBOOT")   # discarded once MAPINI has run
SPLIT = "@@@SPLIT@@@"          # marker used to cut a joined translation apart

def units(d):
    """[(unit name, [files])] for a directory of .ASM files, in link order."""
    mods = sorted(f[:-4] for f in os.listdir(d) if f.endswith(".ASM"))
    second = {f[:-4] for fs in JOINED.values() for f in fs[1:]}
    names = [m for m in mods if m not in second]
    order = ([FIRST] + [m for m in names if m != FIRST and m not in TAIL] +
             [m for m in TAIL if m in names])
    return [(m, JOINED.get(m, [m + ".ASM"])) for m in order]

def unit_of(mod):
    for u, fs in JOINED.items():
        if mod + ".ASM" in fs: return u
    return mod
