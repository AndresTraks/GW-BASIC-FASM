"""Check the @INS86 macro against the mnemonics the sources document.

INS86 is hand-encoded machine code: the 8080-to-8086 translator emitted raw
opcode bytes where it could not express something, and 112 of the 127 sites
carry a comment naming the instruction those bytes are meant to be.  That is an
oracle for the riskiest macro in the translation -- a wrong encoding here still
assembles.  For each site the bytes @INS86 emits are disassembled and compared
against a disassembly of what fasm produces from the commented mnemonic.

The comparison has to be on the disassembly, not the bytes: x86's direction bit
gives two valid encodings for a reg,reg operation, and the hand-written opcodes
in the source consistently pick the other one from the one fasm chooses.
"""
import io, os, re, shutil, sys
from common import OUT, fasm, run, pristine_dir
import headers

if not shutil.which("objdump"):
    print("objdump not found (binutils); skipping the INS86 check")
    sys.exit(0)
FASM = fasm()
REGS = set("AX BX CX DX SI DI BP SP AL AH BL BH CL CH DL DH DS ES SS CS".split())
MNEM = set("""mov cmp add sub and or xor test inc dec push pop call jmp ret retf
 cld std cli sti lods stos scas movs cmps xchg lea les lds neg not shl shr sal sar
 rol ror rcl rcr mul imul div idiv cbw cwd nop xlat loop int iret clc stc cmc
 jz jnz je jne ja jae jb jbe jg jge jl jle jc jnc js jns jo jno jp jnp jcxz
 jnae jnb jnbe jna jnge jnl jnle jng adc sbb""".split())

def fasmify(c):
    """Turn a MASM-style comment into a fasm instruction, or None."""
    c = c.strip().rstrip('?').strip()
    c = re.sub(r"\s*[-;].*$", "", c)                 # "CMPC-IS CHAR..." -> "CMPC"
    # NB: do not try to trim trailing prose at a double space -- several comments
    # put one between the mnemonic and its operands ("SHR  DX,CL"), so trimming
    # there silently truncates the operands and turns a real check into a false one.
    t = c.split()
    if not t: return None
    op = t[0].upper()
    op = {"MOVI": "MOV", "MOVBI": "MOV", "CMPI": "CMP", "CMPBI": "CMP",
          "ADDI": "ADD", "SUBI": "SUB", "ANDI": "AND", "ORI": "OR",
          "MOVB": "MOV", "CMPB": "CMP", "CMPC": "CMPSB", "MOVC": "MOVSB",
          "SCAB": "SCASB", "LODB": "LODSB", "STOB": "STOSB"}.get(op, op)
    if op.lower() not in MNEM and op.lower() not in ("cmpsb", "movsb", "scasb", "lodsb", "stosb"):
        return None
    rest = " ".join(t[1:])
    if not rest: return op.lower()
    ops = [o.strip() for o in rest.split(",")]
    out = []
    for o in ops:
        if o.upper() in REGS: out.append(o.lower()); continue
        if re.match(r"^\d+$", o): out.append(o); continue
        if re.match(r"^[A-Za-z_$?@][\w$?@]*(\+\d+)?$", o):
            out.append("[%s]" % o)                   # MASM writes memory bare
            continue
        return None
    return "%s %s" % (op.lower(), ",".join(out))

def disasm(b):
    """Normalised instruction text, via objdump in 16-bit mode."""
    p = os.path.join(OUT, "ins86.bin")
    io.open(p, "wb").write(b)
    a = run(["objdump", "-D", "-b", "binary", "-m", "i8086", "-M", "intel", p])
    out = []
    for l in (a.stdout or "").split("\n"):
        m = re.match(r"^\s*[0-9a-f]+:\s+((?:[0-9a-f]{2} )+)\s*(\S.*)?$", l)
        if m and m.group(2):
            s = re.sub(r"\s+", " ", m.group(2).strip()).lower()
            s = re.sub(r"0x0*", "0x", s)
            out.append(s)
    return out

def asm(lines, tag):
    p = os.path.join(OUT, "ins86_%s.fasm" % tag)
    io.open(p, "w").write("\n".join(lines) + "\n")
    a = run(FASM + [p, p + ".bin"])
    o = (a.stdout or "") + (a.stderr or "")
    if "passes," not in o: return None
    return io.open(p + ".bin", "rb").read()

SYMS = ["use16", "org 0"] + ["%s = 4660" % s for s in
        ("FRETOP", "STKLOW", "BEGDSG", "SAVSEG", "CPMEXT", "TEMP", "VARTAB",
         "ARYTAB", "STREND", "MEMSIZ", "CURLIN", "TXTTAB", "DATPTR", "NXTOPR")]
MAC = [l for l in headers.HAND["OEM.H"][1].split("\n")]

# Sites where the bytes are correct but the comment cannot be matched one to one.
# Both were checked by hand against the surrounding code.
KNOWN = {
  # opcode only; the immediate follows as "DB 128D / DB 0", so the instruction
  # spans three source lines and a per-site comparison cannot see it
  ("ADVGRP.ASM", "5"): "ADD AX,imm16 whose immediate is in the following DBs",
  # implements BASIC's OR, whose operands are BX and DX -- cf. the neighbouring
  # AND BX,DX (23 DA) and XOR BX,DX (33 DA).  The comment is a typo for OR BX,DX.
  ("GWEVAL.ASM", "13,332"): "comment says OR BX,BX; the bytes are OR BX,DX",
}

sites, ok, mism, skip, known = 0, 0, [], 0, 0
for f in sorted(x for x in os.listdir(pristine_dir()) if x.endswith(".ASM")):
    for raw in io.open(os.path.join(pristine_dir(), f), encoding="latin-1"):
        raw = raw.replace("\r", "")
        m = re.match(r"^\s*INS86\s+([^;]+);(.*)$", raw)
        if not m: continue
        sites += 1
        args, cmt = m.group(1).strip().rstrip(), m.group(2)
        want = fasmify(cmt)
        if not want: skip += 1; continue
        a = asm(SYMS + MAC + ["@INS86 " + args], "a")
        b = asm(SYMS + [want], "b")
        if a is None or b is None: skip += 1; continue
        da, db = disasm(a), disasm(b)
        if da == db: ok += 1
        elif (f, args) in KNOWN: known += 1
        else: mism.append((f, args, cmt.strip(), want, " / ".join(da), " / ".join(db)))

print("INS86 sites with a comment: %d" % sites)
print("  verified identical to the commented instruction: %d" % ok)
print("  known exceptions, verified by hand: %d" % known)
for (f, a), why in sorted(KNOWN.items()): print("      %-11s INS86 %-8s %s" % (f, a, why))
print("  mismatched: %d" % len(mism))
print("  comment not a decodable mnemonic: %d" % skip)
for f, args, cmt, want, a, b in mism[:20]:
    print("    %-11s INS86 %-16s ;%-24s" % (f, args, cmt))
    print("        %-34s vs %s" % ("INS86: " + a, want + ": " + b))
sys.exit(1 if mism else 0)
