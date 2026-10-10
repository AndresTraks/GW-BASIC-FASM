; [ This translation created 10-Feb-83 by Version 4.3 ]

if @GW_PASS = 1

include 'OEM.H'

; TITLE   GIOSCN - Screen Machine Independent Device Driver Code

; COMMENT	*

; --------- --- ---- -- ---------
; COPYRIGHT (C) 1982 BY MICROSOFT
; --------- --- ---- -- ---------

; 	*
include 'GIO86U'

@CPM86=0  ;CPM86 Operating System
@GIOSCN@_IBMCSR=@IBMLIK  ;IBM compatibile cursor control interface

;Definition of scroll types
; Choice of scroll type is by switch SCROLT.
; Switches defined here are used to implement a specific SCROLT type.
; If other scroll types are needed then additional SCROLT types should be
;   defined here.
	@GIOSCN@_INVLIN=@SCROLT  ;Invisible (function key) Line
	@GIOSCN@_FKFSRL=(@SCROLT-1) AND 1  ;Clear fkeys/full scroll/rewrite fkeys

include 'MSDOSU'  ;Operating System Constants

; PUBLIC	SCNDSP,SCNINI,SCNTRM
; EXTRN	DERBFM:NEAR,INIFDB:NEAR
; EXTRN	DEVBIN:NEAR,DEVBOT:NEAR
end if
; EXTRN	TWOBYT:WORD
if @GW_PASS = 1

;Screen Dispatch Table

@SCNDSP:
	DW	(@DERBFM)  ;test EOF for file opened to this device
	DW	(@DERBFM)  ;LOC
	DW	(@DERBFM)  ;LOF
	DW	(@GIOSCN@_SCNCLS)  ;perform special CLOSE functions for this device
	DW	(@SCNSWD)  ;set device width
	DW	(@DERBFM)  ;GET/PUT random record from/to this device
	DW	(@GIOSCN@_SCNOPN)  ;perform special OPEN functions for this device
	DW	(@DERBFM)  ;input 1 byte from file opened on this device
	DW	(@SCNSOT)  ;output 1 byte to file opened on this device
	DW	(@SCNGPS)  ;POS
	DW	(@SCNGWD)  ;get device width
	DW	(@SCNSCW)  ;set device comma width
	DW	(@SCNGCW)  ;get device comma width
	DW	(@DEVBIN)  ;block input from file opened on this device
	DW	(@DEVBOT)  ;block output to file opened on this device
; PUBLIC	SCNSWD,SCNSOT,SCNGPS,SCNGWD,SCNSCW,SCNGCW
; SUBTTL CRT Primitive I/O Routines

;SCNINI is called to initialize Screen when BASIC comes up

end if
; EXTRN	WDTFLG:WORD
if @GW_PASS = 1
@SCNINI:
	MOV	AL,byte [@LINLEN]  ; Get CRT logical line length
	MOV	byte [@WDTFLG],AL  ; Default width of device SCRN:
	RET

;SCNTRM is called to Clean-up Screen when BASIC terminates

; EXTRN	TKEYOF:NEAR
@SCNTRM:	CALL	@TKEYOF  ;Turn off KEY display
; EXTRN	SCNPOS:NEAR
	CALL	@SCNPOS  ;[DX]=current cursor location
	RET

;SCNCLS - perform any device dependent close functions.
; Entry - SI points to File-Data-Block.
; Exit  - All registers preserved.
;         This routine is called before BASIC releases the
;         file-data-block associated with this file.

@GIOSCN@_SCNCLS:	RET

;SCNSWD - set device width
; Entry - [DX] = new device width
; Exit  - All registers preserved

@SCNSWD:
; EXTRN	SWIDTH:NEAR
end if
; EXTRN	LINCNT:WORD,WDTFLG:WORD
if @GW_PASS = 1
	MOV	byte [@WDTFLG],DL  ;Set/Reset infinite length flag
	CMP	DL,((255) and 0FFh)
	JNZ	@GIOSCN@_SCNWD1  ;BRIF not infinite length
	RET
@GIOSCN@_SCNWD1:	PUSH	CX
	PUSH	AX
	MOV	AL,DL  ;pass Width in AL
	MOV	CL,byte [@LINCNT]  ;pass Height in CL
	CALL	@SWIDTH  ;Let screen editor set width
	POP	AX
	POP	CX
	RET

;SCNOPN - perform any device dependent open functions.
; Entry - [AL]=  device id
;                0 if default device,
;                1..n for Disk A:, B:, ...
;                -1..-n for non-disk devices
;         [BX] = file number (0..n)
;         [CX] = random record size if [FILMOD] = random
;                (if [CX] = 0, use default record size)
;         [DI] = device offset (2=SCND, 4=SCRN, etc.)
;         [FILMOD] = file mode
;                    MD.SQI = 1 ;sequential input
;                    MD.SQO = 2 ;sequential output
;                    MD.RND = 3 ;random
;                    MD.APP = 4 ;append
;         [FILNAM] = filename
;         [FILEXT] = 1..3 byte filename extension
; Exit  - [SI] points to new FDB
;         FDB is linked into FDB chain with all standard
;         fields initialized.
;         All other registers are preserved.

