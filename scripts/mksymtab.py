import io, os, re, sys, json, collections
from common import pristine_dir
G = pristine_dir()
files = sorted(f for f in os.listdir(G) if f.endswith(".ASM"))
word, near, const, local = set(), set(), set(), {}
for fn in files:
    t = io.open(G+"/"+fn,"rb").read().replace(b"\x00",b"").decode("latin-1").replace("\r","")
    t = re.sub(r"(?mi)^\s*COMMENT\s*(\S).*?\1", "", t, flags=re.S)
    seg = None
    for line in t.split("\n"):
        b = line.split(";")[0].rstrip()
        if not b.strip(): continue
        m = re.match(r"(?i)^\s*(\S+)\s+SEGMENT\b", b)
        if m: seg = m.group(1).upper(); continue
        if re.match(r"(?i)^\s*\S*\s*ENDS\b", b): seg = None; continue
        m = re.match(r"(?i)^\s*EXTRN\s+(.*)$", b)
        if m:
            for item in m.group(1).split(","):
                if ":" not in item: continue
                n, ty = item.split(":",1); n, ty = n.strip().upper(), ty.strip().upper()
                if n: (word if ty=="WORD" else near).add(n)
            continue
        if re.match(r"(?i)^\s*([A-Za-z_$?@][\w$?@]*)\s*=[^=]", b):
            const.add(re.match(r"(?i)^\s*([A-Za-z_$?@][\w$?@]*)", b).group(1).upper()); continue
        m = re.match(r"(?i)^\s*([A-Za-z_$?@][\w$?@]*)\s+(DB|DW|DD|DQ|DT)\b", b)
        if m: local[m.group(1).upper()] = 'data'; continue
        m = re.match(r"(?i)^\s*([A-Za-z_$?@][\w$?@]*)\s+LABEL\s+(\w+)", b)
        if m: local[m.group(1).upper()] = 'code' if m.group(2).upper() in ("NEAR","FAR") else 'data'; continue
        m = re.match(r"(?i)^\s*R\s+([A-Za-z_$?@][\w$?@]*)\s*,", b)   # GWRAM's RAM-layout macro
        if m: local[m.group(1).upper()] = 'data'; continue
        m = re.match(r"(?i)^\s*([A-Za-z_$?@][\w$?@]*)\s*:", b)
        if m: local.setdefault(m.group(1).upper(), 'data' if seg=="DSEG" else 'code'); continue
sym = {}
for n,k in local.items(): sym[n] = k
for n in near:  sym[n] = 'code'
for n in const: sym.setdefault(n, 'const')
for n in word:  sym[n] = 'data'          # EXTRN :WORD is authoritative
c = collections.Counter(sym.values())
print("symbols:", len(sym), dict(c))
json.dump(sym, io.open(sys.argv[2],"w"))
