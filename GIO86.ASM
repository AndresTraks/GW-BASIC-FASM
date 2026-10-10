; [ This translation created 10-Feb-83 by Version 4.3 ]

if @GW_PASS = 1

include 'OEM.H'

; TITLE   GIO86   - BASIC-86 Interpreter Device Independent I/O Module

; COMMENT	*

; --------- --- ---- -- ---------
; COPYRIGHT (C) 1982 BY MICROSOFT
; --------- --- ---- -- ---------

;         T. Corbett      Microsoft Inc.

;         *
include 'GIO86U'

@CPM86=0
@GIO86@_IBMCSR=@IBMLIK  ;IBM Compatible Cursor Handling

include 'MSDOSU'

end if
; EXTRN	DEVPTR:WORD,DEVTBL:WORD,DEVINI:WORD,DEVTRM:WORD
; EXTRN	NLONLY:WORD,RUNFLG:WORD
; EXTRN	FILMOD:WORD,FILDEV:WORD,FILNM:WORD,FILEXT:WORD
; EXTRN	PTRFIL:WORD,FILTAB:WORD,STKLOW:WORD
if @GW_PASS = 1

; EXTRN	SNERR:NEAR,FCERR:NEAR
; EXTRN	FRESTR:NEAR,GETYPR:NEAR
; EXTRN	$_KYBD:NEAR,$_LPT1:NEAR,$_NDEV:NEAR
; EXTRN	DERBFM:NEAR,DERBFN:NEAR,DERFAO:NEAR,DERFNO:NEAR,DERIFN:NEAR
; EXTRN	DERDNA:NEAR,DERFDR:NEAR

macro @DOSIO DFUN {
  MOV	AH,((DFUN) and 0FFh)
  INT	33
}

; SUBTTL OPEN statement

; PUBLIC	OPEN
; EXTRN	$LEN:NEAR,EQULTK:NEAR,$FOR:NEAR,$INPUT:NEAR,GETBYT:NEAR
; EXTRN	GWWID:NEAR

; OPEN Statement
; Syntax:
;  OPEN filespec FOR mode AS fnum [LEN=random-record-length]
;  OPEN mode,fnum,filespec[,random-record-length]

@OPEN:	CALL	@FRMEVL  ;read the file mode or filename
	MOV	AL,byte [BX+0]  ;get terminator
	CMP	AL,((44) and 0FFh)  ;followed by comma? (then
; non-spcdsk open...)
	JNZ	@GIO86@_NOTNSO  ;nope, must be SPCDSK form
	PUSH	BX  ;save the text pointer
	CALL	@FRESTR  ;free string temp & check string
	MOV	AL,byte [BX+0]  ;make sure its not a null string
	OR	AL,AL
	JZ	@GIO86@_ERBFM0  ;if so, "bad file mode"
	INC	BX
	MOV	BX,word [BX+0]  ;[BX] points at mode character
	MOV	AL,byte [BX+0]  ;[A]=mode character
	AND	AL,((-1-" ") and 0FFh)  ;force to upper case
	MOV	DH,((@MD_SQO) and 0FFh)  ;assume its "O"
	CMP	AL,(("O") and 0FFh)  ;is it?
	JZ	@GIO86@_HAVMOD  ;[D] has correct mode
	MOV	DH,((@MD_SQI) and 0FFh)  ;assume sequential
	CMP	AL,(("I") and 0FFh)  ;is it?
	JZ	@GIO86@_HAVMOD  ;[D] says sequential input
	MOV	DH,((@MD_APP) and 0FFh)  ;append?
	CMP	AL,(("A") and 0FFh)  ;test
	JZ	@GIO86@_HAVMOD  ;allow it
	MOV	DH,((@MD_RND) and 0FFh)  ;must be random
	CMP	AL,(("R") and 0FFh)
	JNZ	@GIO86@_ERBFM0  ;if not, no match so "bad file mode"
@GIO86@_HAVMOD:	MOV	byte [@FILMOD],DH  ;set file mode
	POP	BX  ;get back the text pointer
	CALL	@SYNCHR
	DB	44  ;skip comma before file number
@GIO86@_HAVMD1:	CALL	@GIO86@_POFNUM  ;[AL]=the file number
	PUSH	AX  ;save file number
	CALL	@SYNCHR
	DB	44  ;skip comma before name
	CALL	@NAMSCN  ;parse filename setting FILDEV, FILNM, FILEXT
	CALL	@GIO86@_PORLEN  ;parse reclen parm
	JMP	@GIO86@_OPEN1  ;branch to common code (with Fnum on stack)

@GIO86@_ERBFM0:	JMP	@DERBFM  ;bad file mode error

@GIO86@_NOTNSO:	CALL	@GIO86@_NAMSC1  ;parse filename setting FILDEV, FILNM, FILEXT
	MOV	DH,((@MD_RND) and 0FFh)  ;Assume there is no FOR, in which
;case the default mode is random.
	MOV	AL,byte [BX+0]
	CMP	AL,((@@SFOR) and 0FFh)  ;Is there a 'FOR'?
	JNZ	@GIO86@_GOTMOD  ;No, better see 'AS'
	CALL	@CHRGTR
	CMP	AL,((@@SINPUT) and 0FFh)  ;Input mode?
	MOV	DH,((@MD_SQI) and 0FFh)  ;Assume it is
	JZ	@GIO86@_GOTMD1  ;Yes, have file mode
	CMP	AL,(("A") and 0FFh)  ;test
	JNE	@GIO86@_NTAPP  ;branch if not append (might be OUTPUT)
	CALL	@SYNCHR
	DB	"A"
	CALL	@SYNCHR
	DB	"P"
	CALL	@SYNCHR
	DB	"P"
	CALL	@SYNCHR
	DB	"E"
	CALL	@SYNCHR
	DB	"N"
	CALL	@SYNCHR
	DB	"D"
	MOV	DH,((@MD_APP) and 0FFh)  ;append file mode
	JMP	@GIO86@_GOTMOD  ;allow it
@GIO86@_NTAPP:
	CALL	@SYNCHR
	DB	"O"  ;it must be OUTPUT
	CALL	@SYNCHR
	DB	"U"
	CALL	@SYNCHR
	DB	"T"
	CALL	@SYNCHR
	DB	"P"
	CALL	@SYNCHR
	DB	"U"
	CALL	@SYNCHR
	DB	"T"
	MOV	DH,((@MD_SQO) and 0FFh)
	JMP	@GIO86@_GOTMOD

@GIO86@_GOTMD1:	CALL	@CHRGTR
@GIO86@_GOTMOD:	MOV	byte [@FILMOD],DH  ;set file mode
	CALL	@SYNCHR
	DB	"A"
	CALL	@SYNCHR
	DB	"S"  ;Must have 'AS'
	CALL	@GIO86@_POFNUM  ;[AL]=file #
	PUSH	AX  ;save file#
	CALL	@GIO86@_PNRLEN  ;parse new reclen parameter
@GIO86@_OPEN1:	DEC	BX
	CALL	@CHRGTR
	JNZ	@GIO86@_SNERR1  ;error if not end-of-statement
	POP	AX  ;[AL]=file number
	CALL	@GIO86@_OPNFIL  ;branch to general file-open code
	JMP	@FINPRT  ;reset PTRFIL to 0 (keyboard/crt)

;PORLEN - parse old variable record length field
; Entry - [FILMOD]=file mode
; Exit  - [CX]=reclen if reclen parm included, else 0

@GIO86@_PORLEN:	CALL	@GIO86@_PRLENC
	JZ	@GIO86@_PRLENX
	CALL	@SYNCHR
	DB	44
	JMP	@GIO86@_VARECS

;PNRLEN - parse new variable record length field
; Entry - [FILMOD]=file mode
; Exit  - [CX]=reclen if reclen parm included, else 0

@GIO86@_PNRLEN:	CALL	@GIO86@_PRLENC
	JZ	@GIO86@_PRLENX
	CALL	@SYNCHR
	DB	255  ;else parse "LEN=record-length"
	CALL	@SYNCHR
	DB	@@SLEN  ;LEN is a 2-byte token
	CALL	@SYNCHR
	DB	@EQULTK
; EXTRN	INTID2:NEAR
@GIO86@_VARECS:	CALL	@INTID2  ;[DX]=record size (0..32767)
	MOV	CX,DX  ;return it in CX
	OR	CX,CX
	JZ	@GIO86@_FCERR1  ;0 is illegal value
@GIO86@_PRLENX:	RET

;PRLENC - see if reclen parm is expected

@GIO86@_PRLENC:
	MOV	CX,0  ;indicates reclen parm not included
	MOV	AL,byte [@FILMOD]  ;[AL]=requested file mode
	CMP	AL,((@MD_RND) and 0FFh)
	JNZ	@GIO86@_NOLEN  ;branch if file mode is not RANDOM
	DEC	BX  ;decrement text pointer
	CALL	@CHRGTR  ;re-get last character parsed
	JZ	@GIO86@_NOLEN  ;branch if end-of-statement
	MOV	CL,((1) and 0FFh)  ;indicates reclen parm included
@GIO86@_NOLEN:	OR	CX,CX  ;set NZ if reclen parm included
	RET

@GIO86@_FCERR1:	JMP	@FCERR  ;function call error

@GIO86@_SNERR1:	JMP	@SNERR  ;syntax error

; SUBTTL CLOSE, WIDTH Statements

; PUBLIC	CLOSE