@GIOSCN@_SCNOPN:
	CALL	@SCNGPS  ;[AH]=current column position
	MOV	DH,AH  ;[DH]=current column position
	MOV	AH,((@MD_SQO) and 0FFh)  ;allow open for output only
	MOV	DL,byte [@WDTFLG]  ;initial file logical width
	JMP	@INIFDB

; PUBLIC	CALTTY,$CATTY

;CALTTY IS A SPECIAL ROUTINE TO OUTPUT ERROR MESSAGE TO TTY, REGARDLESS
;   OF CURRENT FILE I/O.
; Entry - [AL] = byte to be output
; Exit  - All registers preserved

; EXTRN	OUTDO:NEAR
end if
; EXTRN	PTRFIL:WORD
if @GW_PASS = 1
@@SCATTY:
@CALTTY:	PUSH	word [@PTRFIL]
	MOV	word [@PTRFIL],0  ;Make sure we go to the "TTY"
	CALL	@OUTDO
	POP	word [@PTRFIL]
	RET

;SCNSOT - Sequential Output.
; Entry - SI points to File-Data-Block.
;         [AL] = byte to be output.
; Exit  - SI, DI can be changed.
;         All other registers preserved
;         This routine expands tabs if appropriate.
;         It need not force a carriage return when width
;         exceeded as this is handled at a lower level.

@SCNSOT:
; EXTRN	SCNOUT:NEAR
	PUSHF
	PUSH	AX

;If last char SCNSOT was called with was the 1st byte of a 2-byte char,
; SCNSOT saved it in TWOBYT so they be both output as one 16-bit character.

	MOV	AH,byte [@TWOBYT]  ;If two byte, put first in [AH]
	OR	AH,AH
	JZ	@GIOSCN@_SCNSO1  ;BRIF not second of two bytes
	MOV	byte [@TWOBYT],((0) and 0FFh)  ;Clear TWOBYT flag
	JMP	@GIOSCN@_SCNSO3  ;Output both bytes at once
@GIOSCN@_SCNSO1:
end if
; EXTRN	F_EDIT:WORD
if @GW_PASS = 1
	TEST	byte [@F_EDIT],((255) and 0FFh)
	JZ	@GIOSCN@_SCNS1A  ;BRIF not in editor, don't collect FF codes
	CMP	AL,((255) and 0FFh)
	JZ	@GIOSCN@_SCNS1B  ;BRIF is first of two bytes
@GIOSCN@_SCNS1A:
	JMP	@GIOSCN@_SCNSO2  ;branch if not 1st of 2-bytes
@GIOSCN@_SCNS1B:
	MOV	byte [@TWOBYT],AL  ;save char for next time
	JMP	@GIOSCN@_SCNSOX  ;Set two byte flag and return
@GIOSCN@_SCNSO2:
	XOR	AH,AH  ;clear high-byte (not 2-byte char)
@GIOSCN@_SCNSO3:	CALL	@GIOSCN@_SCNOL1
@GIOSCN@_SCNSOX:	POP	AX
	POPF
	RET

;SCNSOT level 1
; Outputs AX, destroys AX

@GIOSCN@_SCNOL1:
end if
; EXTRN	LSTCHR:WORD
if @GW_PASS = 1
;For IBM Compatibility, the following filter performs the following translations
;    x x x CR x x x    === x x x CR LF x x x
;    x x x CR LF x x x === x x x CR LF x x x

;    If (Char = CR) then
;       output CR : output LF
;    else if (char <> LF) or (LSTCHR <> CR) then
;       output char
;    else
;       {eat the LF which follows a CR}
;    LSTCHR = CHR

	CMP	byte [@LSTCHR],((@ASCCR) and 0FFh)
	MOV	byte [@LSTCHR],AL  ;save this char for comparison with next
	JNE	@GIOSCN@_NTCRLF  ;branch if not LF after CR
	CMP	AL,((@ASCLF) and 0FFh)
	JE	@GIOSCN@_RET22  ;eat LF if it follows CR
@GIOSCN@_NTCRLF:
	PUSH	AX
	CALL	@GIOSCN@_SCNOL2  ;output this char
	POP	AX
	CMP	AL,((@ASCCR) and 0FFh)
	JNE	@GIOSCN@_RET22  ;if not CR, just output char
	MOV	AX,@ASCLF  ;else map CR to CR LF
	CALL	@GIOSCN@_SCNOL2
@GIOSCN@_RET22:	RET

;SCNSOT level 2
; Output [AX], destroys AX

@GIOSCN@_SCNOL2:
	OR	SI,SI
	JZ	@GIOSCN@_SCNSO8  ;BRIF is not file I/O
	CMP	AL,((@ASCCR) and 0FFh)
	JZ	@GIOSCN@_SCNSO8  ;BRIF CR, don't do wrap
	PUSH	AX  ;save char to be output
	MOV	AL,byte [@CSRX]
	OR	AH,AH  ;see if 2-byte char
	JZ	@GIOSCN@_SCNSO4  ;BRIF not DBLCHR
	INC	AL  ;Need two char posns for DBLCHR
