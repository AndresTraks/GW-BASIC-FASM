"""Every macro name defined anywhere in the GW-BASIC sources or headers."""
import io, json, os, re, sys
G = sys.argv[1]
names = set()
for f in sorted(os.listdir(G)):
    if not (f.endswith(".ASM") or f in ("OEM.H", "BINTRP.H", "IBMRES.H", "GIO86U", "MSDOSU")):
        continue
    t = io.open(G + "/" + f, "rb").read().replace(b"\x00", b"").replace(b"\x1a", b"")
    for m in re.finditer(r"(?im)^\s*([A-Za-z_$?@][\w$?@&%]*)\s+MACRO\b", t.decode("latin-1")):
        names.add(m.group(1).upper())
json.dump(sorted(names), io.open(sys.argv[2], "w"))
print("macros: %d" % len(names))
