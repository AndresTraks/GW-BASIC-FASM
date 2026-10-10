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
cs, ds = set(), set()
for f in sorted(x for x in os.listdir(G) if x.endswith(".ASM")):
    seg, pend = "CSEG", None
    for l in io.open(os.path.join(G, f), encoding="latin-1"):
        b = l.replace("\r", "").split(";")[0]
        m = re.match(r"^\s*([A-Za-z_$?@][\w$?@]*)\s+(SEGMENT|ENDS)\b", b, re.I)
        if m:
            seg = m.group(1).upper() if m.group(2).upper() == "SEGMENT" else "CSEG"
            continue
        m = re.match(r"^\s*([A-Za-z_$?@][\w$?@]*)\s*:\s*(.*)$", b)
        if m:
            rest = m.group(2).strip()
            if re.match(r"(?i)^(DB|DW|DD|DQ|DT)\b", rest):
                (cs if seg == "CSEG" else ds).add(m.group(1).upper())
            elif not rest:
                pend = (m.group(1).upper(), seg)
            else:
                pend = None
            continue
        if pend and b.strip():
            if re.match(r"(?i)^\s*(DB|DW|DD|DQ|DT)\b", b):
                (cs if pend[1] == "CSEG" else ds).add(pend[0])
            pend = None
        m = re.match(r"^\s*([A-Za-z_$?@][\w$?@]*)\s+(DB|DW|DD|DQ|DT|LABEL)\b", b, re.I)
        if m: (cs if seg == "CSEG" else ds).add(m.group(1).upper())
# A name that also exists in DSEG is ambiguous; leave those alone.
out = sorted(cs - ds)
json.dump(out, io.open(sys.argv[2], "w"))
print("CSEG data labels: %d (%d dropped as also present in DSEG)" % (len(out), len(cs & ds)))