@GIOSCN@_SCNSO4:
	CMP	AL,byte [@F_WID+SI]  ;Compare posn with file width
	JA	@GIOSCN@_SCNSCR  ;Beyond max, force CR
	CMP	AL,byte [@LINLEN]
	JBE	@GIOSCN@_SCNSO7  ;Within line, go ahead and output
	DEC	AL
	MOV	byte [@CSRX],AL  ;Make sure there's room before end of line
@GIOSCN@_SCNSO7:	POP	AX  ;restore char to be output
@GIOSCN@_SCNSO8:
	JMP	@SCNOUT  ;Output the char in [AX] and return

@GIOSCN@_SCNSCR:	CMP	AL,byte [@LINLEN]
	JZ	@GIOSCN@_SCNSO7  ;BRIF file width .EQ. device width, use wrap code
	MOV	AX,@ASCCR
	CALL	@SCNOUT  ;Force new line
	MOV	AX,@ASCLF
	CALL	@SCNOUT
	JMP	@GIOSCN@_SCNSO7  ;Output the character

;POS(X) function

; PUBLIC	POS
; EXTRN	SNGFLT:NEAR
end if
; EXTRN	LINLEN:WORD
if @GW_PASS = 1
@POS:	MOV	AL,byte [@CSRX]  ;[AL]=current 1 relative position
	CMP	AL,byte [@LINLEN]
	JBE	@GIOSCN@_POS0  ;BRIF not beyond end of line
	MOV	AL,((1) and 0FFh)  ;Else next char will go in first column
@GIOSCN@_POS0:	JMP	@SNGFLT  ;return result to user

;SCNGPS - return current file position.
; Entry - SI points to File-Data-Block.
; Exit  - [AH] = current file column. (0-relative)
;         All other registers preserved

end if
; EXTRN	CSRX:WORD
if @GW_PASS = 1
@SCNGPS:	MOV	AH,byte [@CSRX]
	PUSHF
	CMP	AH,byte [@LINLEN]
	JBE	@GIOSCN@_SCNGP1  ;BRIF not beyond edge of screen
	MOV	AH,byte [@LINLEN]  ;Force posn within screen
@GIOSCN@_SCNGP1:	POPF
	DEC	AH  ;Make it 0 relative
	RET

;SCNGWD - get device width
; Exit  - [AH] = device width as set by xxxSWD
;         All other registers preserved

@SCNGWD:
end if
; EXTRN	LINLEN:WORD
if @GW_PASS = 1
	MOV	AH,byte [@LINLEN]
	OR	SI,SI
	JZ	@GIOSCN@_SCNGWX  ;BRIF not file I/O, use device width
	MOV	AH,byte [@F_WID+SI]  ;Is file I/O, use FDB width
@GIOSCN@_SCNGWX:	RET

;SCNSCW - set device comma width
; Entry - [BX] = new device comma width
; Exit  - SI, DI can be changed.
;         All other registers preserved

@SCNSCW:	RET

;SCNGCW - get device comma width
; Exit  - [BX] = device comma width as set by xxxSCW
;         All other registers preserved

@SCNGCW:	RET

end if

; ---- end of translation unit: drop its file-scoped macros ----
purge @@QZ0
purge @@Qz0
purge @ACRLF
purge @acrlf
purge @ADD_EXT
purge @add_ext
purge @ADR
purge @adr
purge @ADRP
purge @adrp
purge @CALLOS
purge @callos
purge @CHRGET
purge @chrget
purge @COMPAR
purge @compar
purge @CPMXIO
purge @cpmxio
purge @DC
purge @dc
purge @DCE
purge @dce
purge @DCL
purge @dcl
purge @DCUL
purge @dcul
purge @DEF_MAC
purge @def_mac
purge @DERMAK
purge @dermak
purge @DEV
purge @dev
purge @DJNZ
purge @djnz
purge @DOSIO
purge @dosio
purge @DO_EXT
purge @do_ext
purge @EXPAND_MAC
purge @expand_mac
purge @FSIGN
purge @fsign
purge @GETYPE
purge @getype
purge @HLFDE
purge @hlfde
purge @HLFHL
purge @hlfhl
purge @INS86
purge @ins86
purge @INST
purge @inst
purge @LDDR
purge @lddr
purge @LDIR
purge @ldir
purge @M
purge @m
purge @MOVRI
purge @movri
purge @NAMES
purge @names
purge @NDEV
purge @ndev
purge @NEGDE
purge @negde
purge @NEGHL
purge @neghl
purge @OUTCHR
purge @outchr
purge @PDIRAM
purge @pdiram
purge @PDURAM
purge @pduram
purge @POPR
purge @popr
purge @PUSHM
purge @pushm
purge @PUSHR
purge @pushr
purge @Q
purge @q
purge @QF
purge @qf
purge @R
purge @r
purge @R1
purge @r1
purge @R2
purge @r2
purge @RINIT
purge @rinit
purge @ROFFST
purge @roffst
purge @SYNCHK
purge @synchk
purge @T
purge @t
purge @UN_DEF
purge @un_def
