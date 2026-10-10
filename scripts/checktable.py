"""Verify the emitted reserved-word table against the sources.

The table is self-describing, which makes it the one part of the translation
that can be checked end to end: each entry is the keyword with its first
character dropped (the table is indexed by initial letter) and the high bit set
on the last, followed by one token byte.  The expected token for every word is
derived here by simulating MASM's QQ counter over the R/R2/T sequence, entirely
independently of the translator, so agreement is real evidence.
"""
import io, re, sys
from common import BIN, pristine_dir

L = [l.replace("\r", "").split(";")[0] for l in io.open(pristine_dir() + "/IBMRES.ASM", encoding="latin-1")]
tok, qq = {}, None
for l in L:
    m = re.match(r"^\s*QQ\s*=\s*(\d+)[Dd]?\s*$", l)
    if m: qq = int(m.group(1)); continue
    m = re.match(r"^\s*QQ\s*=\s*QQ\s*\+\s*(\d+)[Dd]?\s*$", l)
    if m: qq += int(m.group(1)); continue
    m = re.match(r"^\s*(R2|R|T)\s+([^\s,]+)", l)
    if m and qq is not None: qq += 1; tok.setdefault(m.group(2).upper(), qq)
want = {}
for l in L:
    m = re.match(r"^\s*(QF?)\s+(\S+)", l)
    if m:
        w = m.group(2).upper(); v = tok.get(w)
        # QF (functions) emit token-128, Q (statements) emit the token itself
        if v is not None: want.setdefault(w[1:], set()).add(v - 128 if m.group(1) == "QF" else v)

d = io.open(BIN + "/GWBASIC.COM", "rb").read()
i = d.find(b"UT\xcf")                      # AUTO, the first entry
if i < 0: sys.exit("reserved-word table not found in the image")
pairs = []
while i < len(d):
    if d[i] == 0: i += 1; continue          # DB 0 group terminator
    w = ""
    while i < len(d) and 32 <= d[i] < 127: w += chr(d[i]); i += 1
    if i >= len(d) or d[i] < 128: break
    pairs.append((w + chr(d[i] & 127), d[i + 1])); i += 2

good = wrong = other = 0
for tail, t in pairs:
    c = want.get(tail.upper())
    if c and t in c: good += 1
    elif c: wrong += 1; print("  WRONG %r token %d, expected %s" % (tail, t, sorted(c)))
    else: other += 1
print("reserved-word table at 0x%X: %d entries, %d verified against the QQ "
      "simulation, %d wrong, %d hand-written DB entries" % (d.find(b"UT\xcf"), len(pairs), good, wrong, other))
sys.exit(1 if wrong else 0)
