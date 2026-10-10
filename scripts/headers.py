"""The header macros that have no mechanical fasm equivalent.

MASM's text machinery -- IRPC, IFB/IFNB, "&" name building -- cannot be
translated line by line, so these macros are stripped from the translated
headers and replaced with hand-written fasm versions.
"""
import io, re

# Macros whose MASM text machinery (IRPC, IFB/IFNB, IFDIF, & name building)
# has no mechanical fasm equivalent: stripped and written by hand below.
HAND = {
 "OEM.H": (["INS86", "DC"], r"""
macro @INS86 A,B,C,D {
  db A#o
  match any, B \{ db B#o \}
  match any, D \{ db C#o
                  db D#o \}
  match , D \{ match any, C \\{ dw C \\} \}
}
macro @DC ARG { db ARG }
"""),
 "MSDOSU": (["CALLOS"], r"""
macro @CALLOS FUNC { match any, FUNC \{ mov ah, FUNC \}
  int 21h }
"""),
 "BINTRP.H": (["T", "Q", "QF", "R", "R2", "un_def", "DERMAK"], None),
 "IBMRES.H": (["T", "Q", "QF", "R", "R2", "un_def"], None),
}
# Reserved-word table macros.  Arguments pass RAW; the macro applies the naming
# function itself, because the same parameter is used both as a name fragment
# (@@S#RESWRD = the token value $RESWRD) and as a symbol (@#RESDSP = an address).
TABLE = r"""
macro @un_def dummy,RESWRD { display "+++ Undefined reserved word", 10 }

; Emits the word with its FIRST CHARACTER DROPPED and the high bit set on the
; last -- the GW-BASIC table is indexed by initial letter.  MASM does the same
; via "IF $F", which is false on the first IRPC iteration.  TXT is the original
; MASM token as a string literal: the escaped symbol name must never be the
; source of the emitted characters ($CHR$ -> @@SCHR@S would spell "HR@S").
macro @RESCHARS TXT {
  local len, c
  virtual at 0
    db TXT
    len = $
  end virtual
  repeat len - 1
    virtual at 0
      db TXT
      load c byte from %
    end virtual
    if % = len - 1
      db c or 128
    else
      db c
    end if
  end repeat
}
macro @T dummy,RESWRD { @QQ = @QQ + 1
  @@S#RESWRD = @QQ }
macro @Q dummy,RESWRD,TXT {
  if defined @@S#RESWRD
    @RESCHARS TXT
    db @@S#RESWRD
  else
    @un_def ,RESWRD
  end if }
macro @QF dummy,RESWRD,TXT {
  if defined @@S#RESWRD
    @RESCHARS TXT
    db @@S#RESWRD - 128
  else
    @un_def ,RESWRD
  end if }
macro @R dummy,RESWRD { dw @#RESWRD
  @QQ = @QQ + 1
  @@S#RESWRD = @QQ }
macro @R2 dummy,RESWRD,RESDSP { dw @#RESDSP
  @QQ = @QQ + 1
  @@S#RESWRD = @QQ }
"""
DERMAK = r"""
macro @DERMAK dummy,X { @DER#X: mov dl, @ERR#X
  db 271o }

; The DERMAK chain works because the 271o (0B9h, "MOV CX,imm16") swallows the
; next entry's two-byte "MOV DL,imm8", so entering anywhere runs that entry's
; MOV DL and then skips the rest of the table.  After the last entry MASM does
; "ORG $-1" to overwrite the final, useless skip byte with the JMP that follows.
; fasm cannot rewind its output, so the last entry uses this variant, which
; simply never emits the byte.
macro @DERMAK_END dummy,X { @DER#X: mov dl, @ERR#X }
"""

def strip_macros(path, names):
    t = io.open(path, encoding="latin-1").read().split("\n")
    out, drop, depth = [], False, 0
    low = {n.lower() for n in names}
    for l in t:
        m = re.match(r"^macro\s+@?([A-Za-z_$?@@][\w$?@@]*)", l)
        if m and m.group(1).lstrip("@").lower() in low:
            drop, depth = True, l.count("{") - l.count("}")
            if depth <= 0: drop = False
            continue
        if drop:
            depth += l.count("{") - l.count("}")
            if depth <= 0: drop = False
            continue
        out.append(l)
    io.open(path, "w", encoding="latin-1").write("\n".join(out))



def finish(path, name):
    """Strip the untranslatable macros from a converted header and append the
    hand-written replacements."""
    if name not in HAND: return
    names, tail = HAND[name]
    strip_macros(path, names)
    extra = tail if tail else (TABLE + (DERMAK if name == "BINTRP.H" else ""))
    io.open(path, "a", encoding="latin-1").write(extra)
