"""Per-module global sets: a name is global FOR MODULE M only if M itself
declares it PUBLIC or EXTRN.  That is LINK's rule, and it is the only rule that
keeps the 29 names that are PUBLIC in one module and a private label in another
(SAVE, RESTORE, DMULT, GETQ, ...) from being merged."""
import io, json, os, re, sys
G = sys.argv[1]
UNITS = {"MATH1": ["MATH1.ASM", "MATH2.ASM"]}          # assembled as MASM MATH1+MATH2
mods = sorted(f[:-4] for f in os.listdir(G) if f.endswith(".ASM"))
units = {m: UNITS.get(m, [m + ".ASM"]) for m in mods if m != "MATH2"}
out = {}
for u, files in units.items():
    g = set()
    for f in files:
        for l in io.open(G + "/" + f, encoding="latin-1"):
            l = l.replace("\r", "").split(";")[0]
            m = re.match(r"^\s*(PUBLIC|EXTRN)\s+(.*)$", l, re.I)
            if m:
                for it in m.group(2).split(","):
                    n = it.split(":")[0].strip().upper()
                    if n: g.add(n)
                continue
            # Names the table macros declare PUBLIC or EXTRN inside their bodies,
            # which no scan of the module text can see.  They are global only for
            # the module that invokes the macro: MATH1's private "$COS:" label
            # must stay distinct from the "$COS" token constant built elsewhere.
            m = re.match(r"^\s*(T|Q|QF|R|R2)\s+([^\s,]+)\s*(?:,\s*([^\s,]+))?", l)
            if m:
                a = m.group(2).strip().upper()
                g.add("$" + a); g.add(a)
                if m.group(3): g.add(m.group(3).strip().upper())
            m = re.match(r"^\s*(?:R|R1|RINIT)\s+([A-Za-z_$?@][\w$?@]*)\s*,", l)
            if m: g.add(m.group(1).upper())          # GWRAM: "PUBLIC NAME" in the body
            m = re.match(r"^\s*DERMAK\s+([A-Za-z_$?@][\w$?@]*)", l)
            if m: g.add("DER" + m.group(1).upper())
    out[u] = sorted(g)
json.dump(out, io.open(sys.argv[2], "w"), indent=0)
print("units: %d   globals per unit: min %d, max %d, total distinct %d"
      % (len(out), min(len(v) for v in out.values()), max(len(v) for v in out.values()),
         len(set().union(*out.values()))))
