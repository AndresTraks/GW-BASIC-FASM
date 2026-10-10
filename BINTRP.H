;               Include file for BINTRP.ASM

include 'OEM.H'  ; General definitions

macro @MOVRI B,C,D,E {
  DB      185
  DB      C
  DB      B
  DB      186
  DB      E
  DB      D
}

; Reserve word table generating Macros






; Dispatch table generating Macros.  We have to play games with the
; external declarations as ASM86 won't allow something to be declared
; external during pass 2.  Instead we build a chain of dummy macros
; that could generate the declaration for all potentially external
; reserve word dispatch addresses.

; play games with a possible external.  Create a new
; macro for the symbol and text, and string it together
; with a central invoker

if 1
    @@Qi=0
end if

macro @@QZ0 {}
macro @@Qz0 {}

; add an external declaration to S with type NEAR if it is not defined

macro @ADD_EXT {}
macro @add_ext {}

; define a macro called that possibly externals S:NEAR and then calls macro n

macro @DEF_MAC {}
macro @def_mac {}

; call the macro chain

macro @DO_EXT {}
macro @do_ext {}

macro @EXPAND_MAC {}
macro @expand_mac {}




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

macro @DERMAK dummy,X { @DER#X: mov dl, @ERR#X
  db 271o }

; The DERMAK chain works because the 271o (0B9h, "MOV CX,imm16") swallows the
; next entry's two-byte "MOV DL,imm8", so entering anywhere runs that entry's
; MOV DL and then skips the rest of the table.  After the last entry MASM does
; "ORG $-1" to overwrite the final, useless skip byte with the JMP that follows.
; fasm cannot rewind its output, so the last entry uses this variant, which
; simply never emits the byte.
macro @DERMAK_END dummy,X { @DER#X: mov dl, @ERR#X }
