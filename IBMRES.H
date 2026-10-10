; Include file for IBMRES.ASM

include 'OEM.H'  ; General definitions

; Reserve word table generating Macros








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
