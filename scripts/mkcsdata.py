"""Data labels that live in the code segment.

MASM resolves a symbol's segment and, under "ASSUME CS:CSEG / DS:DSEG", emits a
CS: override automatically when code reads data that lives in CSEG.  fasm has
no ASSUME, so those overrides have to be put back, or the read goes to the data
segment and returns whatever happens to be at that offset -- which still
assembles.  SCNDRV's "MOV AX,WORD PTR FUNTAB[BX]", the control-function
dispatch, is one of these.
"""
import io, json, os, re, sys
G = sys.argv[1]
DEF = r"(?i)^\s*(DB|DW|DD|DQ|DT)\b"
cs, ds = set(), set()
cslab, segop = set(), set()             # for the dummy-label override idiom
for f in sorted(x for x in os.listdir(G) if x.endswith(".ASM")):
    seg, pend = "CSEG", []
    for l in io.open(os.path.join(G, f), encoding="latin-1"):
        b = l.replace("\r", "").split(";")[0]
        m = re.match(r"^\s*([A-Za-z_$?@][\w$?@]*)\s+(SEGMENT|ENDS)\b", b, re.I)
        if m:
            seg = m.group(1).upper() if m.group(2).upper() == "SEGMENT" else "CSEG"
            continue
        m = re.match(r"(?i)^\s*(?:[A-Za-z_$?@][\w$?@]*:)?\s*"
                     r"(?:XLAT|LODS|MOVS|CMPS)\s+(\S.*)$", b)
        if m:
            segop |= {n.upper() for n in re.findall(r"[A-Za-z_$?@][\w$?@]*", m.group(1))}
        m = re.match(r"^\s*([A-Za-z_$?@][\w$?@]*)\s*:\s*(.*)$", b)
        if m:
            if seg == "CSEG": cslab.add(m.group(1).upper())
            rest = m.group(2).strip()
            if re.match(DEF, rest):
                (cs if seg == "CSEG" else ds).add(m.group(1).upper())
                pend = []
            elif not rest:
                pend.append((m.group(1).upper(), seg))   # label alone on its line
            else:
                pend = []
            continue
        # A listing or radix directive between a label and its storage does not
        # end the definition: "$FOTB:" is followed by ".RADIX 10" and then the
        # table, and missing it left the decimal-exponent table read from DSEG.
        if pend and b.strip() and not re.match(r"^\s*(\.|PAGE\b|SUBTTL\b|TITLE\b)", b, re.I):
            if re.match(DEF, b):
                for n, sg in pend: (cs if sg == "CSEG" else ds).add(n)
            pend = []
        m = re.match(r"^\s*([A-Za-z_$?@][\w$?@]*)\s+(DB|DW|DD|DQ|DT|LABEL)\b", b, re.I)
        if m: (cs if seg == "CSEG" else ds).add(m.group(1).upper())
# XLAT and the string instructions take an operand only to name a segment --
# the address is always DS:BX or DS:SI, or CS: with the override MASM derives
# from the operand's segment.  All twelve sites name ?CSLAB, which GWSTS and
# MATH1 define in CSEG as "Code segment dummy label", and their comments say so
# outright: "FETCH FROM CS", "MUST FETCH FROM CODE SEGMENT".  Without the
# overrides the whole floating-point library reads its constants out of DSEG --
# $FOTNV's bracket control table, the powers of ten, the polynomial
# coefficients -- so every float prints as seven zero-padded digits and
# dividing by a power of ten divides by zero.
cs |= segop & cslab

# A name that also exists in DSEG is ambiguous; leave those alone.
out = sorted(cs - ds)
json.dump(out, io.open(sys.argv[2], "w"))
print("CSEG data labels: %d (%d dropped as also present in DSEG)" % (len(out), len(cs & ds)))