; CLOSE Statement
;  Syntax: CLOSE [[#]n [,[#]n ...]]

@CLOSE:	JNZ	@GIO86@_CLOS1  ;branch if statement has parm
	JMP	@CLSALL  ;close all files if no parm given
@GIO86@_CLOS1:	CMP	AL,(("#") and 0FFh)
	JNZ	@GIO86@_NOLBS  ;branch if no #
	CALL	@CHRGTR  ;skip #
@GIO86@_NOLBS:
	CALL	@GETBYT  ;[AL]=file#
	CALL	@CLSFIL  ;close file [AL] and return
	DEC	BX
	CALL	@CHRGTR
	CMP	AL,((44) and 0FFh)  ;check for comma
	JNZ	@GIO86@_RET6  ;branch if end of file list
	CALL	@CHRGTR  ;skip comma
	JMP	@GIO86@_CLOS1  ;close next file in list

; PUBLIC	WIDTHS

; WIDTH Y[,X]/[#fnum,]/[device,]   Statement
; Entry - (BX) = text pointer

@WIDTHS:	CMP	AL,(("#") and 0FFh)
	JZ	@GIO86@_FILWID  ;Is files WIDTH specification
	CMP	AL,((44) and 0FFh)
	JZ	@GIO86@_CRTWD1  ;branch if Comma
; EXTRN	$LPRINT:NEAR,$_LPT1:NEAR
	CMP	AL,((@@SLPRINT) and 0FFh)
	JNZ	@GIO86@_NOTLPR  ;branch if not WIDTH LPRINT
	CALL	@CHRGTR  ;skip LPRINT
	MOV	AL,((@@S_LPT1) and 0FFh)
	JMP	@GIO86@_ITSWLP
@GIO86@_NOTLPR:
	PUSH	BX  ;save Text Pointer in case CRT width
	CALL	@FRMEVL  ;evaluate string or number
	CALL	@GETYPR
	JNZ	@GIO86@_CRTWD  ;brif not string argument. CRT width
	POP	SI  ;discard old text pointer
	PUSH	BX  ;save text pointer
	CALL	@FRESTR  ;release temporary string descriptor
;[BX] points to string descriptor
	MOV	CL,byte [BX+0]
	MOV	CH,((0) and 0FFh)  ;[CX]=length of string
	MOV	SI,word [BX+1]  ;SI points to start of string
	CALL	@GIO86@_PARDEV  ;AL=-(device number)
	POP	BX  ;restore text pointer
	PUSH	AX  ;save device id
	CALL	@SYNCHR
	DB	44
	POP	AX  ;[AL]=device id
@GIO86@_ITSWLP:
	PUSH	AX  ;save device id
	CALL	@GIO86@_GETWDT  ;[DL]=width
	POP	AX  ;[AL]=device id
	CALL	@GIO86@_CDEVID  ;[DI]=device dispatch table offset
	JZ	@GIO86@_ERIFN0  ;illegal file name if device=disk
	MOV	AH,((@G_SWD) and 0FFh)  ;select set-width function
	JMP	@GIO86@_TBLDSP  ;dispatch function [AH] for device [DI]

@GIO86@_FILWID:	CALL	@GIO86@_PRFNUM  ;[AL]=file number
	CALL	@GIO86@_FDBPTR  ;[SI] points to file-data-block
	JZ	@GIO86@_ERFNO1  ;branch if file not opened
	PUSH	SI
	CALL	@SYNCHR
	DB	44
	CALL	@GIO86@_GETWDT  ;[AL]=width (1..255)
	POP	SI  ;SI points to file data block
	MOV	byte [@F_WID+SI],AL  ;save width in FDB
@GIO86@_RET6:	RET

@GIO86@_GETWDT:	CALL	@GETBYT
	OR	AL,AL
	JZ	@GIO86@_FCERR2  ;width of 0 is illegal
	RET  ;return if width is between 1 and 255

@GIO86@_CRTWD:	POP	BX  ;restore text pointer
@GIO86@_CRTWD1:	JMP	@GWWID

@GIO86@_FCERR2:	JMP	@FCERR
@GIO86@_ERIFN0:	JMP	@DERIFN  ;illegal file name error
@GIO86@_ERFNO1:	JMP	@DERFNO  ;file not open error
@GIO86@_ERDNA1:	JMP	@DERDNA  ;Device not available

; SUBTTL BSAVE, BLOAD Statements

; PUBLIC	BLOAD,BSAVE
; EXTRN	GETBYT:NEAR,SYNCHR:NEAR,MAKINT:NEAR,CHRGTR:NEAR,SNERR:NEAR
; EXTRN	PRODIR:NEAR
end if
; EXTRN	SAVLEN:WORD,SAVSEG:WORD
if @GW_PASS = 1

; BSAVE Statement - Save memory image to file
; Syntax: BSAVE name, start-adr, byte-count

@BSAVE:	CALL	@GIO86@_BPARMS  ;parse parms
	INC	AL
	JNZ	@GIO86@_SNERR2  ;Error if 1 or no parms.
	PUSH	BX  ;save text pointer
	PUSH	CX  ;SAVE start-adr
	MOV	AL,((@MD_SQO) and 0FFh)  ;open file 0 for output
	CALL	@NULOPM
	CALL	@SCDBIN  ;set file-code to binary
	MOV	AL,((@BSVFID) and 0FFh)  ;output binary file ID
	CALL	@OUTDO  ;output to file
	MOV	AX,word [@SAVSEG]  ;DX=Segment from DEF SEG statement
	CALL	@GIO86@_OUT16  ;write segment adr to file
	POP	AX  ;[AX]=start-adr
	PUSH	AX
	CALL	@GIO86@_OUT16  ;output start adr
	MOV	AX,word [@SAVLEN]  ;[DX]=number of bytes
	MOV	CX,AX  ;[CX]=length
	CALL	@GIO86@_OUT16  ;output end adr + 1
	POP	BX  ;[BX]=start-adr
	MOV	DX,word [@SAVSEG]  ;DX=Segment adr
	CALL	@GIO86@_OUTBLK  ;output binary
	JMP	@GIO86@_LODEND  ;exit

@GIO86@_SNERR2:	JMP	@SNERR

; BLOAD Statement - load memory image from disk
; Syntax: BLOAD name[, start-adr]

@BLOAD:
	CALL	@GIO86@_BPARMS  ;Get Parms if any.
	OR	AL,AL
	JZ	@GIO86@_BLODP  ;Will set -1 if start-adr only given.
	INC	AL
	JZ	@GIO86@_SNERR2  ;error if 2 parms given
@GIO86@_BLODP:	DEC	AL  ;AL=1: no start-adr parm, -1: start-adr parm
	PUSH	BX  ;save text pointer
	PUSH	AX  ;save Parm Switch
	PUSH	CX  ;save start-adr parm
	MOV	AL,((@MD_SQI) and 0FFh)
	CALL	@NULOPM  ;Open File 0 for INPUT
	CALL	@SCDBIN  ;set file code to binary
	CALL	@INCHR  ;[A]=1st byte from file
	CMP	AL,((@BSVFID) and 0FFh)  ;make sure this was created by BSAVE
	JNZ	@GIO86@_ERBFM2  ;else BAD FILE MODE
	POP	CX  ;[CX]=start-adr parm
	CALL	@GIO86@_INP16  ;[AX]=next 16 bits from file
	MOV	DX,AX  ;[DX]=default segment
	CALL	@GIO86@_INP16  ;[AX]=next 16 bits from file
	MOV	BX,AX  ;[BX]=default start-adr
	POP	AX  ;AL=1: no start-adr parm, -1: start-adr parm
	DEC	AL
	JZ	@GIO86@_DEFSAD  ;branch if no start-adr parm given
	MOV	DX,word [@SAVSEG]  ;[DX]=segment parm
	MOV	BX,CX  ;[BX]=start-adr parm
@GIO86@_DEFSAD:	CALL	@GIO86@_INP16  ;[AX]=file length
	MOV	CX,AX  ;[CX]=file length
	CALL	@GIO86@_INPBLK  ;do the load
@GIO86@_LODEND:
	POP	BX  ;restore text pointer
	JMP	@FINPRT  ;close file 0, reset PTRFIL

@GIO86@_ERBFM2:	JMP	@DERBFM  ;bad file mode error

;BPARMS - Parse parms for BLOAD and BSAVE
; Exit  - [AL]=(1,0,-1) if 0,1,2 parameters parsed.
;         [BX] is preserved (text pointer)
;         [CX] = start-adr
;         [SAVLEN] = file size (if BSAVE)

@GIO86@_BPARMS:
	CALL	@PRODIR  ;Don't allow in direct mode if protected
	CALL	@NAMSCN  ;scan file name and disk number
;setting FILDEV, FILNM, FILEXT
	JB	@GIO86@_BNAMOK  ;Extension supplied by user
	CALL	@GIO86@_NAMBAS  ;Supply ".BAS" default extension
@GIO86@_BNAMOK:
	DEC	BX
	CALL	@CHRGTR  ;See if any parms
	JNZ	@GIO86@_BPARM2  ;Brif parms follow
	MOV	AL,((1) and 0FFh)  ;No Parms, use file header if BLOAD.
	RET  ; else exit.
@GIO86@_BPARM2:
	CALL	@SYNCHR
	DB	","  ;Must see comma first
	CALL	@ADRGET  ;get start-adr (0..65535)
	PUSH	DX  ;save it
	DEC	BX
	CALL	@CHRGTR
	JNZ	@GIO86@_BPARM3  ;Brif 2nd Parm given.
	POP	CX  ;[CX]=start adr
	XOR	AL,AL  ;Set 0 if 1 parm only given.
	RET
@GIO86@_BPARM3:
	CALL	@SYNCHR
	DB	","
	CALL	@ADRGET  ;[DX]=number of bytes for bsave (0..65535)
	XCHG	BX,DX
	MOV	word [@SAVLEN],BX  ;Save end ADDRESS+1(start+count)
	XCHG	BX,DX  ;[BX]=text pointer
	DEC	BX
	CALL	@CHRGTR
	JNZ	@GIO86@_SNERR3  ;must be end of statement
	POP	CX  ;[CX]=start-adr
	MOV	AL,((255) and 0FFh)  ;Set -1 if 2 parms given.
	RET

@GIO86@_SNERR3:	JMP	@SNERR

; SUBTTL LPRINT, PRINT Statements

; PUBLIC	LPRINT,PRINT
; EXTRN	PRINUS:NEAR,IMOD:NEAR,FOUT:NEAR,STRLIT:NEAR,STRPRT:NEAR
; EXTRN	USINTK:NEAR,TABTK:NEAR,SPCTK:NEAR
end if
; EXTRN	FACLO:WORD
if @GW_PASS = 1

@GIO86@_JPRINU:	JMP	@PRINUS  ;Print Using

@GIO86@_PRINTX:	CALL	@CRDO  ;output terminating CR
@GIO86@_PRNTX1:	POP	CX  ;discard line width, last comma column
	JMP	@FINPRT  ;close file#0, reset PTRFIL to keyboard

@LPRINT:	MOV	word [@PTRFIL],-1  ;future output will go to Line Printer
	JMP	@GIO86@_PRINT1
@PRINT:
	MOV	CL,((@MD_SQO) and 0FFh)  ;setup output file
	CALL	@FILGET
@GIO86@_PRINT1:	CALL	@GIO86@_PTRWDC  ;[CH]=width, [CL]=last comma column
	PUSH	CX  ;save on stack
@GIO86@_NEWCHR:	DEC	BX
	CALL	@CHRGTR  ;get another character
	JZ	@GIO86@_PRINTX  ;print CR if end without punctuation
@GIO86@_PRINTC:	JZ	@GIO86@_PRNTX1  ;branch if end of statement
	POP	CX  ;refresh [CH]=width, [CL]=last comma column
	CMP	AL,((@USINTK) and 0FFh)  ;is it "print using" ?
	JZ	@GIO86@_JPRINU  ;IF SO, USE A SPECIAL HANDLER
	PUSH	CX  ;save [CH]=width, [CL]=last comma column
	CMP	AL,((@TABTK) and 0FFh)
	JZ	@GIO86@_TABERJ  ;the TAB function?
	CMP	AL,((@SPCTK) and 0FFh)
	JZ	@GIO86@_TABERJ  ;the SPC function?
	PUSH	BX  ;save the text pointer
	CMP	AL,((44) and 0FFh)
	JZ	@GIO86@_COMPRT  ;Print Comma
	CMP	AL,((59) and 0FFh)  ;is it a ";"
	JNZ	@GIO86@_PRTS
	JMP	@GIO86@_NOTABR
@GIO86@_TABERJ:	JMP	@GIO86@_TABER
@GIO86@_PRTS:	POP	DX  ;get rid of old text pointer
	CALL	@FRMEVL  ;evaluate the formula
	PUSH	BX  ;save text pointer
	CALL	@GETYPR  ;see if we have a string
	JZ	@GIO86@_STRDON  ;if so, print special
	DEC	BX
	CALL	@CHRGTR  ;[BX]=addr of number terminator(non-blank)
	CMP	byte [BX+0],((44) and 0FFh)
	PUSHF  ;remember if value was comma terminated
	CALL	@FOUT  ;make a number into a string
	CALL	@STRLIT  ;make it a string
	MOV	byte [BX+0],((" ") and 0FFh)  ;put a space at the end
	POPF
	POP	BX
	POP	CX  ;restore [CH]=width, [CL]=last comma column
	PUSH	CX
	PUSH	BX
	MOV	BX,word [@FACLO]  ;[BX]=address of string descriptor
	JNZ	@GIO86@_INCLEN  ;BRIF not comma terminated(print the space too)
	CALL	@PTRGPS  ;[AL]=file's current position
	ADD	AL,byte [BX+0]  ;add length of string we will output
;At this point we have [AL]=posn after number is printed(without space),
;  [CH]=device width, [CL]=last comma posn, [BX]=addr of string descriptor.
;IF number output stops at comma column minus one
;THEN don't append blank(This insures that another number will appear at the
;next comma column, instead of the second column posn after this string)
	CMP	CH,((255) and 0FFh)  ;infinite width?
	JZ	@GIO86@_MODCOM  ;do modulus to determine next comma column
	CMP	AL,CL  ;compare with last comma column
	JNB	@GIO86@_INCLEN  ;Will do CR after do output,
; make string include blank
;Determine if posn in [AL] is one less than a comma column
@GIO86@_MODCOM:	INC	AL
@GIO86@_MODCM1:	SUB	AL,((@CLMWID) and 0FFh)  ;[AL]=modulus CLMWID
	JA	@GIO86@_MODCM1
	JZ	@GIO86@_STRDON  ;BRIF at comma column, exclude trailing space
@GIO86@_INCLEN:	INC	word [BX+0]  ;increment the length to include the space
;NOTE:number is less than 255(can do INC)
@GIO86@_STRDON:	POP	BX
	POP	CX
	PUSH	CX  ;refresh [CH]=width, [CL]=last comma column
	PUSH	BX
	MOV	BX,word [@FACLO]  ;BX points to string descriptor
	INC	CH
	JZ	@GIO86@_LINCH2  ;branch if infinite (255) line width
	DEC	CH  ;restore [CH]=device width
	CALL	@PTRGPS  ;[AL]=file's current column pos
	OR	AL,AL  ;don't CR if string longer than line
	JZ	@GIO86@_LINCH2  ;  length if position is 0
	ADD	AL,byte [BX+0]  ;[AL]=column + string size
	CMC  ;set nc if overflow on check
	JAE	@GIO86@_LINCHK  ;start on a new line if overflow
	DEC	AL
	CMP	AL,CH  ;check for overlap
@GIO86@_LINCHK:	JB	@GIO86@_LINCH2  ;branch if still on current line
	CALL	@CRDO  ;else output CR
@GIO86@_LINCH2:	CALL	@STRPRT  ;PRINT THE string/number
	POP	BX  ;restore text pointer
	JMP	@GIO86@_NEWCHR  ;print some more

;PRINT comma (text pointer stacked)

@GIO86@_COMPRT:	CALL	@PTRGPS  ;[AL]=file's current column position
	CMP	CH,((255) and 0FFh)  ;infinite width?
	JZ	@GIO86@_MORCOM  ;do modulus
	CMP	AL,CL  ;compare current with last comma column
@GIO86@_CHKCOM:	JB	@GIO86@_MORCOM  ;branch if not beyond last comma col
	CALL	@CRDO  ;start new line
	JMP	@GIO86@_NOTABR  ;AND QUIT IF BEYOND LAST COMMA FIELD
@GIO86@_MORCOM:	SUB	AL,((@CLMWID) and 0FFh)  ;[AL]=MODULUS CLMWID
	JAE	@GIO86@_MORCOM
	NEG	AL
	DEC	AL  ;fill the print position out
;to an even CLMWID, so
;we print CLMWID-[AL] MOD CLMWID spaces
	JMP	@GIO86@_ASPA2  ;go print [AL]+1 spaces

;PRINT TAB(N) & SPC(N)

@GIO86@_TABER:	PUSH	AX  ;remember IF [A]=SPCTK or TABTK
	CALL	@CHRGTR
	CALL	@ADRGET  ;[DX]=parameter (0..65535)
	POP	AX  ;see if its SPC or TAB
	PUSH	AX
	OR	DX,DX
	JG	@GIO86@_TBNONG  ;branch if greater than 0
	MOV	DX,0  ;map negative parms to 0
	JMP	@GIO86@_SPCNDC
@GIO86@_TBNONG:	CMP	AL,((@SPCTK) and 0FFh)  ;if space leave alone
	JZ	@GIO86@_SPCNDC
	DEC	DX  ;offset TAB by 1
@GIO86@_SPCNDC:	PUSH	BX  ;save the text pointer
	MOV	BL,CH  ;[BL]=file width
	MOV	AL,CH  ;[AL]=file width
	INC	AL  ;test for width of 255 (no folding)
	JZ	@GIO86@_LNOMOD  ;if so, don't mod
	MOV	BH,((0) and 0FFh)  ;MOD out by line length
	CALL	@IMOD  ;[BX]=[DX] MOD filewidth
	XCHG	DX,BX  ;set [DL] = position to go to
@GIO86@_LNOMOD:	POP	BX  ;get back the text pointer
	CALL	@SYNCHR
	DB	")"
	DEC	BX
	POP	AX  ;get back SPCTK or TABTK
	SUB	AL,((@SPCTK) and 0FFh)  ;was it SPCTK?
	PUSH	BX  ;save the text pointer
	JZ	@GIO86@_DOSIZT  ;value in [AL]
	CALL	@PTRGPS  ;[AL]=file position
@GIO86@_DOSIZT:	NEG	AL  ;print [E]-[A] spaces
	DEC	AL
	ADD	AL,DL
	JB	@GIO86@_ASPA2  ;print if past current
	INC	AL
	JZ	@GIO86@_NOTABR  ;do nothing if at current
	CALL	@CRDO  ;go to a new line
	MOV	AL,DL  ;get the position to go to
	DEC	AL
	JS	@GIO86@_NOTABR
@GIO86@_ASPA2:	INC	AL
@GIO86@_ASPAC:	MOV	DL,AL  ;[B]=number of spaces to print
	MOV	AL,((" ") and 0FFh)  ;[A]=space
@GIO86@_REPOUT:	CALL	@OUTDO  ;PRINT [AL]
	DEC	DL  ;decrement the count
	JNZ	@GIO86@_REPOUT
@GIO86@_NOTABR:	POP	BX  ;pick up text pointer
	CALL	@CHRGTR  ;and the next character
	JMP	@GIO86@_PRINTC  ;and since we just printed
;spaces, don't call crdo
;if it's the end of the line

; SUBTTL EOF, LOC, LOF  Functions

; PUBLIC	EOF,LOC,LOF
; EXTRN	CONINT:NEAR

; EOF(n) Function - returns -1 if eof, else 0
; Entry - [FAC] = file number
; Exit  - [FAC] = -1 if EOF, else 0.

@EOF:	CALL	@GIO86@_FACFPT  ;[SI] points to FDB for file [FAC]
	JZ	@GIO86@_ERFNO4  ;error if file not opened
	XOR	BX,BX  ;BX=0 (assume not at eof)
	TEST	byte [@F_FLGS+SI],((@FL_BKC) and 0FFh)
	JNZ	@GIO86@_GFUNX  ;if character backed up, no eof
	DEC	BX  ;[BX]=-1 (EOF true)
	CMP	byte [@F_ORCT+SI],((0) and 0FFh)
	JE	@GIO86@_GFUNX  ;branch if FDB EOF flag set
	MOV	AH,((@G_EOF) and 0FFh)  ;End of file function
	CALL	@GIO86@_SIDSP
	JMP	@GIO86@_GFUNX  ;return result in FAC

@GIO86@_ERFNO4:	JMP	@DERFNO  ;file not open error

; LOC(n) Function
; Entry - [FAC] = file number
; Exit  - [FAC] = current record number

@LOC:	MOV	AH,((@G_LOC) and 0FFh)  ;LOC function
@GIO86@_GENFUN:	CALL	@GIO86@_FACDSP  ;[BX]=EOF(file [FAC])
@GIO86@_GFUNX:	JMP	@MAKINT  ;return result in FAC

; LOF(n) Function
; Entry - [FAC] = file number
; Exit  - [FAC] = length of file in bytes

@LOF:	MOV	AH,((@G_LOF) and 0FFh)  ;LOF Function
	JMP	@GIO86@_FACDSP  ;[FAC]=LOF(file [FAC])

; SUBTTL GET/PUT - Random disk I/O Statements

; PUBLIC	DPUTG

;Syntax - GET fn [,recnum]   (if no recnum next relative record assumed)
;         PUT fn [,recnum]
; Entry - [BX] = text pointer
;         [CX] = 0 for GET, 1 for PUT

@DPUTG:
	PUSH	CX  ;save GET/PUT Flag
	CALL	@GIO86@_POFNUM  ;[AL]=file number
	CALL	@GIO86@_FDBPTR  ;[SI] points to File Data Block of file [AL]
	JZ	@GIO86@_ERFNO3  ;branch if file not open
	CMP	byte [@F_MODE+SI],((@MD_RND) and 0FFh)
	JNE	@GIO86@_ERBFM1  ;Not random - bad file mode
	PUSH	SI  ;save FDB pointer
	DEC	BX
	CALL	@CHRGTR  ;reget next character
	JZ	@GIO86@_RELRND  ;branch if end-of-statement (relative record)
	CALL	@SYNCHR
	DB	44  ;parse required comma
	CALL	@ADRGET  ;[DX]=record number (0..65535)
	POP	SI  ;restore FDB pointer
	POP	AX  ;restore GET/PUT flag
	ADD	AX,2  ;[AX]=2 for GET [DX], 3 for PUT [DX]
	JMP	@GIO86@_RELRN1
@GIO86@_RELRND:	POP	SI  ;restore FDB pointer
	POP	AX
@GIO86@_RELRN1:	PUSH	BX  ;save text pointer
;[AL]=0,1,2,3 for GET PUT GETrel PUTrel
	MOV	AH,((@G_RND) and 0FFh)  ;select Random I/O function code
	CALL	@GIO86@_SIDSP  ;dispatch to routine for FDB SI
	POP	BX  ;restore text pointer
	RET

@GIO86@_ERBFM1:	JMP	@DERBFM

; SUBTTL Misc. Parsing Routines

;POFNUM - Parse optional file number "[#]n"
; Entry - [BX] = text pointer
; Exit  - [BX] = updated text pointer, [AL]=file number
;         All other registers preserved

@GIO86@_POFNUM:	CMP	byte [BX+0],(("#") and 0FFh)  ;[AL]=current character
	JNZ	@GIO86@_GETNZB  ;branch if optional # not included

;PRFNUM - Parse required file number "#n"
; Entry - [BX] = text pointer
; Exit  - [BX] = updated text pointer, [AL]=file number
;         All other registers preserved

@GIO86@_PRFNUM:	CALL	@SYNCHR
	DB	"#"

;GETNZB - Parse byte (1..255) expression, returning result in [AL]
; Entry - [BX] = text pointer
; Exit  - [BX] = updated text pointer, [AL]=byte parsed
;         All other registers preserved

@GIO86@_GETNZB:	PUSH	DX
	PUSH	CX
	CALL	@GETBYT  ;[AL]=file number
	OR	AL,AL
	JZ	@GIO86@_ERBFN1  ;bad file number if 0
	POP	CX
	POP	DX
@GIO86@_RET9:	RET

@GIO86@_ERBFN1:	JMP	@DERBFN  ;bad file number

; PUBLIC	FILINP,FILGET,GETPTR,FILSET,FILSCN
@FILINP:	MOV	CL,((@MD_SQI) and 0FFh)  ;MUST BE SEQUENTIAL INPUT
@FILGET:	CMP	AL,(("#") and 0FFh)  ;NUMBER SIGN THERE?
	JNZ	@GIO86@_RET9  ;NO, NOT FILE INPUT
	PUSH	CX  ;SAVE EXPECTED MODE
	CALL	@FILSCN  ;READ AND GET POINTER
	JZ	@GIO86@_ERFNO3  ;ERROR IF FILE NOT OPEN
	POP	DX  ;[DL]=FILE MODE
	CMP	AL,DL  ;IS IT RIGHT?
	JZ	@GIO86@_GDFILM  ;GOOD FILE MODE
	CMP	AL,((@MD_RND) and 0FFh)  ;ALLOW STUFF WITH RANDOM FILES
	JNZ	@GIO86@_ERBFM3  ;IF NOT, "BAD FILE MODE"
@GIO86@_GDFILM:
	CALL	@SYNCHR
	DB	44  ;GO PAST THE COMMA
@FILSET:	MOV	DX,CX  ;SETUP PTRFIL
	MOV	word [@PTRFIL],CX
	RET

@GIO86@_ERBFM3:	JMP	@DERBFM
@GIO86@_ERFNO3:	JMP	@DERFNO

;FILSCN - parse file number
; Entry - [BX]=text pointer
; Exit  - [DL]=file number, [SI], [CX] point to file data block for file [DL]
;         [AL]=file mode, FLAGS.Z is set if file is not open.
;         note - if file is not open, no FDB exists

@FILSCN:	CALL	@GIO86@_POFNUM  ;[AL]=file number

@GIO86@_FILIDX:	MOV	DL,AL  ;return file number in [DL]
@GIO86@_FILID2:	CALL	@GIO86@_FDBPTR  ;SI points to FDB for file [AL]
	JZ	@GIO86@_NTOPEN  ;branch if file is not open
	MOV	CX,SI  ;CX  points to FDB
	MOV	AL,byte [@F_MODE+SI]  ;[AL]=file mode
	OR	AL,AL  ;set non-zero (file is opened)
@GIO86@_NTOPEN:	RET

;GETPTR IS CALLED FROM VARPTR(#<EXPRESSION>)
; Entry - [AL]=file number
; Exit  - [DX] points to random file buffer, or sector buffer of file

@GETPTR:	CALL	@GIO86@_FDBPTR  ;SI points to File Data Block
	JZ	@GIO86@_ERFNO3  ;error if file not open
	MOV	DX,@F_MODE  ;Return pointer to MODE
	ADD	DX,SI  ;Return result in [DX]
	RET

;DIRDO is called to make sure direct statement is not found when loading file
; If device is keyboard, control transfers to GONE with AX used.

; PUBLIC	DIRDO
@DIRDO:	MOV	AX,word [@PTRFIL]
	OR	AX,AX
	JNZ	@GIO86@_ERFDR  ;if device not keyboard then
;   error(direct statement in file)
; EXTRN	GONE:NEAR
	JMP	@GONE  ;else OK

@GIO86@_ERFDR:	JMP	@DERFDR

;ADRGET - parse 16 bit expression
; Entry - [BX]=text pointer
; Exit  - [DX]=result (0..65535)
;         [BX]=updated text pointer
;         AX used, other registers preserved.

; PUBLIC	ADRGET
@ADRGET:	PUSH	CX
; EXTRN	FRMEVL:NEAR
	CALL	@FRMEVL
	PUSH	BX
; EXTRN	FRQINT:NEAR
	CALL	@FRQINT  ;Make Unsigned 16 bits
	POP	DX
	XCHG	BX,DX  ;Offset in [DX], text pointer in [BX]
	POP	CX
	RET

; SUBTTL Major I/O Routines

;PRGFIL is called to open file #0 (SAVE/LOAD/MERGE etc.)
; Entry - [BX]=text pointer, pointing at filename
;         [DH]=file mode
; Exit  - [PTRFIL] points to files FDB (directing all future I/O to file)
;         [BX]=[TEMP]=updated text pointer
;         SI may be destroyed.

; PUBLIC	PRGFIL
end if
; EXTRN	TEMP:WORD
if @GW_PASS = 1
@PRGFIL:	MOV	byte [@FILMOD],DH  ;save file mode (MD.SQI / MD.SQO)
	CALL	@NAMSCN  ;scan filename
	MOV	word [@TEMP],BX  ;PRGFIN restores text pointer when done
	JB	@GIO86@_PRGFIX  ;Exit - "." found in name
	CALL	@GIO86@_NAMBAS  ;Add ".BAS" extension to disk file names
@GIO86@_PRGFIX:	JMP	@GIO86@_NULOPN  ;open file #0

;NAMBAS is called to add the ".BAS" extension to disk file names
;Entry - FILDEV points to device id
;Exit  - SI destroyed

@GIO86@_NAMBAS:	MOV	SI,@FILDEV  ;SI points to device id
	TEST	byte [SI+0],((255) and 0FFh)
	JS	@GIO86@_NAMBAX  ;Exit if device is not DISK
	ADD	SI,9  ;SI points to Extention
	CMP	byte [SI+0],((" ") and 0FFh)  ;if blank extention, default to ".BAS"
	JNE	@GIO86@_NAMBAX  ;Exit if device is not DISK
	MOV	word [SI+0],(256*"A")+"B"
	MOV	byte [SI+2],(("S") and 0FFh)
@GIO86@_NAMBAX:	RET

;NULOPN opens File 0 with mode [AL].
; Exit  - [PTRFIL] points to files FDB (directing all future I/O to file)

; PUBLIC	NULOPM
@NULOPM:	MOV	byte [@FILMOD],AL  ;FILMOD=file mode
@GIO86@_NULOPN:	XOR	AL,AL  ;[AL]=file number
	XOR	CX,CX  ;random record length = 0
;fall into OPNFIL

;OPNFIL - general file-open routine
; Entry - [AL]=file number (0..n)
;         [CX]=record length (0=default)
;         [FILMOD]=mode (MD.SQI / MD.SQO / MD.RND / MD.APP)
;         [FILDEV]=device id
;         [FILNM]=filename
;         [FILEXT]=1..3 byte filename extension
; Exit  - [PTRFIL] points to files FDB (directing all future I/O to file)
;         all registers preserved

@GIO86@_OPNFIL:	PUSHF
	PUSH	AX
	PUSH	BX
	PUSH	CX
	PUSH	DX
	PUSH	SI
	PUSH	DI
	MOV	BL,AL
	MOV	BH,((0) and 0FFh)  ;[BX]=file number
	CALL	@GIO86@_FDBPTR  ;see if file is already open
	JNZ	@GIO86@_ERFAO1  ;error if already open
	MOV	AL,byte [@FILDEV]  ;[AL]=device id
	CALL	@GIO86@_CDEVID  ;[DI]=device dispatch table offset (AL)
	MOV	AH,((@G_OPN) and 0FFh)  ;open function code (AL is still DEVICE ID)
	CALL	@GIO86@_TBLDSP  ;call device-dependent open routine
	POP	DI
	POP	SI
	POP	DX
	POP	CX
	POP	BX
	POP	AX
	POPF
	RET

@GIO86@_FCERR3:	JMP	@FCERR
@GIO86@_ERFAO1:	JMP	@DERFAO  ;file already opened error

;CLSALL - close all opened files
; Entry - none
; Exit  - All registers preserved

; PUBLIC	CLSALL
@CLSALL:	PUSH	AX
	PUSH	SI
	MOV	SI,word [@FILTAB]  ;Get address of next file block
@GIO86@_CLSAL1:	CMP	SI,word [@STKLOW]
	JZ	@GIO86@_CLSALX  ;Branch if finished
	PUSH	word [@F_NEXT+SI]  ;save pointer to next entry in chain
	MOV	AL,byte [@F_NUM+SI]  ;[AL]=file number
	CALL	@CLSFIL  ;Close file [AL]
	POP	SI  ;SI points to next FDB in chain
	JMP	@GIO86@_CLSAL1  ;Keep looping till all files closed
@GIO86@_CLSALX:	POP	SI
	POP	AX
	RET

;CLSFIL - close file [AL]
; Exit  - Flags, AX, SI used, all other registers are preserved

; PUBLIC	CLSFIL
@CLSFIL:	MOV	AH,byte [@NLONLY]
	TEST	AH,((128) and 0FFh)  ;see if Chain All / Load, R in progress
	JNZ	@GIO86@_RET22  ;branch if Dont-Close-Any-Files flag set
	TEST	AH,((1) and 0FFh)  ;see if Load/Merge/Chain is in progress
	JZ	@GIO86@_CLSFL1  ;branch if Dont-Close-File-0 flag not set
	OR	AL,AL
	JZ	@GIO86@_RET22  ;branch if trying to close file 0
@GIO86@_CLSFL1:	CALL	@GIO86@_FDBPTR  ;[SI] points to FDB [AL]
	JZ	@GIO86@_RET22  ;branch if file already closed
	PUSH	BX
	PUSH	CX
	PUSH	DX
	MOV	word [@FREFDB],SI  ;So FINPRT will force close file if low-level
;close routine gets I/O error
	MOV	AH,((@G_CLS) and 0FFh)
	CALL	@GIO86@_SIDSP  ;close FDB pointed to by [SI]
	MOV	word [@FREFDB],0
	CALL	@GIO86@_FFREE  ;Deallocate FDB and remove from FDB Chain
	POP	DX
	POP	CX
	POP	BX
@GIO86@_RET22:	RET

;INCHR - get next byte from file PTRFIL
; Exit  - [AL]=byte, [FLAGS], [AH] destroyed.
;         All other regs preserved
;         if END-OF-FILE then
;            if program load was in progress, file 0 closed etc.
;            else Read-Past-End error is generated

; PUBLIC	INCHR
; EXTRN	PRGFIN:NEAR,KYBSIN:NEAR
@INCHR:
	PUSH	SI
	CALL	@GIO86@_INCHRE  ;[AL]=next byte from PTRFIL, carry if EOF
	JAE	@GIO86@_INCHRX  ;branch if not EOF
	CMP	byte [@F_NUM+SI],((0) and 0FFh)  ;EOF on ASCII file #0 = end of Load/Chain/Merge
	JE	@GIO86@_FL0EOF  ;branch if EOF reached for file #0
; EXTRN	DERRPE:NEAR
	JMP	@DERRPE  ;Input past end error
@GIO86@_FL0EOF:	CMP	byte [@F_CODE+SI],((@FC_BIN) and 0FFh)
	JNE	@GIO86@_LDREOF  ;branch if not binary file (must be ascii LOAD)
	STC  ;else must be BLOAD/binary LOAD
	RET  ;return EOF indication to caller
@GIO86@_LDREOF:
end if
; EXTRN	CHNFLG:WORD
if @GW_PASS = 1
; EXTRN	CHNRET:NEAR
	CMP	byte [@CHNFLG],((0) and 0FFh)  ;chain in progress?
	JE	@GIO86@_NOTCHN  ;branch if not chaining
	JMP	@CHNRET  ;perform variable block transfer, etc.
; close all files
@GIO86@_NOTCHN:
	PUSH	BX  ;save all registers
	PUSH	CX
	PUSH	DX
	MOV	AL,byte [@NLONLY]  ;get load flags
	AND	AL,((128) and 0FFh)  ;leave others open, null gets closed
	MOV	byte [@NLONLY],AL  ;allow other files to be closed
	CALL	@PRGFIN  ;close the file
	POP	DX
	POP	CX
	POP	BX
	MOV	AL,byte [@RUNFLG]  ;run it or not?
	OR	AL,AL
	JZ	@GIO86@_NORUNC  ;dont run program
; EXTRN	RUNC:NEAR
	CALL	@RUNC  ;run it
; EXTRN	NEWSTT:NEAR
	JMP	@NEWSTT
@GIO86@_NORUNC:	PUSH	BX
	PUSH	CX
	PUSH	DX
; EXTRN	REDDY:NEAR,STROUT:NEAR
	MOV	BX,@REDDY  ;print prompt "ok"
	CALL	@STROUT
	POP	DX
	POP	CX
	POP	BX
	MOV	AL,((13) and 0FFh)
@GIO86@_INCHRX:	POP	SI
	RET

;INCHRE - get next byte from file PTRFIL.
; Exit  - Carry set if EOF, else [AL]=byte.
;         SI points to FDB
;         All other regs preserved

; PUBLIC	INDSKC
@INDSKC:
@GIO86@_INCHRE:	MOV	SI,word [@PTRFIL]  ;SI points to current FDB
;fall into INCHSI

;INCHSI - get next byte from file SI (CTL Z = end-of-file)
; Exit  - Carry set if EOF, else [AL]=byte.
;         All other regs preserved

; PUBLIC	INCHSI
@INCHSI:	INC	SI
	JZ	@GIO86@_ERBFM6  ;branch if Line Printer (can't input)
	DEC	SI
	JNZ	@GIO86@_INGFDB  ;branch if not Keyboard (got FDB)
; EXTRN	INCHRI:NEAR
	JMP	@INCHRI
@GIO86@_INGFDB:	CMP	byte [@F_MODE+SI],((@MD_SQO) and 0FFh)
	JZ	@GIO86@_ERBFM6
	CMP	byte [@F_ORCT+SI],((0) and 0FFh)
	JZ	@GIO86@_INCEOF  ;branch if EOF already reached
	TEST	byte [@F_FLGS+SI],((@FL_BKC) and 0FFh)
	JNZ	@GIO86@_GETBKC  ;branch if char backed up
	MOV	AH,((@G_SIN) and 0FFh)
	CALL	@GIO86@_SIDSP  ;[AL]=next input from file
	JB	@GIO86@_INCEOF  ;branch if device detected EOF
	RET

@GIO86@_INCEOF:	MOV	byte [@F_ORCT+SI],((0) and 0FFh)  ;indicates EOF on future calls
	MOV	byte [@F_BREM+SI],((0) and 0FFh)
	STC  ;tells caller EOF reached
	RET

@GIO86@_GETBKC:	AND	byte [@F_FLGS+SI],((255-@FL_BKC) and 0FFh)  ;clear Backup Present flag
	MOV	AL,byte [@F_BAKC+SI]  ;return Backed-up character
	RET  ;with no carry (no-eof)

@GIO86@_ERBFM6:	JMP	@DERBFM  ;bad file mode error

; PUBLIC	CRFIN,CRDONZ,FININL,CRDO
@CRFIN:	XOR	AL,AL  ;all references should be eliminated
	RET

;CRDONZ - output carriage return if file PTRFIL is not at left margin

@CRDONZ:	CALL	@PTRGPS  ;[AH]=0-relative column for PTRFIL
	OR	AH,AH
	JNZ	@CRDO  ;if not at column 0, output CRLF
	RET

end if
; EXTRN	BUFMIN:WORD
if @GW_PASS = 1
@FININL:	MOV	byte [BX+0],((0) and 0FFh)
	MOV	BX,@BUFMIN

;CRDO - output ascii carriage return to current file

@CRDO:	MOV	AL,((@ASCCR) and 0FFh)
	CALL	@OUTDO  ;output Carriage Return
	MOV	AL,((@ASCLF) and 0FFh)  ;output Line Feed
	CALL	@OUTDO
	XOR	AL,AL  ;must return with [AL]=0 and FLAGS.Z true
	RET

;OUTDO - output [AL] to current file (force CR if end-of-line)
; Exit - All registers preserved (including FLAGS)

; PUBLIC	OUTDO,FILOU3
@FILOU3:
@OUTDO:
	PUSHF
	PUSH	AX
	MOV	AH,((@G_SOT) and 0FFh)
	CALL	@PTRDSP  ;dispatch to function [DL] for PTRFIL
	POP	AX
	POPF
	RET

;OUT16 - output data [AX] to current file

@GIO86@_OUT16:	PUSH	AX
	CALL	@OUTDO  ;output low-byte first
	XCHG	AH,AL
	CALL	@OUTDO  ;then output high-byte
	POP	AX
	RET

;INP16 reads the next 16 bits from file PTRFIL
; Exit  - [AX]=result. Carry set if EOF.
;         All other registers are preserved.

@GIO86@_INP16:	PUSH	BX
	CALL	@INCHR  ;get low-byte first
	MOV	BL,AL
	CALL	@INCHR  ;then get high-byte
	MOV	BH,AL
	MOV	AX,BX
@GIO86@_INP16X:	POP	BX
	RET

;BAKCHR - backup sequential input file
; Entry - [AL] = char to be backed up
;         [PTRFIL] points to FDB of file to be backed up

; PUBLIC	BAKCHR,BCHRSI
@BAKCHR:	PUSH	SI
	MOV	SI,word [@PTRFIL]
	CALL	@BCHRSI
	POP	SI
	RET

;BCHRSI - backup sequential input file
; Entry - [AL] = char to be backed up
;         [SI] points to FDB of file to be backed up

@BCHRSI:	MOV	byte [@F_BAKC+SI],AL
	OR	byte [@F_FLGS+SI],((@FL_BKC) and 0FFh)  ;set flag indicating char backed up
	RET

;BINSAV - Binary SAVE support.

; PUBLIC	BINSAV,BINPSV
end if
; EXTRN	TXTTAB:WORD
if @GW_PASS = 1
; EXTRN	PROCHK:NEAR,SCCPTR:NEAR
@BINSAV:	CALL	@SCCPTR  ;GET RID OF POINTERS BEFORE SAVING
	CALL	@PROCHK  ;DONT ALLOW BINARY SAVES OF PROTECTED PROGRAMS
	CALL	@SCDBIN  ;Set attribute CODE to BINARY (not ASCII)
	MOV	AL,((255) and 0FFh)  ;ALWAYS START WITH 255
@BINPSV:	CALL	@FILOU3  ;SEND TO FILE
	MOV	CX,word [@VARTAB]  ;GET STOP POINT
	MOV	BX,word [@TXTTAB]  ;GET START POINT
	SUB	CX,BX  ;Calculate bytes to SAVE
	JBE	@GIO86@_BINSVX  ;Nothing to SAVE
	MOV	DX,DS  ;Get Segment for SAVE
	CALL	@GIO86@_OUTBLK  ;Write the block
@GIO86@_BINSVX:	JMP	@PRGFIN  ;REGET TEXT POINTER AND CLOSE FILE 0

;DEVBIN - General device block input routine.  This routine is called by
;         device code for devices which have no block I/O capability.
; Entry - [BX] = Start adr
;         [CX] = number of bytes to read
;         [DX] = Segment adr
;         [SI] = address of FDB
;         [DI] = device offset (2=COMD, 4=SCRN, etc.)
; Exit  - [BX] = End+1
;         Carry set if reached end of data before CX bytes read
;         SI, CX, AX used.

; PUBLIC	DEVBIN
@DEVBIN:	OR	CX,CX
	JZ	@GIO86@_RET27  ;Until end.
	MOV	AH,((@G_SIN) and 0FFh)  ;sequential input function
	CALL	@PTRDSP  ;[AL]=next byte from file PTRFIL
	JB	@GIO86@_RET27  ;branch if tried to read past end-of-file
	PUSH	DS
	PUSH	DX
	POP	DS  ;[DS]=[DX]
	MOV	byte [BX+0],AL  ;Store Byte
	POP	DS
	INC	BX  ;bump destination pointer
	DEC	CX  ;decrement byte count
	JMP	@DEVBIN

;DEVBOT - General device block output routine.  This routine is called by
;         device code for devices which have no block I/O capability.
; Entry - [BX] = Start adr
;         [CX] = number of bytes to write
;         [DX] = segment adr
;         [SI] = address of FDB
;         [DI] = device offset (2=COMD, 4=SCRN, etc.)
; Exit  - [BX] = End + 1

; PUBLIC	DEVBOT
@DEVBOT:	OR	CX,CX
	JZ	@GIO86@_RET27  ;Until Len=0.
	PUSH	DS  ;save BASIC's Data Segment
	PUSH	DX
	POP	DS  ;DS=DX
	MOV	AL,byte [BX+0]
	POP	DS  ;restore BASIC's Data Segment
	CALL	@OUTDO  ;Write Byte from Memory.
	INC	BX
	DEC	CX
	JMP	@DEVBOT
@GIO86@_RET27:	RET

;OUTBLK - Write Block of memory to current file
; Entry - [BX] = Start adr
;         [CX] = number of bytes to write
;         [DX] = segment adr
; Exit  - [BX] = End + 1

@GIO86@_OUTBLK:	MOV	SI,word [@PTRFIL]
	MOV	AH,((@G_BOT) and 0FFh)  ;Block output function
	CALL	@PTRDSP
	RET

; INPBLK - Read block of memory from current file
; Entry - [BX] = Start adr
;         [CX] = number of bytes to read
;         [DX] = Segment adr
; Exit  - [BX] = End+1
;         Carry set if reached end of data before CX bytes read
;         SI, CX, AX used.

; EXTRN	DFSTLD:NEAR
@GIO86@_INPBLK:	MOV	SI,word [@PTRFIL]
	MOV	AH,((@G_BIN) and 0FFh)  ;block input function
	CALL	@PTRDSP  ;[AL]=next byte from file PTRFIL
	RET

;FSTLOD - load Binary BASIC program (Called from DSKCOM after LOAD statement)
; Entry - BX points to destination of program
;         [FRETOP] - [BX] - ^D86 = maximum legal size of program
;         [PTRFIL] points to FDB of file to be loaded
;         (note: 1st byte of file has already been read and was ^D254)

; PUBLIC	FSTLOD
; EXTRN	OUTLOD:NEAR
@FSTLOD:
	MOV	CX,word [@FRETOP]  ;Bottom of string space
	SUB	CX,86  ;leave a little breathing room
	SUB	CX,BX  ;[CX]=maximum legal size of program
	CALL	@SCDBIN  ;set CODE attribute to Binary
	PUSH	DS
	POP	DX  ;[DX]=segment to be used
	CALL	@GIO86@_INPBLK  ;read block from device to disk
	JB	@GIO86@_RET27  ;branch if file fits in memory
	JMP	@OUTLOD  ;ERROR AND WIPE OUT PARTIAL GARBAGE

;PTRGPS - get column position for file PTRFIL

; Exit  - [AH] = [AL] = column position
;         FLAGS.Z is true if at column 0
;         All other registers are preserved

; PUBLIC	PTRGPS
@PTRGPS:	MOV	AH,((@G_GPS) and 0FFh)  ;Get column position request-code
	CALL	@PTRDSP  ;[AH]=position
	MOV	AL,AH  ;[AL]=position
	OR	AL,AL
	RET

;PTRWDC - get line width and last comma column for file PTRFIL
; Exit  - [CH] = line width
;         [AH] = [CL] = last comma column
;         All other registers are preserved

@GIO86@_PTRWDC:	CALL	@PTRWID  ;[AH]=file PTRFIL's line width
	MOV	CH,AH  ;[CH]=file width
@GIO86@_PTRWDL:	SUB	AH,((14) and 0FFh)  ;T.B.S. eventually, use G.GCW
	JAE	@GIO86@_PTRWDL
	ADD	AH,((28) and 0FFh)
	NEG	AH
	ADD	AH,CH
	MOV	CL,AH  ;[CL]=last comma column
	RET

;PTRWID - get line width for file PTRFIL
; Exit  - [AH] = line width
;         All other registers are preserved

; PUBLIC	PTRWID
@PTRWID:	PUSH	SI  ;save caller's SI
	MOV	SI,word [@PTRFIL]
	INC	SI
	JZ	@GIO86@_PTRWD1  ;if LPT Pseudo FDB, use Device width
	DEC	SI
	JZ	@GIO86@_PTRWD1  ;if KYBD Pseudo FDB, use Device width
	MOV	AH,byte [@F_WID+SI]  ;else use FDB width
	POP	SI  ;restore caller's SI
	RET
@GIO86@_PTRWD1:	POP	SI  ;restore caller's SI
	MOV	AH,((@G_GWD) and 0FFh)  ;Get file width function code
	JMP	@PTRDSP  ;return with [AH]=device width

; SUBTTL General routines useful to low-level device drivers

; PUBLIC	XTABCR,EXPTAB,CRIFEL,UPDPOS
;XTABCR is called by Device Driver Output routines to Expand Tabs to Spaces
;         and Force a carriage return if end-of-line.
; Entry - [AL]=char to be output
;         [DH]=current column position
;         [DL]=line width
;         BX points to raw-output routine
; Exit  - [DH] is new column position
;         FLAGS are used, All other registers are preserved.

@XTABCR:	PUSH	CX
	MOV	CX,@CRIFEL  ;EXPTAB will call CRIFEL which will
	CALL	@EXPTAB  ;call raw-output routine [BX]
	POP	CX
	RET

;EXPTAB is called by Device Driver Output routines to Expand Tabs to Spaces
; Entry - [AL]=char to be output
;         [DH]=current column position
;         CX points to raw-output routine
; Exit  - [DH] is new column position
;         FLAGS are used, All other registers are preserved.

@EXPTAB:
	CMP	AL,((@ASCTAB) and 0FFh)
	JNE	@GIO86@_NOTTAB  ;branch if not tab
	CMP	DL,((9) and 0FFh)
	JB	@GIO86@_EXTABX  ;branch if width is less than 9
	MOV	AL,((@ASCSPC) and 0FFh)  ;output spaces till next tab stop
@GIO86@_EXTABL:	CALL	CX  ;output space (update position)
	TEST	DH,((7) and 0FFh)
	JNZ	@GIO86@_EXTABL  ;branch if not at MOD 8 column position
	MOV	AL,((@ASCTAB) and 0FFh)  ;restore AL
@GIO86@_EXTABX:	RET

@GIO86@_NOTTAB:	JMP	CX  ;output char and update position

;CRIFEL - Force a carriage return if end-of-line (Called by device out routines)
; Entry - [AL]=char to be output
;         [DH]=current column position
;         [DL]=line width
;         BX points to raw-output routine
; Exit  - [DH] is new column position
;         FLAGS are used, All other registers are preserved.

@CRIFEL:	CMP	AL,((32) and 0FFh)
	JB	@GIO86@_NOCR  ;branch if non-printable
	CMP	DL,((255) and 0FFh)
	JZ	@GIO86@_NOCR  ;branch if infinite width (255)
	CMP	DH,DL  ;compare Column with Width
	JB	@GIO86@_NOCR  ;branch if still room on current line
	PUSH	AX
	MOV	AL,((@ASCCR) and 0FFh)
	CALL	BX  ;output Carriage Return
	MOV	AL,((@ASCLF) and 0FFh)  ;output Line Feed
	CALL	BX
	POP	AX  ;restore char to be output
@GIO86@_NOCR:	JMP	BX  ;output char, update position

;UPDPOS - update column position (called by device out routines)
; Entry - [DH] = current 0-relative column position
;         [AL] = byte to be output
; Exit  - [DH] = new column position.  All other registers preserved

@UPDPOS:	CMP	AL,((32) and 0FFh)
	JB	@GIO86@_NPRINT  ;branch if not printable (CTL CHR)
	INC	DH  ;bump column position
	RET
@GIO86@_NPRINT:	CMP	AL,((@ASCCR) and 0FFh)
	JNE	@GIO86@_NOTCR  ;branch if not carriage return
@GIO86@_ZERPOS:	MOV	DH,((0) and 0FFh)  ;reset to left margin
	RET
@GIO86@_NOTCR:	CMP	AL,((@ASCBS) and 0FFh)
	JNE	@GIO86@_UPPOSX  ;branch if not backspace
	OR	DH,DH
	JE	@GIO86@_UPPOSX  ;don't decrement below 0
	DEC	DH  ;decrement position
@GIO86@_UPPOSX:	RET

; SUBTTL File Dispatch Routines

end if
; EXTRN	IOJUMP:WORD
if @GW_PASS = 1

@GIO86@_ERBFN2:	JMP	@DERBFN  ;bad file number error

;FACDSP - Dispatch to I/O routine for file number [FAC]
; Entry - [AH]=function code (G.OPN, G.CLS, etc.)
;         [FAC]=file number (note: file must be opened) (0 is illegal)
; Exit  - DX, AL are used.
;         All other registers preserved except those changed by device driver

@GIO86@_FACDSP:	CALL	@CONINT  ;[DX]=integer equivalent of FAC (file#)
	OR	DX,DX
	JZ	@GIO86@_ERBFN2  ;file #0 is unavailable to user (bad file num.)

;FILDSP - Dispatch to I/O routine for file number [DH]
; Entry - [AH]=function code (G.OPN, G.CLS, etc.)
;         [DX]=file number (note: file must be opened)
; Exit  - All registers preserved except those changed by device driver

@GIO86@_FILDSP:	PUSH	SI
	PUSH	AX
	OR	DH,DH
	JNZ	@GIO86@_FCERR9  ;error if file# greater than 255
	MOV	AL,DL  ;[AL]=file number
	CALL	@GIO86@_FDBPTR  ;(SI) = file data block pointer
	JZ	@GIO86@_ERFNO2  ;Error - bad file number
	POP	AX  ;restore caller's [AX]
	CALL	@GIO86@_SIDSP
	POP	SI
	RET

@GIO86@_FCERR9:	JMP	@FCERR  ;Function Call Error

;PTRDSP - Dispatch to I/O routine for file with FDB=[PTRFIL]
; Entry - [AH]=function code (G.OPN, G.CLS, etc.)
;         [PTRFIL]=points to file's FDB
; Exit  - All registers preserved except those changed by device driver

; PUBLIC	PTRDSP
@PTRDSP:	PUSH	SI
	MOV	SI,word [@PTRFIL]
	CALL	@GIO86@_SIDSP
	POP	SI
	RET

;SIDSP - Dispatch to I/O routine for file with FDB=[SI]
; Entry - [AH]=function code (G.OPN, G.CLS, etc.)
;         [SI]=points to file's FDB
; Exit  - All registers preserved except those changed by device driver

@GIO86@_SIDSP:	PUSH	DI
	PUSH	SI
	PUSH	AX
	PUSHF
	INC	SI
	JZ	@GIO86@_LPDSP  ;branch if Line Printer Pseudo FDB
	DEC	SI
	JNZ	@GIO86@_SIDSP1  ;branch if not Keyboard/CRT Pseudo FDB
;        MOVI    DI,$CODE+2*<^O400-$.KYBD>
	MOV	DI,@@S_KYBD
	NEG	DI  ; Change neg. dev. # to 0 based offset
	AND	DI,255
	SHL	DI,1  ; ASM86 cann't multiply externals by 2
	JMP	@GIO86@_SIDSP2
@GIO86@_LPDSP:
;        MOVI    DI,$CODE+2*<^O400-$.LPT1>   ;SI=0
	MOV	DI,@@S_LPT1
	NEG	DI  ; Change neg. dev. # to 0 based offset
	AND	DI,255
	SHL	DI,1  ; ASM86 cann't multiply externals by 2
	JMP	@GIO86@_SIDSP2
@GIO86@_SIDSP1:	MOV	AL,byte [@F_DEV+SI]  ;(AL) = device number
	CALL	@GIO86@_CDEVID  ;[DI]=device dispatch table offset
@GIO86@_SIDSP2:	POPF
	POP	AX  ;restore caller's [AX]
	CALL	@GIO86@_TBLDSP  ;function [AH] on device [DI]
	POP	SI
	POP	DI
	RET

;TBLDSP - Dispatch to I/O routine for device-table [DI]
; Entry - [AH]=function code (G.OPN, G.CLS, etc.)
;         DI = -2 * device id (0=disk, 2=keyboard etc.)
; Exit  - All registers preserved except those changed by device driver

@GIO86@_TBLDSP:	PUSH	DI
	PUSHF
	PUSH	AX
	MOV	AX,word [@DEVPTR]  ;AX points to 1st entry in dispatch table
	ADD	DI,AX  ;DI points to dispatch table pointer for device
	MOV	DI,word [cs:DI+0]  ;DI points to dispatch table for device
	OR	DI,DI  ;If entry is 0, then
	JZ	@GIO86@_ERDNA2  ;  Error - device not available
	POP	AX  ;restore function code
	PUSH	AX
	XCHG	AH,AL
	CBW  ;[AX]=function code
	ADD	DI,AX  ;Add function code offset to dispatch
	MOV	AX,word [cs:DI+0]  ;Get address of routine
	MOV	word [@IOJUMP],AX
	POP	AX
	POPF
	POP	DI
	JMP	 word [@IOJUMP]  ;jump to routine at address [IOJUMP]

;CDEVID - convert device id to dispatch table address
; Entry - [AL]=device id (0..n for disk, -1..-n for non-disk devices)
; Exit  - [DI]=DEVPTR offset for device (0 for disk, 2 for KYBD, etc.)
;         FLAGS.Z is true if device=disk
;         All other registers are preserved.

@GIO86@_CDEVID:	PUSH	AX
	OR	AL,AL
	JS	@GIO86@_CDEV1  ;must be a special device
	XOR	AL,AL  ;(AL) = 0 for disks
	JMP	@GIO86@_CDEV2
@GIO86@_CDEV1:	NEG	AL  ;(AL) = - device number for special
@GIO86@_CDEV2:	PUSHF  ;save Z=disk
	CBW  ;[AX]=device number
	ADD	AX,AX  ; * 2
	MOV	DI,AX
	POPF  ;restore Z=disk
	POP	AX
	RET

@GIO86@_ERFNO2:	JMP	@DERFNO  ;file not opened error

@GIO86@_ERDNA2:	JMP	@DERDNA  ;device not available error

; SUBTTL NAMSCN, PARDEV - Device/Filename scanning routines

; EXTRN	FOPTSZ:NEAR
end if
; EXTRN	FILOPT:WORD
if @GW_PASS = 1

;T.B.S. - FOPTSZ should eventually be used instead of CMPI CX,^D64, but
; the DEC-Macros don't permit this.

;NAMSCN - parse file-specification [dev:]filename[.extension]
; Entry - [BX] = text pointer
; Exit  - [FILDEV] = 0 if default device,
;                    (1..n) if device=(A:, B:, ...)
;                    (-1..-n) for DEVTBL entry (1..n)
;         [FILNM] = filename
;         [FILEXT] = extention
;         [BX] = updated text pointer
;         [AL]=next character
;         FLAGS.CARRY is set if "." scanned
;         DX is used.
;         All other registers preserved

; PUBLIC	NAMSCN
@NAMSCN:	CALL	@FRMEVL

@GIO86@_NAMSC1:	PUSH	BX  ;save text pointer
	CALL	@FRESTR  ;release string descriptor
;[BX] points to string descriptor
	MOV	CL,byte [BX+0]
	MOV	CH,((0) and 0FFh)  ;[CX]=length of string
	MOV	SI,word [BX+1]  ;SI points to start of string
	CALL	@GIO86@_PARDEV  ;(AL) = device #
	MOV	byte [@FILDEV],AL  ;Save device #
	OR	AL,AL
	JS	@GIO86@_NOTDSK  ;branch if special device
	XOR	AL,AL  ;(AL) = 0 for disks
@GIO86@_NOTDSK:	PUSH	AX
	PUSH	DX
	PUSH	DI
	OR	AL,AL
	PUSHF  ;save NC - indicates "." not scanned
	MOV	DI,@FILNM
	MOV	DX,@FNAML  ;filename length
	JNS	@GIO86@_SCAN1  ;If disk device, put name in FILNM

; This code copies Device Dependent Options to FILOPT which is a
; buffer scanned by device drivers at device open time.

	MOV	DI,@FILOPT
	JCXZ	@GIO86@_SCOM1  ;Will copy 1 to
	CMP	CX,64  ;compare with option buffer size
	JAE	@GIO86@_ERIFN1  ;"Bad File Name" if too long
	CLD  ;set Post-Increment mode
;Copy string to FILNM
 REP	MOVSB
@GIO86@_SCOM1:
	MOV	byte [DI+0],CL  ;Terminate option string with 0
	JMP	@GIO86@_SCNAM3

@GIO86@_SCAN1:	JCXZ	@GIO86@_FILSPC  ;End of string
	DEC	CX
	CLD  ;set Post-Increment mode
	LODSB  ;Get filename character
	CMP	AL,(("*") and 0FFh)  ;filename can't have wildcard chars
	JE	@GIO86@_ERIFN1
	CMP	AL,(("?") and 0FFh)
	JE	@GIO86@_ERIFN1
	CMP	AL,((" ") and 0FFh)
	JAE	@GIO86@_SCNAM2

@GIO86@_ERIFN1:	JMP	@DERIFN  ;Illegal file name error

@GIO86@_SCNAM2:	CMP	AL,((".") and 0FFh)
	JE	@GIO86@_FILLNM
	CLD  ;set Post-Increment mode
	STOSB  ;Store character
	DEC	DX
	JNZ	@GIO86@_SCAN1  ;Keep looking for characters

@GIO86@_SCNAM3:	POPF
	POP	DI
	POP	DX
	POP	AX
	POP	BX  ;restore updated text pointer
	RET

@GIO86@_FILLNM:	POPF
	STC  ;set carry indicating "." scanned
	PUSHF
@GIO86@_FILNM0:	CMP	DX,@FNAML  ;file name length
	JE	@GIO86@_ERIFN1  ;Error - extension only !
	CMP	DX,3
	JB	@GIO86@_ERIFN1  ;Error - 2nd dot
	JE	@GIO86@_SCAN1  ;Scan extension like filename
	MOV	AL,((" ") and 0FFh)
	CLD  ;set Post-Increment mode
	STOSB  ;Fill with blank
	DEC	DX
	JMP	@GIO86@_FILNM0  ;Keep filling

@GIO86@_FILSPC:	MOV	AL,((" ") and 0FFh)  ;Fill short name with spaces
	CLD  ;set Post-Increment mode
	STOSB
	DEC	DX
	JNZ	@GIO86@_FILSPC  ;Keep filling
	JMP	@GIO86@_SCNAM3  ;Done with name

;PARDEV - Parse device name from string
; Entry - (CX) = length of string
;         (SI) = string address
; EXIT  - (AL) = device # (0 = default , - = special)
;         (CX) = remaining count
;         (SI) = address of remaining string

@GIO86@_PARDEV:
	PUSH	DX
	PUSH	DI
	PUSH	SI
	MOV	DX,CX  ;(DX) = original length
	OR	DX,DX  ;test for zero length
	JZ	@GIO86@_NODVNM  ;If length = 0 , no device name
@GIO86@_DEVSCN:	CLD  ;set Post-Increment mode
	LODSB  ;Get character
	CMP	AL,((":") and 0FFh)
	JE	@GIO86@_DEVNM  ;Found possible name
	LOOP	@GIO86@_DEVSCN

@GIO86@_NODVNM:	MOV	CX,DX  ;No device name - restore everything
	POP	SI
	POP	DI
	POP	DX
	XOR	AL,AL  ;Default device to 0
	RET

@GIO86@_DEVNM:	POP	DI  ;Restore old string pointer
	XCHG	SI,DI
	PUSH	DI  ;Save new string pointer
	SUB	DX,CX  ;(DX) = device name length
	JZ	@GIO86@_ERIFN2  ;Length = 0 - illegal file name
	DEC	CX  ;Count off :
	CMP	DX,1
	JE	@GIO86@_DSKNAM  ;Length = 1 - must be disk name

	MOV	DI,word [@DEVTBL]
	DEC	DI
@GIO86@_DEVSRC:	PUSH	SI
	PUSH	DX

@GIO86@_DEVLOP:	INC	DI
	CLD  ;set Post-Increment mode
	LODSB
	CALL	@GIO86@_UPCASE  ;Convert to upper case
	TEST	byte [cs:DI+0],((128) and 0FFh)  ;Check to see if at device (long name)
	JNZ	@GIO86@_NMTCH2
	CMP	byte [cs:DI+0],AL
	JNE	@GIO86@_NOMTCH
	DEC	DX
	JNZ	@GIO86@_DEVLOP

@GIO86@_FNDDEV:	INC	DI
	MOV	AL,byte [cs:DI+0]  ;Get device #
	OR	AL,AL
	JNS	@GIO86@_NOMTCH  ;Not a device #

	POP	SI
	POP	SI
@GIO86@_DEVRET:	POP	SI  ;(SI) = pointer after :
	POP	DI
	POP	DX
	RET  ;(CX) = chars left , (AL) = device #

@GIO86@_NMTCH1:	INC	DI
@GIO86@_NOMTCH:
	TEST	byte [cs:DI+0],((128) and 0FFh)  ;Check for device #
	JZ	@GIO86@_NMTCH1  ;  No
@GIO86@_NMTCH2:	POP	DX
	POP	SI
	CMP	byte [cs:DI+1],((0) and 0FFh)  ;End of table?
	JNE	@GIO86@_DEVSRC  ;  No - check next entry

@GIO86@_ERIFN2:	JMP	@DERIFN  ;Error - bad filename (device name)

@GIO86@_DSKNAM:
	CLD  ;set Post-Increment mode
	LODSB  ;Refetch character
	CALL	@GIO86@_UPCASE
	SUB	AL,(("A"-1) and 0FFh)  ;Convert letter to 1-26 (let @ be 0)
	JB	@GIO86@_ERIFN2  ;  Less than @
	CMP	AL,(("Z" AND 31) and 0FFh)
	JAE	@GIO86@_ERIFN2  ;  Greater than Z
	JMP	@GIO86@_DEVRET

@GIO86@_UPCASE:	CMP	AL,(("a") and 0FFh)  ;Convert (AL) to upper case
	JB	@GIO86@_UPRET
	CMP	AL,(("z") and 0FFh)
	JA	@GIO86@_UPRET
	AND	AL,((255-" ") and 0FFh)
@GIO86@_UPRET:	RET

; SUBTTL File Data Block Management Routines

end if
; EXTRN	VARTAB:WORD,ARYTAB:WORD,MEMSIZ:WORD,FRETOP:WORD,SAVFRE:WORD
; EXTRN	FILTAB:WORD,STREND:WORD
if @GW_PASS = 1
; EXTRN	ERROM:NEAR,ERROR:NEAR
; EXTRN	SKPNAM:NEAR,GARBA2:NEAR
;INIFDB - Special device open common routine
; Allocates, initializes and links new FDB into FDB Chain.
; Entry - (AL) = file device
;         (AH) = valid file modes
;         (CX) = buffer size (not including basic FDB size)
;         (DL) = file width
;         (DH) = initial file position
;         (BX) = file number
; Exit -  SI points to new File Data Block
;         [PTRFIL] points to new FDB
;         All other registers preserved.

; PUBLIC	INIFDB
@INIFDB:	PUSH	CX
	PUSH	DI
	TEST	byte [@FILMOD],AH  ;Check for valid file mode
	JZ	@GIO86@_ERBFM4  ;  Bad file mode
	ADD	CX,@FDBSIZ  ;(CX) = size of block to allocate
	CALL	@GIO86@_FALLOC  ;SI points to Allocated block
	MOV	word [@PTRFIL],SI
	MOV	byte [@F_NUM+SI],BL  ;Set file number
	MOV	byte [@F_DEV+SI],AL  ;Set file device
	MOV	byte [@F_FLGS+SI],((0) and 0FFh)
	MOV	byte [@F_CODE+SI],((@FC_ASC) and 0FFh)  ;default file-code to ASCII
	MOV	CL,byte [@FILMOD]
	MOV	byte [@F_MODE+SI],CL  ;Set file mode
	MOV	byte [@F_WID+SI],DL  ;Set file width
	MOV	byte [@F_POS+SI],DH  ;Set file position
	MOV	byte [@F_ORCT+SI],((1) and 0FFh)  ;indicates not at EOF
	POP	DI
	POP	CX
	RET

@GIO86@_ERBFM4:	JMP	@DERBFM  ;Bad file mode

;SCDASC - Set file-attribute CODE for file PTRFIL to ASCII
; Exit  - all registers preserved.

; PUBLIC	SCDASC
@SCDASC:	PUSH	SI
	MOV	SI,word [@PTRFIL]
	MOV	byte [@F_CODE+SI],((@FC_ASC) and 0FFh)
	POP	SI
	RET

;SCDBIN - Set file-attribute CODE for file PTRFIL to binary
; Exit  - all registers preserved.

; PUBLIC	SCDBIN
@SCDBIN:	PUSH	SI
	MOV	SI,word [@PTRFIL]
	MOV	byte [@F_CODE+SI],((@FC_BIN) and 0FFh)
	POP	SI
	RET

;FDBPTR - Transform file number into File-Data-Block pointer
; Entry - [FAC] = file number (0..n)
; Exit  - if File-Data-Block is allocated,
;            SI points to 1st byte of File-Data-Block
;         else FLAGS.Z is true
;         DX, AX are used

@GIO86@_FACFPT:	CALL	@CONINT  ;[AL] = file number
;fall into FDBPTR

;FDBPTR - Transform file number into File-Data-Block pointer
; Entry - [AL] = file number (0..n)
; Exit  - if File-Data-Block is allocated,
;            SI points to 1st byte of File-Data-Block
;         else FLAGS.Z is true
;         All other registers are preserved

@GIO86@_FDBPTR:	MOV	SI,word [@FILTAB]  ;[SI] points to 1st file-data-block
@GIO86@_GPTRL:	CMP	SI,word [@STKLOW]  ;compare with nil FDB pointer
	JZ	@GIO86@_GPTRX  ;branch if at end of FDB chain
	CMP	AL,byte [@F_NUM+SI]
	JZ	@GIO86@_GPTRF  ;branch if found FDB
	MOV	SI,word [@F_NEXT+SI]  ;advance to next FDB in chain
	JMP	@GIO86@_GPTRL
@GIO86@_GPTRF:	OR	SI,SI  ;set NZ - indicates FDB found
@GIO86@_GPTRX:	RET

;FALLOC(nbytes) {allocate file-data-block and link into chain}
; Entry - CX=size of FDB
; Exit  - SI points to new FDB (which is already linked into FDB chain)
;         SI, DI used.

;  if FRETOP-STREND .LEQ. nbytes then
;    perform major string garbage collection
;    if FRETOP-STREND is still .LEQ. nbytes then deverr(Out-of-memory)
;  temp = FILTAB;
;  xfrstr(FILTAB,-nbytes); {move string space down nbytes}
;  FILTAB.F.NEXT := temp; {link new FDB into chain}
;  return FILTAB;

@GIO86@_FALLOC:	PUSH	AX
	PUSH	BX
	PUSH	CX
	PUSH	DX
	PUSHF
	MOV	AX,CX  ;[AX]=size of new FDB
	MOV	DL,((1) and 0FFh)  ;Indicates 1st attempt to find space
@GIO86@_FALC1:	MOV	BX,word [@FRETOP]  ;BX points to top of free string space
	SUB	BX,word [@STREND]  ;BX=number of bytes free - 1
	CMP	AX,BX  ;compare with requested amount
	JB	@GIO86@_FALCOK  ;branch if its available
	DEC	DL
	JZ	@GIO86@_FAPAS1  ;branch if 1st attempt
	MOV	DL,((@ERROM) and 0FFh)  ;else give Out of Memory error
	JMP	@ERROR
@GIO86@_FAPAS1:	PUSH	AX
	PUSH	DX
	CALL	@GARBA2  ;perform major garbage collection
	POP	DX
	POP	AX
	JMP	@GIO86@_FALC1  ;now that its compressed, try again

@GIO86@_FALCOK:	NEG	AX  ;indicates moving strings down
	MOV	SI,word [@FILTAB]  ;SI points to lowest FDB in chain
	PUSH	SI  ;save for link
	CALL	@GIO86@_XFRSTR  ;move string space
	POP	BX
	MOV	SI,word [@FILTAB]  ;SI points to new FDB
	MOV	word [@F_NEXT+SI],BX  ;link FDB into chain

; PUBLIC	PDCBAX,PCBAX,PBAX
@GIO86@_PFDCBA:	POPF
@PDCBAX:	POP	DX
@PCBAX:	POP	CX
@PBAX:	POP	BX
	POP	AX
	RET

;FFREE(fdbptr) {free file data block}
;              {ffree is called by clsfil only}
; Entry - SI points to FDB to be freed
; Exit  - SI, DI Used

;  fdbptr points to low byte of freed file-data-block
;  remove fdbptr from chain of file-data-blocks (FILTAB)
;  nbytes := size of freed file-data-block.
;  xfrstr(fdbptr, nbytes); {move string space and lower-FDB's up nbytes}

@GIO86@_FFREE:	PUSH	AX
	PUSH	BX
	PUSH	CX
	PUSH	DX
	PUSHF
	MOV	AX,word [@F_NEXT+SI]  ;AX points to next FDB in chain
	SUB	AX,SI  ;AX = size of FDB being freed
	MOV	BX,word [@FILTAB]  ;BX points to 1st FDB in chain
@GIO86@_FFNDL:	CMP	BX,SI  ;see if this is the one being freed
	JE	@GIO86@_FFOUND  ;branch if it is
	JB	@GIO86@_STILOK  ;branch if still less than expected
@GIO86@_BADFDB:	JMP	@GIO86@_BADFDB  ;better to halt than destroy other data
@GIO86@_STILOK:
	MOV	CX,word [@F_NEXT+BX]  ;CX points to next FDB in chain
	ADD	word [@F_NEXT+BX],AX  ;update next-ptr to reflect block move
	MOV	BX,CX
	JMP	@GIO86@_FFNDL  ;continue quest

@GIO86@_FFOUND:
	CALL	@GIO86@_XFRSTR  ;move strings and lower FDB's up
	JMP	@GIO86@_PFDCBA  ;restore registers and exit

;XFRSTR(top, nbytes) {transfer string space}
; Entry - SI points 1 byte above block to be moved
;         AX = direction and number of bytes to be moved {nbytes}
;              (if AX .GT. 0 then strings are moved to a higher adr (UP))
;         FRETOP points 1 byte below bottom of block to be moved
; Exit  - FLAGS, AX, BX, CX, DX used (Others preserved)

;  if moving string space down, nbytes .LS. 0, top=FILTAB
;  if moving string space up, top=pointer to FDB being released,
;  perform block move
;  for each string descriptor in VARTAB, ARYTAB, temporaries do
;    if str.adr .LSS. top then
;      str.adr := str.adr + nbytes {update string descriptor}
;    else if str.adr .LSS. top+nbytes then
;      str.len := 0 {reset field variables in released FDB}
;    end; {for each string...}
;  FILTAB := FILTAB + nbytes;
;  MEMSIZ := MEMSIZ + nbytes;
;  FRETOP := FRETOP + nbytes;
;  SAVFRE := SAVFRE + nbytes; (so CHAIN will work)
;  PTRFIL := PTRFIL + nbytes; (if it was pointing to a moved FDB)

@GIO86@_XFRSTR:	PUSH	SI
	PUSH	DI
	DEC	SI  ;SI points to top of block to be moved
	MOV	DI,SI  ;DI points to top of block to be moved
	MOV	DX,AX  ;DX=byte-count adjustment for block move
	ADD	DI,AX  ;DI points to top of dest of block move
	MOV	CX,SI
	SUB	CX,word [@FRETOP]  ;CX = number of bytes to transfer
	JZ	@GIO86@_XFRSTX  ;return if string space is empty
	PUSH	SI
	PUSH	DI
	STD  ;set Post-Decrement mode
	OR	AX,AX
	JNS	@GIO86@_XFRSUP  ;brif moving strings up in memory
	CLD  ;set Post-Increment mode
	SUB	SI,CX
	SUB	DI,CX  ;start transfer from bottom
	INC	SI  ;SI points to bottom of SRC block
	INC	DI  ;DI points to bottom of DST block
@GIO86@_XFRSUP:
 REP	MOVSB  ;execute block move
	POP	DI  ;restore DI points to TOP of DST block
	POP	SI  ;restore SI points to TOP of SRC block

;Update all string descriptors in VARTAB
; SI points to top of source of block move
; DI points to top of destination of block move
; DX = byte count adjustment for block move

	MOV	BX,word [@VARTAB]  ;Look at simple strings
@GIO86@_CSVAR:	CMP	BX,word [@ARYTAB]  ;Done if we have reached array table
	JZ	@GIO86@_CAYVAR  ;Yes
	CALL	@SKPNAM  ;Skip name, returns Z if was a string
	JNZ	@GIO86@_CSKPVA  ;Skip this var, not string
	CALL	@GIO86@_UPDSTD  ;Update this string descriptor
	XOR	AL,AL  ;UPDSTD has already incremented [BX]
@GIO86@_CSKPVA:
	MOV	AH,((0) and 0FFh)
	ADD	BX,AX  ;Add length of VALTYP
	JMP	@GIO86@_CSVAR

;Update all string descriptors in ARYTAB

@GIO86@_CAYVA2:	MOV	BX,AX  ;BX points to next string descriptor
@GIO86@_CAYVAR:	CMP	BX,word [@STREND]  ;New limit of search
	JZ	@GIO86@_XFRSTX  ;branch if done searching arrays
	CALL	@SKPNAM  ;Skip over name
	PUSHF  ;save string-name indicator
	MOV	AX,word [BX+0]  ;Get length of array
	INC	BX
	INC	BX
	ADD	AX,BX  ;AX points to next entry in ARYTAB
	POPF  ;String array?
	JNZ	@GIO86@_CAYVA2  ;No, look at next one
	PUSH	AX  ;save pointer to end of array
	MOV	AL,byte [BX+0]  ;Pick up number of DIMs
	MOV	AH,((0) and 0FFh)  ;Make double with high zero
	ADD	BX,AX  ;Go past DIMS
	ADD	BX,AX
	INC	BX  ;One more to account for # of DIMs
@GIO86@_CAYSTR:	POP	AX  ;AX points to end of array
	CMP	BX,AX  ;Are we done with this array?
	JZ	@GIO86@_CAYVAR  ;Get next array
	PUSH	AX
	CALL	@GIO86@_UPDSTD  ;Update string descriptor
	JMP	@GIO86@_CAYSTR

@GIO86@_XFRSTX:	MOV	CX,word [@PTRFIL]
	CMP	CX,word [@FRETOP]
	JB	@GIO86@_XFSTX1  ;brif PTRFIL pointed below moved block
	CMP	CX,SI
	JAE	@GIO86@_XFSTX1  ;brif PTRFIL pointed above moved block
	ADD	word [@PTRFIL],DX  ;Adjust PTRFIL for block move
@GIO86@_XFSTX1:	ADD	word [@FRETOP],DX  ;Adjust FRETOP for block move
	ADD	word [@SAVFRE],DX  ;Adjust SAVFRE for block move
	ADD	word [@FILTAB],DX  ;Adjust FILTAB for block move
	ADD	word [@MEMSIZ],DX  ;Adjust MEMSIZ for block move
	POP	DI
	POP	SI
	RET

;Update String Descriptor pointed to by BX.
; Entry - BX points to string descriptor
;         SI points to top of source for block move
;         DI points to top of destination for block move
;         DX = size and direction of block move
; Exit  - BX points 1 byte beyond string descriptor
;         if string descriptor pointed inside buffer being released, len=0
;         if descriptor points within block-move, its pointer is adjusted.
;         CX used.  All other registers preserved.

@GIO86@_UPDSTD:
	MOV	CX,word [BX+1]  ;CX points to string data
	CMP	CX,word [@FRETOP]
	JBE	@GIO86@_UPDSTX  ;brif string data is below string space
	CMP	CX,SI
	JBE	@GIO86@_UPDSTU  ;brif string data was block moved
	CMP	CX,DI
	JA	@GIO86@_UPDSTX  ;brif string not in buffer being freed
	MOV	byte [BX+0],((0) and 0FFh)  ;set string len to 0 (reset field buf)
@GIO86@_UPDSTU:
	ADD	word [BX+1],DX  ;adjust pointer for block move
@GIO86@_UPDSTX:
	ADD	BX,3  ;BX points 1 byte beyond string desc
	RET

; SUBTTL General Queue support routines

; PUBLIC	INITQ,PUTQ,GETQ,NUMQ,LFTQ

;These routines are all called with SI pointing to an 8-byte queue descriptor
; which is organized (invisibly to the caller) as follows:

	@GIO86@_Q_PUT=0  ;points to the next empty byte in the queue
	@GIO86@_Q_GET=2  ;points to the next byte to be fetched (oldest data)
	@GIO86@_Q_BUF=4  ;points to the 1st byte of the physical buffer
	@GIO86@_Q_END=6  ;points 1 byte beyond the end of the physical buffer

;   Note: if Q.PUT(SI)=Q.GET(.SI), the queue is empty
;         Size of queue buffer is Q.END - Q.BUF
;         Maximum data in queue at any time is Q.END - Q.BUF - 1

;INITQ - initialize queue descriptor for empty queue
; Entry - SI points to 8 byte queue descriptor
;         BX points to 1st byte of queue buffer
;         [AX] = size of queue buffer
; Exit  - AX is used

@INITQ:	MOV	word [@GIO86@_Q_PUT+SI],BX
	MOV	word [@GIO86@_Q_GET+SI],BX
	MOV	word [@GIO86@_Q_BUF+SI],BX
	ADD	AX,BX
	MOV	word [@GIO86@_Q_END+SI],AX
	RET

;PUTQ - append data to back of queue
; Entry - SI points to 8 byte queue descriptor
;         [AL]=data to be put in queue
; Exit  - FLAGS.Z is true if queue is full

@PUTQ:	MOV	BX,word [@GIO86@_Q_PUT+SI]
	MOV	byte [BX+0],AL
	CALL	@GIO86@_BUMPQP  ;advance PUT-POINTER BX
	CMP	BX,word [@GIO86@_Q_GET+SI]
	JE	@GIO86@_PQFULL  ;brif queue is full (ignore new data)
	MOV	word [@GIO86@_Q_PUT+SI],BX  ;save new PUT-POINTER
@GIO86@_PQFULL:	RET

;GETQ - get next byte from front of queue
; Entry - SI points to 8 byte queue descriptor
; Exit  - FLAGS.Z is true if queue is empty
;         otherwise, [AL]=data to be put in queue
;         AX is used

@GETQ:	MOV	BX,word [@GIO86@_Q_GET+SI]
	CMP	BX,word [@GIO86@_Q_PUT+SI]
	JE	@GIO86@_GQEMTY  ;branch if queue is empty
	MOV	AL,byte [BX+0]  ;get next byte from queue
	CALL	@GIO86@_BUMPQP  ;advance queue pointer BX
	MOV	word [@GIO86@_Q_GET+SI],BX  ;save new GET-POINTER
	OR	BX,BX  ;set NZ so caller knows AL has data
@GIO86@_GQEMTY:	RET

@GIO86@_BUMPQP:	INC	BX
	CMP	BX,word [@GIO86@_Q_END+SI]
	JB	@GIO86@_BUMPQX  ;branch if no need to Wrap-Around
	MOV	BX,word [@GIO86@_Q_BUF+SI]  ;reset pointer to start of buf
@GIO86@_BUMPQX:	RET

;LFTQ - How many times can PUTQ be successfully called for queue SI
; Entry - SI points to 8 byte queue descriptor
; Exit  - [AX] = number of bytes free in queue (0..QueueSize - 1)

@LFTQ:	MOV	AX,word [@GIO86@_Q_GET+SI]
	DEC	AX
	SUB	AX,word [@GIO86@_Q_PUT+SI]
	JMP	@GIO86@_NUMQ1

;NUMQ - How many times can GETQ be successfully called for queue SI
; Entry - SI points to 8 byte queue descriptor
; Exit  - [AX] = number of bytes of data in queue (0..QueueSize - 1)

@NUMQ:	MOV	AX,word [@GIO86@_Q_PUT+SI]
	SUB	AX,word [@GIO86@_Q_GET+SI]
@GIO86@_NUMQ1:	JAE	@GIO86@_NUMQX  ;brif PUT-POINTER exceeds GET-POINTER
	ADD	AX,word [@GIO86@_Q_END+SI]
	SUB	AX,word [@GIO86@_Q_BUF+SI]
@GIO86@_NUMQX:	RET

; SUBTTL I/O Initialization Called by INIT

; PUBLIC	GIOINI,GIOTRM

@GIOINI:
	CALL	@GIO86@_MSISET  ;Init MSDOS interrupts &H23 & &H24
	XOR	AX,AX
	MOV	word [@STKLOW],AX
	MOV	word [@FILTAB],0  ;so FDBPTR will work during initialization
	MOV	byte [@NLONLY],AL
	MOV	BX,word [@DEVINI]  ;DI points to array of init routines
	CALL	@GIO86@_DOALDV
	JMP	@FINPRT  ;reset PTRFIL to Keyboard

@GIOTRM:	MOV	BX,word [@DEVTRM]  ;DI points to array of terminate routines
	CALL	@GIO86@_DOALDV
	CALL	@GIO86@_MSIRST  ;Replace MSDOS int vectors &H23 & &H24
	RET

@GIO86@_DOALDV:	MOV	AL,((@@S_NDEV) and 0FFh)
	CBW  ;[CX]=number of devices in system
	ADD	AX,AX
	JZ	@GIO86@_DOALLX  ;branch if no non-disk devices
	MOV	DI,AX  ;[DI]=2*number of non-disk devices
@GIO86@_DOALLP:	PUSH	BX
	PUSH	DI
	CALL	 word [cs:BX+DI-2]  ;Call initialization/termination routine
	POP	DI
	POP	BX
	DEC	DI
	DEC	DI
	JNZ	@GIO86@_DOALLP  ;Loop until Device ID = 0 (disk)
@GIO86@_DOALLX:
	RET

;FINLPT forces a carriage return on LPT1 if it is not already at left margin.
; It then falls into FINPRT.
; Exit  - AX, SI, DI, FLAGS used, all other registers preserved.

@FINLPT:	PUSH	AX
	MOV	AH,((@G_GPS) and 0FFh)  ;Get column position request-code
;        MOVI    DI,$CODE+2*<^O400-$.LPT1>
	MOV	DI,@@S_LPT1
	NEG	DI  ; Change neg. dev. # to 0 based offset
	AND	DI,255
	SHL	DI,1  ; ASM86 cann't multiply externals by 2
	PUSH	DI  ;save Device Code
	CALL	@GIO86@_TBLDSP  ;function [AH] on device [DI] (LPT1)
	POP	DI
	OR	AH,AH  ;test LPT1 current column position
	JZ	@GIO86@_FINLPX  ;branch if at column 0
	MOV	AX,(256*@G_SOT)+13
	PUSH	DI  ;save Device Code
	XOR	SI,SI  ;SI=pseudo LPT FDB
	CALL	@GIO86@_TBLDSP  ;Send CR to LPT
	POP	DI
	MOV	AX,(256*@G_SOT)+10
	XOR	SI,SI  ;SI=pseudo LPT FDB
	CALL	@GIO86@_TBLDSP  ;Send LF to LPT
@GIO86@_FINLPX:	POP	AX
;Fall into FINPRT

;FINPRT is called at the end of every BASIC statement and after ERROR.
; It resets the current file to be Keyboard/Crt.
; It also frees the File-Data-Block pointed to by FREFDB if it is non-zero.
; This is useful for Device-Open routines (xxxOPN).  After calling
; INIFDB to allocate an FDB, they can set FREFDB to point to allocated FDB.
; When the file gets completely opened, they can reset FREFDB to 0.
; Then if some error occurs in between, FINPRT will release the FDB.
; Exit  - AX, SI, DI, FLAGS used, all other registers preserved.

; PUBLIC	FINPRT,FINLPT
end if
; EXTRN	FREFDB:WORD
if @GW_PASS = 1
@FINPRT:
; EXTRN	SETCSR:NEAR
end if
; EXTRN	CSRY:WORD,CSRX:WORD,CSRTYP:WORD
if @GW_PASS = 1
	PUSH	DX
	MOV	DL,byte [@CSRY]
	MOV	DH,byte [@CSRX]  ;DX=current posn
	MOV	byte [@CSRTYP],((3) and 0FFh)  ;Set to user cursor
	CALL	@SETCSR  ;Display the cursor
	POP	DX
	MOV	SI,word [@FREFDB]
	OR	SI,SI
	JZ	@GIO86@_NFRFDB  ;branch if no FDB needs to be released
	CALL	@GIO86@_FFREE
@GIO86@_NFRFDB:	XOR	AX,AX
	MOV	word [@FREFDB],AX  ;reset FREE-FDB flag
	CALL	@CLSFIL  ;close file #0 (if NLONLY=0)
	XOR	AX,AX
	TEST	byte [@NLONLY],((1) and 0FFh)
	JNZ	@GIO86@_RET45  ;don't clear PTRFIL if loading program
	MOV	word [@PTRFIL],AX  ;future I/O will use Keyboard/CRT
@GIO86@_RET45:	RET
; SUBTTL  MSDOS   Abort/Initialization/Termination Processing

end if
; EXTRN	DINTAD:WORD,CTLCAD:WORD
; EXTRN	MSDCCF:WORD
if @GW_PASS = 1

; EXTRN	ERROR:NEAR
; EXTRN	ERRDWP:NEAR,ERRDNR:NEAR,ERRDME:NEAR

; PUBLIC	SAVVEC,SETVEC

;DSKERR - Processing for MSDOS interrupt &H23
;         Exit is made through ERROR.  No IRET is executed.

@GIO86@_DSKERR:	STI
	MOV	AX,DI  ;[AX]= Error code
	ADD	SP,20  ;Adjust stack
	POP	DS  ;Get BASIC data segment
	POP	ES  ;Get BASIC extra segment
	MOV	DL,((@ERRDWP) and 0FFh)
	OR	AL,AL  ;Test for "Disk write protect"
	JZ	@GIO86@_DSKERX  ;Disk write protect
	MOV	DL,((@ERRDNR) and 0FFh)
	CMP	AL,((2) and 0FFh)  ;Test for "Disk not ready"
	JZ	@GIO86@_DSKERX  ;Disk not ready
	MOV	DL,((@ERRDME) and 0FFh)  ;Else "Disk media error
@GIO86@_DSKERX:	JMP	@ERROR  ;Go report the error and return
;Extra stuff on stack is removed by ERROR

;MSCTLC - Processing for MSDOS interrupt &H23

@GIO86@_MSCTLC:	MOV	byte [@MSDCCF],((255) and 0FFh)  ;Record control-C event for POLKEY
	IRET

;MSISET - Set MSDOS termination and Ctl-C processing addresses.
;         The current addresses are saved for restoration upon termination
;         All registers preserved.

@GIO86@_MSISET:	PUSH	AX
	PUSH	DX
	PUSH	ES
	MOV	AX,36  ;MSDOS fatal error interrupt
	MOV	BX,@DINTAD  ;Get save location for fatal error
	CALL	@SAVVEC
	DEC	AX  ;MSDOS Ctl-C interrupt
	MOV	BX,@CTLCAD  ;Get save location
	CALL	@SAVVEC
	PUSH	CS
	POP	ES  ;BASIC code segment to ES
	MOV	DX,@GIO86@_MSCTLC  ;BASIC Ctl-C handler address
	CALL	@SETVEC  ;BASIC Ctl-C handler vector set
	INC	AX  ;MSDOS fatal error interrupt
	MOV	DX,@GIO86@_DSKERR
	CALL	@SETVEC  ;BASIC fatal error handler vector set
	POP	ES
	POP	DX
	POP	AX
	RET

@GIO86@_MSIRST:	PUSH	AX
	PUSH	ES
	MOV	AX,36  ;MSDOS fatal error interrupt
	LES	DX,dword [@DINTAD]  ;Get MSDOS fatal error handler add/par
	CALL	@SETVEC
	DEC	AX  ;MSDOS Ctl-C interrupt
	LES	DX,dword [@CTLCAD]  ;Get MSDOS Ctl-C handler add/par
	CALL	@SETVEC
	POP	ES
	POP	AX
	RET
;SAVVEC - Get and store an interrupt vector
;ENTRY  - AX = interrupt
;         BX = CS relative address of vector storage area
;EXIT   - all registers preserved

@SAVVEC:	PUSH	DX
	PUSH	ES
	CALL	@GIO86@_GETVEC
	MOV	word [BX+0],DX  ;Save address portion
	MOV	DX,ES
	MOV	word [BX+2],DX  ;Save paragraph portion
	POP	ES
	POP	DX
	RET

;SETVEC - Set an interrupt vector
;ENTRY  - AX    = interrupt number
;         ES:DX = new interrupt vector
;EXIT   - All registers preserved

@SETVEC:	PUSH	AX
	PUSH	BX
	PUSH	CX
	PUSH	DX
	CALL	@GIO86@_XCESDS  ;Swap ES and DS
	@DOSIO	37  ;Set interrupt
	CALL	@GIO86@_XCESDS  ;Swap ES and ES back
	JMP	@PDCBAX  ;POP DX,CX,BX,AX and RET

@GIO86@_XCESDS:	PUSH	ES
	PUSH	DS
	POP	ES
	POP	DS
	RET

;GETVEC - Get current interrupt vector
;ENTRY  - AX    = interrupt number
;EXIT   - ES:DX = interrupt vector
;         All other registers preserved

@GIO86@_GETVEC:	PUSH	AX
	PUSH	BX
	PUSH	DS
	SHL	AX,1
	SHL	AX,1  ;Calculate interrupt address
	MOV	BX,AX
	XOR	AX,AX
	MOV	DS,AX  ;Get interrupt paragraph
	LES	DX,dword [BX+0]  ;Get interrupt vector
	POP	DS
	POP	BX
	POP	AX
	RET
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
