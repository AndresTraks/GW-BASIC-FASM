; [ This translation created 10-Feb-83 by Version 4.3 ]

if @GW_PASS = 1

include 'OEM.H'

; TITLE   GWSTS - GW-BASIC Common Statement Support

; COMMENT	*

; --------- --- ---- -- ---------
; COPYRIGHT (C) 1982 BY MICROSOFT
; --------- --- ---- -- ---------

;         *

;General Feature Switches (Not OEM Switches)

@GWSTS@_KANADT=0  ;Japanese date format("[yy]yy/mm/dd")
@GWSTS@_STKEYF=1  ;Start number of string function keys
@GWSTS@_IBMCSR=@IBMLIK  ;IBM comp. cursor interface
@GWSTS@_FKEYCR=60  ;CR character for F-KEY display line
@GWSTS@_GWLEV2=0  ;Version 2.0 of GW BASIC-86

;OEM Switches (ONLY INCLUDE IF ABSOLUTELY NECESSARY)

@GWSTS@_MCI=0
@GWSTS@_TETRA=0
@GWSTS@_MELCO=0
@GWSTS@_ZENITH=0

;Definition of scroll types
; Choice of scroll type is by switch SCROLT.
; Switches defined here are used to implement a specific SCROLT type.
; If other scroll types are needed then additional SCROLT types should be
;   defined here.
	@GWSTS@_INVLIN=@SCROLT  ;Invisible (function key) Line
	@GWSTS@_FKFSRL=(@SCROLT-1) AND 1  ;Clear fkeys/full scroll/rewrite fkeys

;Local Switches

	@GWSTS@_KEYFSW=0  ;No KEY Function
	@GWSTS@_INTHND=@SCP  ;MSDOS Ctl-C interrupt handler
	@GWSTS@_CLRFMT=(@GWSTS@_MELCO-1) AND (@GWSTS@_ZENITH-1)  ;New COLOR parameter format
	@GWSTS@_FKEYCR=27  ;IBM CR FKey display line graphic

; EXTRN	CHRGTR:NEAR,SYNCHR:NEAR,SNERR:NEAR,FCERR:NEAR,GETBYT:NEAR
; EXTRN	USERR:NEAR

if @CPM86
macro @CPMXIO DFUN {
  MOV	CL,((DFUN) and 0FFh)
  INT	224
}
end if

macro @DOSIO DFUN {
  MOV	AH,((DFUN) and 0FFh)
  INT	33
}
	@GWSTS@_GDAT=42  ;MS-DOS Get Date Function
	@GWSTS@_SDAT=43  ;MS-DOS Set Date Function
	@GWSTS@_GTIM=44  ;MS-DOS Get Time Function
	@GWSTS@_STIM=45  ;MS-DOS Set Time Function
; PUBLIC	PATCHG
@PATCHG:	DB	500 dup (?)  ;GW patch space
; SUBTTL CLS,LOCATE,WIDTH (of screen),LCOPY

; PUBLIC	CLS,LOCATE,GWWID,LCOPYS,COLOR,GETLIN,SCRENF,SCREEN

end if
; EXTRN	LINCNT:WORD,LINLEN:WORD,CSRY:WORD,CSRX:WORD,BUF:WORD
if @GW_PASS = 1

; EXTRN	GETFBC:NEAR
; EXTRN	SCRSTT:NEAR,SCRATR:NEAR
; EXTRN	SETCLR:NEAR,SWIDTH:NEAR
; EXTRN	LCPY:NEAR

	@GWSTS@_COMMA=","
	@GWSTS@_OPAREN="("
	@GWSTS@_CPAREN=")"
	@GWSTS@_QUOTE=34
	@GWSTS@_BKSPC=8
	@GWSTS@_CR=13
	@GWSTS@_LF=10
;CLS: CLear Screen issues an escape sequence to clear
;     the CRT.  Sequences are ANSII standard whereas the machine
;     default is not.  CLS resets the graphics cursor position.
;ENTRY - none
;EXIT  - none
;USES  - none

; EXTRN	CLRSCN:NEAR
@CLS:	CALL	@SCNINT  ;Test for optional parameter
	CMC
	PUSHF
	PUSH	AX
	CALL	@EOSCHK  ;Test for end of statement
	POP	AX
	POPF
	PUSH	BX
	CALL	@CLRSCN
	POP	BX
	RET
;LOCATE: Parse the following syntax:
;       LOCATE [Y] [, [X] [, [CURSOR] [, [START] [, [STOP] ]]]

; EXTRN	SCNPOS:NEAR
@LOCATE:	CALL	@SCNINT  ;Get optional Y parameter
	JNB	@GWSTS@_YLCPRM  ;Parameter present
	CALL	@GWSTS@_GTLINE  ;Get the current screen position
@GWSTS@_YLCPRM:	MOV	DL,AL
	OR	AL,AL  ;Test for LOCATE 0
	JZ	@GWSTS@_GOFCER
	SUB	DL,byte [@KEYSW]  ;Increment if PF-keys are displayed
	CMP	DL,byte [@LINCNT]  ;Check for parameter range
	JA	@GWSTS@_GOFCER
	PUSH	AX  ;Save new Y location
	CALL	@SCNINT  ;Get optional X parameter
	JNB	@GWSTS@_XLCPRM  ;Parameter present
	CALL	@SCNPOS  ;Get the current screen position
	MOV	AL,DH  ;Default to current cursor position
@GWSTS@_XLCPRM:	MOV	DL,AL
	DEC	DL  ;Dissallow LOCATE ,0
	CMP	DL,byte [@LINLEN]  ;Check for parameter range
	JAE	@GWSTS@_GOFCER
	PUSH	AX  ;Save new X
	CALL	@SCNINT  ;Cursor on/off - 0=off else on
; EXTRN	CSRATR:NEAR
	MOV	AH,((255) and 0FFh)  ;Ensure non-zero
	JNB	@GWSTS@_LOCPR1  ;Parameter 1 found
	XOR	AH,AH  ;Flag as a default
@GWSTS@_LOCPR1:	PUSH	AX  ;Push first parameter and flag
	CALL	@SCNINT  ;Get next parameter
	MOV	AH,((255) and 0FFh)  ;Ensure non-zero flag
	JNB	@GWSTS@_LOCPR2  ;Parameter 2 found
	XOR	AH,AH  ;Flag as a default
@GWSTS@_LOCPR2:	PUSH	AX  ;Push second parameter and flag
	CALL	@SCNINT  ;Get next parameter
	MOV	AH,((255) and 0FFh)  ;Ensure non-zero flag
	JNB	@GWSTS@_LOCPR3  ;Parameter 3 found
	XOR	AH,AH  ;Flag as a default
@GWSTS@_LOCPR3:	PUSH	AX  ;Push third parameter
	CALL	@EOSCHK  ;Check for end of statement
	MOV	DX,BX  ;Save text pointer
	POP	CX
	POP	BX
	POP	AX  ;Recover three parameters
	PUSH	DX  ;Save text pointer
	CALL	@CSRATR  ;Set Cursor Attribute (OEM routine)
	JB	@GWSTS@_GFCERR  ;Declare error from CSRATR
	POP	BX  ;Text pointer
@GWSTS@_SETLOC:	MOV	AX,BX
	POP	CX
	POP	BX
	PUSH	AX
	MOV	BH,CL
; EXTRN	SCNLOC:NEAR
	MOV	AX,BX
	CALL	@SCNLOC  ;position cursor at line [AL], col [AH]
end if
; EXTRN	CSRTYP:WORD
if @GW_PASS = 1
; EXTRN	CSRDSP:NEAR
	MOV	DX,AX  ;Load cursor position
	MOV	AL,((3) and 0FFh)  ;Signal for user cursor
	CALL	@CSRDSP  ;Set cursor
	POP	BX  ;Restore text pointer
	RET

@GWSTS@_GOFCER:	JMP	@FCERR
;GWWID: Parsing for WIDTH [X] [, [Y]]
;ENTRY - WIDTH LPRINT is not a possibility at this point.
;EXIT  - AL = X param
;        BX = text pointer

@GWWID:	CALL	@SCNINT  ;Get X dimension
	JNB	@GWSTS@_XPRAM  ;X param found
	MOV	AL,byte [@LINLEN]  ;Use current as default
@GWSTS@_XPRAM:	PUSH	AX  ;Save for RET to WIDTH
	PUSH	AX  ;Save for GWWID use
	CALL	@SCNINT  ;Get Y dimension
	JNB	@GWSTS@_YPRAM  ;Y param found
	MOV	AL,byte [@LINCNT]  ;Use current as default
@GWSTS@_YPRAM:	PUSH	AX
	CALL	@EOSCHK  ;Must be at end of statement
	POP	AX
	CMP	AL,byte [@LINCNT]  ;Set CC's for Y dimension change
	LAHF
	MOV	CX,AX
	POP	AX
	CMP	AL,byte [@LINLEN]  ;Set CC's for X dimension change
	LAHF
	AND	AH,CH  ;Set CC's for X OR Y change
	SAHF
	JZ	@GWSTS@_GWWIDX  ;No change - done
	PUSH	BX  ;Save text pointer
	PUSH	AX  ;save Width
	PUSH	CX  ;save Height
	CALL	@SWIDTH  ;Machine dependent set logic
	POP	CX
	POP	AX
	JB	@GWSTS@_GFCERR  ;Error detected within SWIDTH
	POP	BX  ;Restore text pointer
@GWSTS@_GWWIDX:	POP	AX  ;Return X dimension for WIDTH
	RET

@GWSTS@_GFCERR:	JMP	@FCERR

;LCOPY: Copy the screen to the line printer.
;ENTRY - BX = text pointer
;EXIT  - BX = text pointer
@LCOPYS:	MOV	DL,((0) and 0FFh)  ;default parm is 0
	JZ	@GWSTS@_NOPARM  ;branch if end-of-statement
	CALL	@GETBYT  ;[DL]=parm
@GWSTS@_NOPARM:	CALL	@EOSCHK  ;Check for unwanted parameters
	PUSH	BX  ;Save text pointer
	CALL	@LCPY
	JB	@GWSTS@_GFCERR  ;Error detected in low level routine
	POP	BX
	RET
; SUBTTL  COLOR,GETLIN,SCREEN (function and statement)
;COLOR: Set the foreground, background, and boarder attributes.
;       SYNTAX - COLOR [FOR] [,BACK [,BOARD]]
;       Where - FOR   = Foreground attribute
;               BACK  = Background attribute
;               BOARD = Boarder attribute

@COLOR:	CALL	@GWSTS@_GTPRMS  ;Get arbitrary number of int. parms.
@GWSTS@_COLOR1:	PUSH	BX  ;Save text pointer
	MOV	BX,DI  ;Get parameter buffer pointer
	CALL	@SETCLR  ;Check colors for validity
	JB	@GWSTS@_GFCERR  ;Error detected by low level routine
	POP	BX
	RET
;GETLIN: Obtain the current cursor line number.
;EXIT - FAC = cursor line number
;       BX preserved
end if
; EXTRN	LINLEN:WORD,LINCNT:WORD,KEYSW:WORD
if @GW_PASS = 1
@GETLIN:	CALL	@GWSTS@_GTLINE
	PUSH	BX
	XOR	BX,BX
	MOV	BL,AL
	CALL	@MAKINT
	POP	BX
	CALL	@CHRGTR
	RET

;GTLINE: Get the line number of the character position to which the next
;character would be written.
;Entry - none
;Exit  - [AL] = line number
;Uses  - AH

@GWSTS@_GTLINE:	MOV	AL,byte [@CSRY]  ;BX = cursor line number
	MOV	AH,byte [@CSRX]
	CMP	AH,byte [@LINLEN]
	JBE	@GWSTS@_GETLN0  ;BRIF will not wrap before next char is output
	MOV	AH,byte [@LINCNT]  ;AL=last valid line number
	DEC	AH  ;Scroll always occurs on line [LINCNT]-1
	CMP	AL,AH
	JAE	@GWSTS@_GETLN0  ;BRIF wrap will cause scroll
	INC	AL  ;Else wrap will cause line number increment
@GWSTS@_GETLN0:	RET
;SCRENF: Obtain character from screen.
@SCRENF:
	CALL	@CHRGTR  ;Eat the SCREEN token since SCREEN is
;defined as a statement and the function
;is dispatched to by EVAL.
	CALL	@SYNCHR
	DB	@GWSTS@_OPAREN  ;Check for "("
	CALL	@SCNINT  ;Get Y parameter
	JB	@GWSTS@_FCERGO  ;Parameter not present
	DEC	AL
	CMP	AL,byte [@LINCNT]  ;Check range [1,LINCNT]
	JAE	@GWSTS@_FCERGO  ;Out of range
	INC	AL
	PUSH	AX  ;Y param.
	CALL	@SCNINT  ;Check for X param
	JB	@GWSTS@_FCERGO  ;Error - no X param
	DEC	AL
	CMP	AL,byte [@LINLEN]  ;Check range [1,LINLEN]
	JAE	@GWSTS@_FCERGO  ;Out of range
	INC	AL
	PUSH	AX  ;X param.
	CMP	AH,((@GWSTS@_CPAREN) and 0FFh)  ;Check terminator
	JE	@GWSTS@_SCRCHR  ;End of params - go get char.
	CALL	@SCNINT
	JB	@GWSTS@_FCERGO  ;Error - no CPAREN and no Z param.
	CMP	AH,((@GWSTS@_CPAREN) and 0FFh)  ;Must now have CPAREN
	JNE	@GWSTS@_FCERGO
	CMP	AL,((0) and 0FFh)  ;Is Z zero?
	JE	@GWSTS@_SCRCHR  ;Yes - go get screen character
	POP	AX  ;Retrieve X param
	POP	CX  ;Retrieve Y param
	PUSH	BX  ;Save text pointer
	MOV	BX,CX  ;Call SCRATR with AX=X,BX=Y
	CALL	@SCRATR  ;Get screen attributes
	JMP	@GWSTS@_SCRENX

@GWSTS@_FCERGO:	JMP	@FCERR

@GWSTS@_SCRCHR:	POP	AX  ;Retrieve col number
	POP	CX  ;Retrieve row number
	PUSH	BX  ;Save the text pointer
; EXTRN	SCRINP:NEAR
	PUSH	DX
	MOV	DL,CL
	MOV	DH,AL
	STC  ;Indicate call is from SCREEN function
	CALL	@SCRINP  ;[AX]=Read char at (DH,DL)
	MOV	BX,AX  ;return result in BX
	POP	DX
@GWSTS@_SCRENX:	CALL	@MAKINT  ;Set FAC
	POP	BX  ;Retrieve text pointer
	DEC	BX
	CALL	@CHRGTR
	RET
;SCREEN: This statement has no standard syntax.  It is handled
;        by parsing single byte integers until end of statement.
;        Parameters may be null (appearance of a comma before an
;        expression is encountered).
;       SCRSTT (machine dependent) is called to process parameters
;       which are in a list which is headed by a one word parameter
;        count.  The remaining list entries are two bytes long.
;        The first byte is 0 if the SCREEN parameter was null.
;        The second byte is the parameter value if it is nonnull
;        or meaningless (if the parameter was null).

@SCREEN:	CALL	@GWSTS@_GTPRMS  ;Get single byte integer parms
	PUSH	BX
	MOV	BX,DI
	CALL	@SCRSTT  ;Process params
	JB	@GWSTS@_FCERGO  ;Error detected in low level routine
	POP	BX  ;Restore text pointer
	RET

@GWSTS@_GTPRMS:	MOV	DI,@BUF  ;Parameters stored in BUF
	XOR	CX,CX  ;Initialize parameter count
	INC	DI  ;Reserve parameter count location
@GWSTS@_SCRLOP:	INC	CX  ;Count the param
	PUSH	CX
	PUSH	DI
	CALL	@SCNINT  ;Look for a parameter
	POP	DI
	POP	CX
	JZ	@GWSTS@_STTEND  ;End of statement encountered
	JNB	@GWSTS@_PRMFND  ;Parameter found (AH = separator)
	XOR	AX,AX  ;Indicate a null parameter
@GWSTS@_PRMFND:	XCHG	AH,AL
	MOV	word [DI+0],AX  ;Load parameter to list
	INC	DI  ;Next list entry
	INC	DI
	JMP	@GWSTS@_SCRLOP  ;Go get next param

@GWSTS@_STTEND:	JB	@GWSTS@_NOPRM
	MOV	byte [DI+0],((255) and 0FFh)  ;Set param. exists flag
	MOV	byte [DI+1],AL
	INC	CX
@GWSTS@_NOPRM:	DEC	CX
	MOV	DI,@BUF  ;Reset list index
	MOV	byte [DI+0],CL  ;Head list with param count
	RET
; SUBTTL  PUT & GET (Distinguish Disk from Graphics)

; PUBLIC	PUT,GET

; EXTRN	DPUTG:NEAR,GPUTG:NEAR

;PUT: This code parses enough of the PUT/GET statement to
;GET: distinguish between the graphics and disk versions of
;     these commands.
;       The accepted technique is to search for a "(".  This
;       does not always allow for file number expressions which begin
;       with  "(".
;ENTRY: [BX] points to the character following the token.
;EXIT  - Exit is made by jumping to the appropriate PUT/GET
;        code.
;        [BX] - restored to entry value before call of PUT/GET code.

@PUT:	MOV	CX,1  ;Set PUT flag
	JMP	@GWSTS@_PARSE
@GET:	XOR	CX,CX  ;Set GET flag
@GWSTS@_PARSE:	PUSH	CX  ;Save indication of PUT or GET
	PUSH	BX  ;Save text pointer
	CMP	AL,(("(") and 0FFh)  ;Test for "("
	JE	@GWSTS@_GRPVER  ;branch if graphics version
	CMP	AL,(("@") and 0FFh)  ;test for relative GET/PUT
	JNE	@GWSTS@_DSKVER  ;Disk code may have no "(" or "@"
@GWSTS@_GRPVER:	POP	BX  ;Restore text pointer
	POP	AX
	JMP	@GPUTG  ;Go to graphics PUT/GET

@GWSTS@_DSKVER:	POP	BX  ;Restore text pointer
	POP	AX  ;Get PUT/GET flag
	JMP	@DPUTG

; SUBTTL  Parsing Routines for GWSTS
; PUBLIC	SCNINT,EOSCHK

;SCNINT: Test for an optional integer parameter.
;       If a comma or EOL is discovered assume parameter is missing.
;       Otherwise evaluate the parameter.
;EXIT - [AL] = parameter value
;       C set - no parameter found
;       C reset - parameter found
;USES - ALL
@SCNINT:	DEC	BX
	CALL	@CHRGTR
	JZ	@GWSTS@_NOMORE  ;EOL - Param null
	CMP	AL,((@GWSTS@_COMMA) and 0FFh)
	JZ	@GWSTS@_OMITD  ;Comma found. Param null.
	CALL	@GETBYT  ;Evaluate parameter
	PUSH	AX  ;Save parameter
	DEC	BX  ;Prepare to test expression terminator
	CALL	@CHRGTR
	JZ	@GWSTS@_TRMOK  ;EOL caused termination - OK
	CMP	AL,((@GWSTS@_COMMA) and 0FFh)
	JZ	@GWSTS@_TRMCOM  ;Comma caused termination - OK
	CMP	AL,((@GWSTS@_CPAREN) and 0FFh)  ;CPAREN caused termination - OK
	JZ	@GWSTS@_TRMCOM
	POP	AX  ;Retrieve param.
	JMP	@FCERR  ;All other terminators not OK

@GWSTS@_TRMCOM:	INC	BX  ;Move over comma
@GWSTS@_TRMOK:	MOV	CL,AL  ;Save terminator
	POP	AX  ;Retrieve parameter value
	MOV	AH,CL  ;Return with AH = terminator
	CLC  ;Flag param. found
	RET

@GWSTS@_OMITD:	INC	BX
@GWSTS@_NOMORE:	MOV	AH,AL  ;Save terminator
	MOV	AL,((0) and 0FFh)  ;Set param value to 0, save flags
	STC  ;Flag param. not found
	RET
;EOSCHK: Detect garbage beyond end of statement
;ENTRY - BX = text pointer
;EXIT  - AL = 0 & all other registers preserved or
;      - Exit on error through FCERR

@EOSCHK:
	DEC	BX  ;Back up text pointer
@GWSTS@_EOSCH1:
	CALL	@CHRGTR  ;Get next character (skipping blanks)
	JZ	@GWSTS@_EOSCKX  ;End of statement
	JMP	@SNERR  ;Not EOS - error
@GWSTS@_EOSCKX:	RET

; SUBTTL  Graphics Support Specific to the 8086

; PUBLIC	LINLP3
end if
; EXTRN	MINDEL:WORD,MAXDEL:WORD,MINUPD:WORD,MAXUPD:WORD
if @GW_PASS = 1
; EXTRN	SETC:NEAR

;LINLP3: Inner loop of line code.

@LINLP3:	CALL	@SETC  ;SET CURRENT POINT
	ADD	DX,word [@MINDEL]  ;ADD SMALL DELTA TO SUM
	CMP	DX,word [@MAXDEL]  ;TIME TO UPDATE MINOR?
	JB	@GWSTS@_LINLOP  ;NO, UPDATE MAJOR AND CONTINUE
	SUB	DX,word [@MAXDEL]  ;UPDATE SUM FOR NEXT POINT
	CALL	 word [@MINUPD+1]  ;ADVANCE MINOR AXIS
@GWSTS@_LINLOP:	CALL	 word [@MAXUPD+1]  ;UPDATE MAJOR AXIS
	LOOP	@LINLP3  ;CONTINUE UNTIL COUNT EXHAUSTED
	RET
; SUBTTL  VARPT2 - VARPTR$ Function

; PUBLIC	VARPT2
; EXTRN	PTRGTN:NEAR
end if
; EXTRN	VALTYP:WORD,DSCPTR:WORD
if @GW_PASS = 1

;VARPTR$(x)
; Called after VARPTR sees next char is "$"
; Returns 3 byte string as follows:
;  byte 0: type of x
;  byte 1: low-adr of varptr(x)
;  byte 2: high-adr of varptr(x)
; Primary use is so BASCOM can handle DRAW "X"+VARPTR$(A$)

@VARPT2:
	CALL	@CHRGTR  ;get byte after "$"
	CALL	@SYNCHR
	DB	"("  ;EAT LEFT PAREN
	CALL	@PTRGTN  ;GET ADDRESS OF VARIABLE
	CALL	@SYNCHR
	DB	")"  ;EAT RIGHT PAREN
	OR	DX,DX  ;MAKE SURE NOT UNDEFINED VAR
	JNZ	@GWSTS@_VARRT2  ;SET CC'S. ZERO IF UNDEF
	JMP	@FCERR  ;ALL OVER IF UNDEF (DONT WANT
;USER POKING INTO ZERO IF HE'S
;TOO LAZY TO CHECK
@GWSTS@_VARRT2:
	PUSH	BX  ;Save text pntr
	PUSH	DX  ;Save Var addr
	MOV	AL,byte [@VALTYP]
	PUSH	AX  ;Save type
	MOV	AL,((3) and 0FFh)
	CALL	@STRINI  ;Get a 3 byte string
	MOV	BX,word [@DSCPTR]  ;Descriptor in [BX]
	POP	word [BX+0]  ;Store Type in Byte 1
	INC	BX
	POP	word [BX+0]  ;Store addr in Bytes 2-3.
	JMP	@PUTNEW  ;Desc in FAC & ret. ([BX] on stack).

; SUBTTL  PLAY/SOUND statements

; PLAY - MUSIC MACRO LANGUAGE

; PUBLIC	PLAYS
; EXTRN	DONOTE:NEAR
; EXTRN	MACLNG:NEAR,MCLXEQ:NEAR,FETCHR:NEAR,DECFET:NEAR,VALSC2:NEAR
; EXTRN	FETCHZ:NEAR

;Low-Level routine required:
; DONOTE(AL: voice (0=forground, 1=back), CX:frequency, DX:duration (1=18.7ms))
; queues note for execution, saves all regs.

@PLAYS:	MOV	DX,@GWSTS@_PLYTAB  ;POINT TO PLAY COMMAND TABLE
	JMP	@MACLNG

@GWSTS@_PLYTAB:	DB	"A"  ;THE NOTES A-G
	DW	@GWSTS@_PLYNOT
	DB	"B"
	DW	@GWSTS@_PLYNOT
	DB	"C"
	DW	@GWSTS@_PLYNOT
	DB	"D"
	DW	@GWSTS@_PLYNOT
	DB	"E"
	DW	@GWSTS@_PLYNOT
	DB	"F"
	DW	@GWSTS@_PLYNOT
	DB	"G"
	DW	@GWSTS@_PLYNOT

	DB	"M"  ;Music Meta Command
	DW	@GWSTS@_PLYMET

	DB	"N"+128  ;PLAY NUMERIC NOTE
	DW	@GWSTS@_PLYNUM
	DB	"O"+128  ;OCTAVE
	DW	@GWSTS@_POCTAV
	DB	"P"+128  ;PAUSE
	DW	@GWSTS@_PPAUSE
	DB	"T"+128  ;TEMPO
	DW	@GWSTS@_PTEMPO
	DB	"L"+128  ;LENGTH
	DW	@GWSTS@_PLYLEN
	DB	"X"  ;EXECUTE STRING
	DW	@MCLXEQ
	DB	0  ;END OF TABLE

; TABLE OF INDEXES INTO NOTTAB FOR EACH NOTE
; VALUE OF 255 MEANS NOTE NOT ALLOWED.

@GWSTS@_NOTXLT:	DB	9*2  ;A- (G#)
	DB	10*2  ;A
	DB	11*2  ;A#
	DB	12*2  ;B
	DB	255  ;NO C- OR B#
	DB	1*2  ;C
	DB	2*2  ;C#
	DB	3*2  ;D
	DB	4*2  ;D#
	DB	5*2  ;E
	DB	255  ;NO E# OR F-
	DB	6*2  ;F
	DB	7*2  ;F#
	DB	8*2  ;G
	DB	9*2  ;G#

; TABLE OF NOTE FREQUENCIES
; THESE ARE THE FREQUENCIES IN HERTZ OF THE TOP OCTAVE (6)
; DIVIDED DOWN BY POWERS OF TWO TO GET ALL OTHER OCTAVES

@GWSTS@_NOTTAB:	DW	4186  ;C
	DW	4435  ;C#
	DW	4699  ;D
	DW	4978  ;D#
	DW	5274  ;E
	DW	5588  ;F
	DW	5920  ;F#
	DW	6272  ;G
	DW	6645  ;G#
	DW	7040  ;A
	DW	7459  ;A#
	DW	7902  ;B

@GWSTS@_PLYLEN:	JNB	@GWSTS@_PLGOFC  ;ERROR IF NO ARG
	CMP	DL,((65) and 0FFh)  ;ALLOW ONLY UP TO 64
	JNB	@GWSTS@_PLGOFC  ;FC ERROR IF TOO BIG
	OR	DL,DL  ;DON'T ALLOW ZERO
	JZ	@GWSTS@_PLGOFC  ;FC ERROR IF ZERO
	MOV	byte [@NOTELN],DL  ;STORE NOTE LENGTH
	RET

@GWSTS@_PTEMPO:	CMP	DL,((32) and 0FFh)  ;ALLOW ONLY 32 - 255
	JB	@GWSTS@_PLGOFC  ;FC ERROR IF TOO SMALL
	MOV	byte [@BEATS],DL  ;Store Beats per minute
	RET

@GWSTS@_NCFCER:
@GWSTS@_PPAUSE:	JNB	@GWSTS@_PLGOFC  ;ERROR IF NO ARG
	XOR	CX,CX  ;PASS FREQ OF 0
	CMP	DL,((65) and 0FFh)  ;ALLOW ONLY 1-64
	JNB	@GWSTS@_PLGOFC  ;FC ERROR IF TOO BIG
	OR	DL,DL  ;SEE IF ZERO
	JZ	@GWSTS@_PLYRET  ;RETURN IF SO - NO PAUSE
	JMP	@GWSTS@_PPAUS2  ;[DX]=PAUSE LENGTH

@GWSTS@_POCTAV:	JNB	@GWSTS@_PLGOFC  ;ERROR IF NO ARG
	CMP	DL,((7) and 0FFh)  ;ALLOW ONLY OCTAVES 0..6
	JNB	@GWSTS@_PLGOFC  ;FC ERROR IF TO BIG
	MOV	byte [@OCTAVE],DL
@GWSTS@_PLYRET:	RET

@GWSTS@_PLYNUM:	JNB	@GWSTS@_PLGOFC  ;ERROR IF NO ARG
	MOV	AL,DL  ;GET NOTE NUMBER INTO [AL]
	OR	AL,AL  ;SEE IF ZERO (PAUSE)
	JZ	@GWSTS@_PLYNO3  ;DO THE PAUSE
	CMP	AL,((85) and 0FFh)  ;ALLOW ONLY 0..84
	JNB	@GWSTS@_PLGOFC  ;FC ERROR IF TOO BIG
	CBW  ;CLEAR HI BYTE FOR DIVIDE
	DEC	AX  ;MAP TO 0..83
	MOV	DL,((12) and 0FFh)  ;DIVIDE BY 12
	DIV	DL
	MOV	DH,AL  ;OCTAVE TO [DH]
	MOV	AL,AH  ;NOTE NUMBER IS REMAINDER
	INC	AL  ;ADD ONE
	ADD	AL,AL  ;DOUBLE TO MAKE INDEX
	JMP	@GWSTS@_PLYNU3  ;PLAY NOTE [AL], OCTAVE [DH]

@GWSTS@_PLGOFC:	JMP	@FCERR  ;GIVE FUNCTION CALL ERROR

@GWSTS@_PLYNOT:	SUB	CL,(("A"-1) and 0FFh)  ;MAP TO 1..7
	ADD	CL,CL  ;MAP TO 2..14 (THIS ASSUMES SHARP)
	CALL	@FETCHR  ;GET NEXT CHARACTER
	JZ	@GWSTS@_PLYNO2  ;END OF STRING - NO SHARP OR FLAT
	CMP	AL,(("#") and 0FFh)  ;CHECK FOR POSSIBLE SHARP
	JZ	@GWSTS@_PLYSHP  ;SHARP IT THEN
	CMP	AL,(("+") and 0FFh)  ;"+" ALSO MEANS SHARP
	JZ	@GWSTS@_PLYSHP
	CMP	AL,(("-") and 0FFh)  ;"-" MEANS FLAT
	JZ	@GWSTS@_PLYFLT
	CALL	@DECFET  ;PUT CHAR BACK IN STRING.
	JMP	@GWSTS@_PLYNO2  ;TREAT AS UNMODIFIED NOTE.
@GWSTS@_PLYFLT:	DEC	CL  ;DECREMENT TWICE TO FLAT IT
@GWSTS@_PLYNO2:	DEC	CL  ;MAP BACK TO UNSHARPED
@GWSTS@_PLYSHP:	MOV	AL,CL  ;INTO [AL] FOR XLAT
	MOV	BX,@GWSTS@_NOTXLT  ;POINT TO TRANSLATE TABLE
@GWSTS@_@QCSLAB:  ; Code segment dummy label
	xlat byte [cs:bx]  ;TRANSLATE INTO NOTE TABLE INDEX
	OR	AL,AL  ;SEE IF LEGAL NOTE
	JS	@GWSTS@_PLGOFC  ;NOTE'S OK IF NOT .GT. 127

; ENTER HERE WITH NOTE TO PLAY IN [AL]
; NOTE 0 IS PAUSE, 2,4,6,8..10,12 ARE A-G AND FRIENDS.

@GWSTS@_PLYNO3:
	MOV	DH,byte [@OCTAVE]  ;GET OCTAVE INTO [DH] FOR LATER MATH
@GWSTS@_PLYNU3:
	PUSH	AX  ;Save Note
	PUSH	DX  ;Save Octave
	MOV	AL,byte [@NOTELN]
	MOV	byte [@NOTE1L],AL  ;One note duration = Note length
	CALL	@FETCHR
	JZ	@GWSTS@_PLYNU4  ;Brif end of string
	CALL	@VALSC2  ;See if possible number
	CMP	DL,((65) and 0FFh)  ;If was .gt. 64
	JNB	@GWSTS@_PLGOFC  ; then error
	OR	DL,DL  ;Any Length?
	JZ	@GWSTS@_PLYNU4  ;Brif not, just do note
	MOV	byte [@NOTE1L],DL  ;Store duration for this note
@GWSTS@_PLYNU4:
	POP	DX  ;Get Octave
	POP	AX  ;Restore Note
	CBW  ;FILL [AH] WITH ZEROS
	MOV	BX,AX  ;TRANSFER TO BX FOR INDEXING
	OR	BX,BX  ;SEE IF PAUSE (NOTE # 0)
	JZ	@GWSTS@_PLYNO4  ;IF PAUSE, PASS [BX]=0
	MOV	BX,word [cs:@GWSTS@_NOTTAB-2+BX]  ;FETCH FREQUENCY
	MOV	CL,((6) and 0FFh)  ;CALCULATE 6-OCTAVE
	SUB	CL,DH  ;FOR # OF TIMES TO SHIFT FREQ.
	SHR	BX,CL  ;DIVIDE BY 2^(6-OCTAVE)
	ADC	BX,0  ;ADD IN CARRY TO ROUND UP
@GWSTS@_PLYNO4:
	MOV	CX,BX  ;FREQUENCY INTO [CX] FOR DONOTE
	MOV	DL,byte [@NOTE1L]  ;Get this note's length
@GWSTS@_PPAUS2:
	MOV	AL,byte [@BEATS]  ;GET BEATS PER UNIT TIME
	MUL	DL  ;CALC NOTE LENGTH * BEATS
	PUSH	CX  ;SAVE [CX] WHILE WE DIVIDE
	MOV	CX,AX  ;CALC TIME CONST/(BEATS * NOTE LENGTH)
	MOV	DX,1  ;[DX:AX]=96000 (4*60*400.0) and will
	MOV	AX,30464  ; cause DONOTE [DX]=1 to play 2.5 milliseconds
	DIV	CX  ; (in other words [DX]=400 will play 1 second)
	POP	CX  ;RESTORE FREQUENCY
	OR	AX,AX  ;IF DURATION IS ZERO, GET OUT.
	JZ	@GWSTS@_PLYNO8
	PUSH	CX  ;Save Freq
@GWSTS@_PLYDOT:
	PUSH	AX  ;Save duration
	CALL	@FETCHR
	JZ	@GWSTS@_PLYDOX  ;Brif EOS
	CMP	AL,((".") and 0FFh)  ;Note duration extender?
	JNZ	@GWSTS@_PLYDO2  ;Brif not
	POP	AX  ;Get duration
	MOV	CX,3
	MUL	CX
	SHR	AX,1  ;Duration = Duration * 1.5
	SHR	DX,1  ;Ovf/2
	OR	DX,DX  ;Still too big?
	JZ	@GWSTS@_PLYDOT  ;Itterate if not
	JMP	@FCERR  ; else complain..
@GWSTS@_PLYDO2:
	CALL	@DECFET  ;Put char back
@GWSTS@_PLYDOX:
	POP	AX  ;Duration
	POP	CX  ;Get freq
	OR	CX,CX
	JZ	@GWSTS@_PLYNO9  ;Brif Pause
	CMP	byte [@MSCALE],((1) and 0FFh)
	JZ	@GWSTS@_PLYNO9  ;Brif Legatto
	PUSH	AX  ;Save Duration
	PUSH	CX  ;Save Frequency
	MOV	CL,byte [@MSCALE]  ;Using scale for shift count
	MOV	BX,3  ;Stecatto multiplier
	CMP	CL,((2) and 0FFh)
	JZ	@GWSTS@_PLYNO6  ;Brif Stecatto
	MOV	BX,7  ; else Normal
@GWSTS@_PLYNO6:
	MUL	BX  ;Duration * 7/8 or 3/4
	SHR	AX,CL
	OR	AX,AX
	JNZ	@GWSTS@_PLYNO7  ;If zero
	INC	AX  ; then make 1
@GWSTS@_PLYNO7:
	POP	CX  ;Get Freq
	CALL	@GWSTS@_PLYNO9  ;Send note
	POP	AX  ;Original duration
	MOV	CL,byte [@MSCALE]
	SHR	AX,CL  ;pause after note is 1/8 or 1/4
	XOR	CX,CX  ;Freq = 0 for pause
	OR	AX,AX  ;Pause = 0?
	JNZ	@GWSTS@_PLYNO9  ;Brif not
@GWSTS@_PLYNO8:
	RET  ; else do nothing
@GWSTS@_PLYNO9:
	MOV	DX,AX  ;DONOTE wants [CX]=freq, [DX]=duration.
	JMP	@GWSTS@_DOSND  ;Play freq [CX] for time [DX]

@GWSTS@_PLYMER:
	JMP	@FCERR

; PLYMET -      Process Music Meta Commands.

@GWSTS@_PLYMET:
	CALL	@FETCHZ  ;Get Meta action or error
	MOV	CL,((1) and 0FFh)  ;Factor for Legatto (1/1): MSCALE=1
	CMP	AL,(("L") and 0FFh)
	JZ	@GWSTS@_PLYDUR  ;Brif Legatto (Full note)
	INC	CL  ;Factor for Stecatto (3/4): MSCALE=2
	CMP	AL,(("S") and 0FFh)
	JZ	@GWSTS@_PLYDUR  ;Brif Stecatto (3/4)
	INC	CL  ;Factor for Normal (7/8): MSCALE=3
	CMP	AL,(("N") and 0FFh)
	JZ	@GWSTS@_PLYDUR  ;Brif Normal (7/8)
	XOR	CL,CL  ;MMODE=0 for Forground
	CMP	AL,(("F") and 0FFh)
	JZ	@GWSTS@_PLYMOD  ;Brif Foreground Music
	INC	CL  ;MMODE=1 for Background
	CMP	AL,(("B") and 0FFh)
	JNZ	@GWSTS@_PLYMER  ;Brif not Background Music
@GWSTS@_PLYMOD:
	MOV	byte [@MMODE],CL  ;Store Music Mode (0=FG, 1=BG)
	RET
@GWSTS@_PLYDUR:
	MOV	byte [@MSCALE],CL  ;Store Duration Scaling factor
	RET

;SNDINI is called to set OCTAVE, BEATS, NOTELN, NOTE1L, MSCALE, and MMODE
;to appropriate initial settings.  SNDINI is called at CLEARC and during
;initialization.
;Entry - none
;Exit  - all registers preserved

end if
; EXTRN	NOTELN:WORD,NOTE1L:WORD,BEATS:WORD,OCTAVE:WORD,MSCALE:WORD
; EXTRN	MMODE:WORD
if @GW_PASS = 1
; PUBLIC	SNDINI
@SNDINI:	MOV	byte [@BEATS],((120) and 0FFh)
	MOV	byte [@MSCALE],((3) and 0FFh)
	MOV	byte [@MMODE],((0) and 0FFh)
	MOV	byte [@NOTELN],((4) and 0FFh)
	MOV	byte [@NOTE1L],((4) and 0FFh)
	MOV	byte [@OCTAVE],((4) and 0FFh)
	CALL	@SNDRST  ;Turn off sound
	RET

;SNDRST is called to reset background music.  It is called during
; initialization from INIT and during the processing of CTL-C
; from POLKEY
; Entry - none
; Exit  - All registers preserved

; PUBLIC	SNDRST
@SNDRST:	PUSH	AX
	PUSH	BX
	PUSH	CX
	PUSH	DX
	PUSHF
	MOV	AL,((255) and 0FFh)
	CALL	@DONOTE  ;Disable background music, init music queue
	POPF
	POP	DX
	POP	CX
	POP	BX
	POP	AX
	RET

; PUBLIC	BEEPS,BEEP,SOUNDS
; EXTRN	DONOTE:NEAR,FRQINT:NEAR,FRCSNG:NEAR,GETIN2:NEAR
end if
; EXTRN	FAC:WORD
if @GW_PASS = 1

@BEEP:
@BEEPS:	MOV	CX,800  ; 800 Hz
	MOV	DX,100  ; .. for 1/4 second.
	XOR	AL,AL  ;[AL]=Music Mode (0=Forground)
	JMP	@GWSTS@_JDNOTE

@GWSTS@_DOSND:	MOV	AL,byte [@MMODE]  ;[AL]=Music Mode (0=Forground, 1=background)
@GWSTS@_JDNOTE:	CALL	@DONOTE  ;start new sound.
	JNB	@GWSTS@_DNOTOK  ;No errors detected by DONOTE
	JMP	@FCERR  ;Function call error detected
@GWSTS@_DNOTOK:
	JMP	@POLKEY  ;Allow CTL-C to interrupt and return
; SOUND  -      Make SOUNDs with the speaker.

;       Syntax: SOUND x,y

;       Where:  x is the Frequency in Hertz.
;               y is the Duration in Clock ticks. (currently 18.2/sec).

;               Frequency must be at least 37 Hz.
;               If Duration is 0, then just turn off current sound...

end if
; EXTRN	$FACLO:WORD,$FACM1:WORD
if @GW_PASS = 1
; EXTRN	$FMULS:NEAR
@SOUNDS:
	CALL	@GETIN2  ;Get frequency.
	CMP	DX,37
	JB	@GWSTS@_SNDFCE  ;Must be at least 37 Hz..
	PUSH	DX  ;Save frequency
	CALL	@SYNCHR
	DB	","
	CALL	@FRMEVL  ;Get duration.
	CALL	@EOSCHK  ;Syntax Error if not end-of-statement
	PUSH	BX  ;Text pointer
	CALL	@FRCSNG  ;Make Single Precision
	MOV	BX,@FAC  ;Point at Exponent
	CMP	byte [BX+0],((0) and 0FFh)  ;Will turn sound off if 0.
	JNZ	@GWSTS@_SOUNL4  ; Brif not, start new sound.
	POP	BX  ;Text pointer
	POP	DX  ;Frequency (not used)
	JMP	@SNDRST  ;Turn off sound, initialize the queue

@GWSTS@_SOUNL4:
	CMP	byte [BX+0],((145) and 0FFh)  ;Duration .gt. 65535?
	JNB	@GWSTS@_SNDFCE  ;Brif so, too big for *32
	PUSH	BX  ;Save FAC address
	PUSH	word [@@SFACM1]  ;Push FAC on the stack
	PUSH	word [@@SFACLO]
	MOV	BX,22  ;Mult by ^D22
	CALL	@MAKINT
	CALL	@FRCSNG  ;Get s.p. ^D22
	POP	DX  ;Get low mantissa bits
	POP	BX  ;Exp sign and high mantissa bits
	CALL	@@SFMULS  ;MULTIPLY
	POP	BX  ;FAC address
	CMP	byte [BX+0],((145) and 0FFh)  ;Overflow?
	JB	@GWSTS@_SOUNL5  ;Brif not
	MOV	word [BX-1],36991  ; else
	MOV	word [BX-3],65280  ; force to 65535
@GWSTS@_SOUNL5:
	CALL	@FRQINT  ;Convert back to Integer
	MOV	DX,BX  ; in [DX]
	POP	BX  ;Text pointer
	POP	CX  ;[CX]=Frequency, [DX]=Duration
	JMP	@GWSTS@_DOSND  ;play the note
@GWSTS@_SNDFCE:
	JMP	@FCERR  ; Complain

; SUBTTL General Event Trapping Code

; PUBLIC	ONGOTP,SETGSB
; EXTRN	STPTRP:NEAR,ONTRP:NEAR,OFFTRP:NEAR,REQTRP:NEAR,FRETRP:NEAR
end if
; EXTRN	$ON:WORD,$OFF:WORD,$STOP:WORD
; EXTRN	TRPTBL:WORD

;Event flags can have one or more of the following bits set:
; They are defined in BIMISC.MAC

; EXTRN	T_ON:WORD
; EXTRN	T_STOP:WORD
; EXTRN	T_REQ:WORD
if @GW_PASS = 1

;To support EVENT TRAPPING, The following switches should be defined
; in the machine dependant Switch File:

;       NMKEYT = number of soft keys
;       NMCOMT = number of COMmunications ports
;       NMPENT = number of light pens (0 or 1)
;       NMSTRT = number of joysticks
;       NUMTRP = total of all of the above
;       ONGOSB should be 1

;To support EVENT TRAPPING, The following variables should be defined
; in the machine dependant RAM module:

;       ONGSBF: BLOCK   1       ;some-event happend flag (see NEWSTT)
;       TRPTBL: BLOCK   3*NUMTRP
;                               ;event flags and GOSUB line ptrs

	@GWSTS@_PENOFF=0  ;offset for PEN event id's
	@GWSTS@_KEYOFF=@GWSTS@_PENOFF+@NMPENT  ;offset for KEY event id's
	@GWSTS@_COMOFF=@GWSTS@_KEYOFF+@NMKEYT  ;offset for COM event id's
	@GWSTS@_STROFF=@GWSTS@_COMOFF+@NMCOMT  ;offset for STRIG event id's

; PUBLIC	CHKINT
; EXTRN	POLKEY:NEAR,POLLEV:NEAR
end if
; EXTRN	AUTFLG:WORD,SEMFLG:WORD,SAVTXT:WORD,SAVSTK:WORD,CURLIN:WORD
if @GW_PASS = 1

;CHKINT is called from BASIC's NEWSTT loop to see if any trappable
; condition has occured.  It traps active function keys, COM input,
; light pen interrupts, joystick triggers, CTL-C, CTL-S, and
; it queues vanilla keys for CHSNS.  For efficiency, it calls POLLEV
; which looks at flag which gets set by BIOS when some interrupt occurs.
; This routine would not be necessary in a stand-alone environment since
; BASIC would manage its own interrupts.

@CHKINT:
end if
; EXTRN	MSDCCF:WORD
if @GW_PASS = 1
	TEST	byte [@MSDCCF],((255) and 0FFh)  ;Test for MSDOS-received Ctl-C
	JNZ	@GWSTS@_CHKIN1
	CALL	@POLLEV  ;Test for occurance of trapable events
	JZ	@GWSTS@_CHKINX  ;Exit - no trapable event
@GWSTS@_CHKIN1:	PUSH	BX
	PUSH	CX
	PUSH	DX
	CALL	@POLKEY  ;trap Function keys, CTL-C, CTL-S
; EXTRN	POLCOM:NEAR
	CALL	@POLCOM  ;trap COM interrupts
@GWSTS@_NOACOM:
	CALL	@GWSTS@_POLPEN  ;trap PEN interrupts
	CALL	@GWSTS@_POLSTR  ;trap STRIG interrupts
	POP	DX
	POP	CX
	POP	BX
@GWSTS@_CHKINX:	RET

;SEVSTT - Set Event Status
; Common code for parsing event-id ON/OFF/STOP
; Entry - [CL]=number of legal events for device
;         [CH]=event-id offset for device

@GWSTS@_SEVSTT:	PUSH	CX  ;save maximum and offset for class
	CALL	@SYNCHR
	DB	"("
	CALL	@GETBYT  ;[AL]=class-relative event-id
	PUSH	AX  ;save it
	CALL	@SYNCHR
	DB	")"
	PUSH	AX  ;save [AL]=$ON, $OFF, or $STOP
	CALL	@GWSTS@_EOSCH1  ;skip past $ON, $OFF, or $STOP
;error if not end of statement
	POP	DX  ;restore $ON, $OFF, or $STOP
	POP	AX  ;[AL]=class-relative event-id
	POP	CX  ;restore maximum, offset for class
	CMP	CH,((@GWSTS@_STROFF) and 0FFh)  ;Special check for STRIG(x)
	JNZ	@GWSTS@_SEVST1  ;Brif not
	ROR	AL,1  ;Divide by 2 so get 0,1,2 or 3
	JMP	@GWSTS@_SEVST2
@GWSTS@_SEVST1:
	OR	AL,AL
	JZ	@GWSTS@_SEVALL  ;branch if parm was 0
	DEC	AL  ;make parm 0-relative
@GWSTS@_SEVST2:
	PUSH	DX  ;save $ON, $OFF, or $STOP
	CMP	AL,CL  ;compare with maximum
	JGE	@GWSTS@_FCERR1  ;branch if not in range
	ADD	AL,CH  ;add in offset to get event id
	CALL	@GWSTS@_EVADR  ;[DX]=adr of event flag
	POP	AX  ;[AL]=ON, OFF, or STOP
;fall into SET1EV

;SET1EV - Set One Event
; Entry - [DX]=adr of event flag
;         [AL]=$ON, $OFF, or $STOP

@GWSTS@_SET1EV:	CALL	@GWSTS@_EVSET  ;set event flags to ON, OFF, or STOP
	RET

@GWSTS@_FCERR1:	JMP	@FCERR
@GWSTS@_SNERR1:	JMP	@SNERR

;Set status for all events of a class
; Entry - [DL]=$ON, $OFF, or $STOP token
;         [CH]=class event-id offset
;         [CL]=number of events in class

@GWSTS@_SEVALL:	PUSH	DX  ;save $ON, $OFF, or $STOP
	MOV	AL,CH  ;[AL]=class offset
	XOR	CH,CH  ;[CX]=number of entries in class
	CALL	@GWSTS@_EVADR  ;[DX] points to 1st event flag
	POP	AX  ;[AL]=ON, OFF, or STOP
@GWSTS@_SEVAL1:	CALL	@GWSTS@_EVSET  ;set event for key 9-[B]
	ADD	DX,3  ;[DX] points to next entry
	LOOPNE	@GWSTS@_SEVAL1
	RET

;EVSET changes the status of 1 event.
; Entry - [AL]=$ON, $OFF, or $STOP
;         [DX] points to event flag
; Exit -  All registers preserved.

@GWSTS@_EVSET:	PUSH	DX  ;save caller's registers
	PUSH	CX
	PUSH	BX
	PUSH	AX
	MOV	BX,DX  ;[BX]=adr of event flag
	CMP	AL,((@@SON) and 0FFh)
	JZ	@GWSTS@_EVON
	CMP	AL,((@@SOFF) and 0FFh)
	JZ	@GWSTS@_EVOFF
	CMP	AL,((@@SSTOP) and 0FFh)
	JNZ	@GWSTS@_SNERR1

@GWSTS@_EVSTP:	CALL	@STPTRP  ;stop event pointed to by [BX]
	JMP	@GWSTS@_EVONX
@GWSTS@_EVON:	CALL	@ONTRP  ;enable event pointed to by [BX]
	JMP	@GWSTS@_EVONX
@GWSTS@_EVOFF:	CALL	@OFFTRP  ;disable event pointed to by [BX]
@GWSTS@_EVONX:	POP	AX  ;restore all caller's registers
	POP	BX
	POP	CX
	POP	DX
	RET

;EVADR transforms event-id to event-flag-pointer.
; Entry - [AL] = event id
; Exit  - [DX]=adr of event flag, [AX] is used, all other regs preserved

@GWSTS@_EVADR:	XOR	AH,AH  ;[AX] = event id
	MOV	DX,AX
	ADD	AX,AX
	ADD	AX,DX  ;[AX] = 3*event id
	ADD	AX,@TRPTBL
	MOV	DX,AX
	RET

end if
; EXTRN	$KEY2B:WORD,$PEN2B:WORD,$STR2B:WORD,$COM2B:WORD
if @GW_PASS = 1
; EXTRN	DERDNA:NEAR

;ONGOTP routine is called from ON GOTO code within BINTRP
;       Do syntax checks for event traps and return.
;       Carry set indicates it was not a trap gosub definition.
;       else carry is clear

; Syntax:       ON [Event] GOSUB line no.

;       WHERE:  Event is one of following:
;               COM(x)
;               PEN
;               STRIG(x) x = 0 for Trigger A, or 2 for Trigger B.
;               KEY(x)   x = 1..NMKEYT-1

;       If one of the Event verbs does not follow the ON
;       keyword, then go back to Level 1 "ONGOTO" to
;       process ON ### GOSUB... or GOTO.

@ONGOTP:	PUSH	BX  ;Text pointer in case not us.
	XOR	CH,CH  ;Assume one byte token
	CMP	AL,((253) and 0FFh)  ;check for 2-byte token
	JB	@GWSTS@_NT2BTK  ;branch if not FF, FE or FD
	MOV	CH,AL  ;[CH] = 1st byte
	CALL	@CHRGTR  ;[AL] = 2nd byte of 2-byte token
	MOV	AH,CH  ;[AH] = 1st byte
@GWSTS@_NT2BTK:
	CMP	AX,@@SKEY2B
	MOV	CX,(256*@GWSTS@_KEYOFF)+@NMKEYT
	JZ	@GWSTS@_ONFUN  ;Brif ON KEY...
	CMP	AX,@@SCOM2B
	MOV	CX,(256*@GWSTS@_COMOFF)+@NMCOMT
	JZ	@GWSTS@_ONFUN  ;Brif ON COM...
	CMP	AX,@@SPEN2B
	MOV	CX,256*@GWSTS@_PENOFF
	JNZ	@GWSTS@_NTONPN  ;BRIF not ON PEN...
	CALL	@CHRGTR  ;get next token
	JMP	@GWSTS@_ONSTM  ;Brif ON PEN...
@GWSTS@_NTONPN:
	CMP	AX,@@SSTR2B
	MOV	CX,(256*@GWSTS@_STROFF)+@NMSTRT
	JZ	@GWSTS@_ONFUN
	STC  ;set carry - indicates not event
	POP	BX  ;Restore Entry Text pointer
	JMP	@GWSTS@_ONGOTX

@GWSTS@_FCERR2:	JMP	@FCERR

@GWSTS@_JERDNA:	JMP	@DERDNA  ;Device unavailable error if PEN

@GWSTS@_ONFUN:
	CALL	@GWSTS@_GETSUB  ;Get Event no. in (x).
	DEC	AL  ;Want base 0. (If not STRIG(x))
	CMP	CH,((@GWSTS@_STROFF) and 0FFh)  ;Special check for STRIG(x)
	JNZ	@GWSTS@_ONFUN1  ;Brif not
	INC	AL  ;Restore STRIG #
	ROR	AL,1  ;Divide by 2 so get 0,1,2 or 3
@GWSTS@_ONFUN1:
	CMP	AL,CL  ;Value [AL] .gt. MAX [CL]?
	JNB	@GWSTS@_FCERR2  ;If so, then Ill fun error.
	MOV	CL,AL  ;Save Event index in [CL]
@GWSTS@_ONSTM:
	ADD	CH,CL  ;[CH]=event-id
	MOV	CL,((1) and 0FFh)  ;[CL]=maximum number of line#'s in gosub
	POP	DX  ;discard saved text pointer
	DEC	BX  ;backup for CHRGET
	OR	AL,AL  ;clear carry - indicates it was event
@GWSTS@_ONGOTX:	MOV	AL,byte [BX+0]  ;Restore Token
	RET

@GWSTS@_GETSUB:	PUSH	CX
	CALL	@CHRGTR  ;skip current token
@GWSTS@_GETSU2:	CALL	@SYNCHR
	DB	"("
	CALL	@GETBYT  ;get event-class index
	PUSH	AX  ;save it
	CALL	@SYNCHR
	DB	")"
	POP	AX
	POP	CX
	RET

;Set gosub entry
; Entry - [AL]=trap id, [DX]=line pointer
; Exit  - [AX], [FLAGS] used, All other registers preserved.

@SETGSB:	PUSH	SI
	PUSH	DX  ;save gosub line pointer
	CALL	@GWSTS@_EVADR  ;[DX] points to event flag
	MOV	SI,DX  ;[SI] points to event flags
	POP	DX  ;restore GOSUB line pointer
	INC	SI  ;[SI] points to gosub line ptr entry
	MOV	word [SI+0],DX  ;put trap adr in table for this entry
	POP	SI
	RET

;EVTRP is called to signal that an event has occured.
; Entry - [AL] = event id
; Exit  - If NZ, the event is not being trapped (not ON)
;         AX is used.  All other registers are preserved.

@GWSTS@_EVTRP:	PUSH	DX
	PUSH	CX
	PUSH	BX
	MOV	BX,word [@CURLIN]
	INC	BX
	JZ	@GWSTS@_NOT_ON  ;branch if in direct mode (no event trapping)
	CALL	@GWSTS@_EVADR  ;[DX] points to event flag
	MOV	BX,DX  ;[BX] points to event flag
	MOV	AL,byte [BX+0]  ;[AL]=event flag
	AND	AL,((@T_ON) and 0FFh)  ;NZ if trapping enabled for key
	JZ	@GWSTS@_NOT_ON  ;branch if event is not on
	PUSHF
	CALL	@REQTRP  ;Trap enabled, Issue Request
	POPF
@GWSTS@_NOT_ON:	POP	BX
	POP	CX
	POP	DX
	RET

;EVCLR is called to reset an event
; Entry - [AL] = event id
; Exit  - Flags, AX are used.  All other registers are preserved.

@GWSTS@_EVCLR:	PUSH	DX
	PUSH	CX
	PUSH	BX
	CALL	@GWSTS@_EVADR  ;[DX] points to event flag
	MOV	BX,DX  ;[BX] points to event flag
	CALL	@FRETRP  ;Reset Trap Request
	JMP	@GWSTS@_NOT_ON

;TSTCEV is called to Test-and-Clear an event.
; Entry - [AL] = 0-relative event index
; Exit  - [BX] = -1 if event had occured
;              =  0 if event had not occured
;         bit T.REQ of TRPTBL+3*index is cleared

@GWSTS@_TSTCEV:
	CALL	@GWSTS@_EVADR  ;[DX] [points to event flag
	MOV	BX,DX  ;[BX] points to event flag
	MOV	AL,byte [BX+0]  ;[AL] = current event state
	PUSH	AX
	CALL	@FRETRP  ;Reset Trap Request (clear T.REQ)
	POP	AX
	XOR	BX,BX  ;prepare to return negative result
	AND	AL,((@T_REQ) and 0FFh)
	JE	@GWSTS@_TSTEVX
	DEC	BX  ;[BX]=-1 (indicates event has occured)
@GWSTS@_TSTEVX:	RET

; SUBTTL COM Statement and Event Trapping

; PUBLIC	COMS
; PUBLIC	COMTRP

;COM statement

@COMS:	MOV	CX,(256*@GWSTS@_COMOFF)+@NMCOMT
	JMP	@GWSTS@_SEVSTT  ;branch to common code

;COMTRP is called by COM interrupt service routine to signal trapping.
; Entry - [AL]=0-relative com channel id.
; Exit  - NZ is true if key trapping is enabled.
;         All other regs preserved.

@COMTRP:	PUSH	AX
	ADD	AL,((@GWSTS@_COMOFF) and 0FFh)  ;[AL]=event id
	CALL	@GWSTS@_EVTRP  ;Signal the occurance of a COM EVENT
	POP	AX
	RET

; SUBTTL SOFT KEY Statement and Event Trapping

; PUBLIC	KEYS
; EXTRN	LINPRT:NEAR,OUTDO:NEAR
end if
; EXTRN	$ON:WORD,$OFF:WORD,$LIST:WORD
; EXTRN	STRTAB:WORD,KEYSW:WORD,FKCNUM:WORD
if @GW_PASS = 1
; EXTRN	SCROUT:NEAR,CLREOL:NEAR
; PUBLIC	KEYTRP
; EXTRN	MAKINT:NEAR

;SET KEY STATUS - KEY(n) (status)

@GWSTS@_KEYSTT:	MOV	CX,(256*@GWSTS@_KEYOFF)+@NMKEYT
	JMP	@GWSTS@_SEVSTT  ;branch to common code

;KEYTRP is called whenever CHGET receives a SOFTKEY from the keyboard.
; Entry - [AL] = Soft key id (0..NMKEYT-1)
; Exit  - If NZ, key was trapped and should not be expanded.
;         Otherwise, CHGET should expand key.
;         All other registers are preserved.

@KEYTRP:	PUSH	AX
	ADD	AL,((@GWSTS@_KEYOFF) and 0FFh)  ;[AL] = 0-relative event id
	CALL	@GWSTS@_EVTRP  ;Signal the occurance of a KEY EVENT
	POP	AX
	RET

; EXTRN	FKYADV:NEAR

;KEY Statement

@KEYS:
	CMP	AL,(("(") and 0FFh)
	JZ	@GWSTS@_KEYSTT  ;set key status
	CMP	AL,((@@SON) and 0FFh)
	JZ	@GWSTS@_KEYON  ;Brif Enable Soft Key Display Line.
	CMP	AL,((@@SOFF) and 0FFh)
	JZ	@GWSTS@_KEYOF  ;Brif Disable Soft Key Display line.
	CMP	AL,((@@SLIST) and 0FFh)
	JZ	@GWSTS@_KEYLSI  ;Brif LIST Soft Keys.
	CALL	@GETBYT  ; else Key defn, get key number.
	OR	AL,AL
	JZ	@GWSTS@_KEYFCE
	SUB	AL,((@GWSTS@_STKEYF) and 0FFh)  ;Get zero relative key number
	CMP	AL,((@NMKEYF) and 0FFh)
	JNB	@GWSTS@_KEYFCE  ;Must be STKEYF - NMKEYF+STKEYF, else error.
	MOV	DX,16
	MUL	DL  ; (16 * Key number).
	MOV	DX,AX
	ADD	DX,@STRTAB  ;Index into Soft Key table
	PUSH	DX  ;Save addr
	CALL	@SYNCHR
	DB	","
	CALL	@FRMEVL
	PUSH	BX  ;Save Text pntr.
	CALL	@FRESTR  ;Get String Descriptor
	MOV	CL,byte [BX+0]
	CMP	CL,((15) and 0FFh)
	JB	@GWSTS@_KEY1
	MOV	CL,((15) and 0FFh)  ;String may be 0 to 15 chars.
@GWSTS@_KEY1:
	INC	BX
	MOV	SI,word [BX+0]  ;Get addr of string
	POP	BX  ;Text pntr
	POP	DI  ;STRTAB addr
	PUSH	BX
	MOV	CH,((0) and 0FFh)
	CLD
;Move new softkey
 REP	MOVSB  ;to Softkey table
	MOV	byte [DI+0],CH  ;Terminate entry with 0.
	MOV	AL,byte [@KEYSW]  ;Are the key definitions being
	OR	AL,AL  ;displayed?
	JZ	@GWSTS@_NODSPK  ;No, don't call DSPKEY since it would
;erase the bottom line of the screen.
	CALL	@KEYDSP  ;Yes, update the display.
@GWSTS@_NODSPK:	POP	BX  ;Text pntr
	RET
@GWSTS@_KEYFCE:
	JMP	@FCERR  ;complain..
@GWSTS@_KEYLSI:	JMP	@GWSTS@_KEYLST

@GWSTS@_KEYON:	CALL	@SKEYON
	JMP	@GWSTS@_KEYOXX  ;non-zero = ON

@GWSTS@_KEYOF:	MOV	AH,((1) and 0FFh)  ;Prepare to inc scroll limit
	MOV	AL,((0) and 0FFh)  ;zero = OFF
	CALL	@GWSTS@_KEYOX
@GWSTS@_KEYOXX:	CALL	@CHRGTR  ;over ON/OFF token.
	RET

; PUBLIC	SKEYON
@SKEYON:	MOV	AH,((-1) and 0FFh)  ;Prepare to dec scroll limit
	MOV	AL,((255) and 0FFh)
@GWSTS@_KEYOX:  ;AH=scroll limit diff., AL=new KEYSW
	CMP	AL,byte [@KEYSW]  ;State change?
	MOV	byte [@KEYSW],AL
	JZ	@GWSTS@_KEYXX  ;Brif same, do nothing
	CMP	byte [@KEYSW],((255) and 0FFh)  ;Test if change to ON
	JNZ	@GWSTS@_KEYOX1  ;Change is to OFF - do not call FKYADV
	CALL	@FKYADV
@GWSTS@_KEYOX1:
	CALL	@KEYDSP  ;On, Display on 25th line.
@GWSTS@_KEYXX:	RET

;List Function Keys

@GWSTS@_KEYLST:
	PUSH	BX
	MOV	SI,@STRTAB  ;List 10 Special Function
	MOV	CX,@NMKEYF+(@GWSTS@_STKEYF*256)
@GWSTS@_KEYLS0:
	PUSH	SI
	MOV	AL,(("F") and 0FFh)
	CALL	@OUTDO
	PUSH	CX
	MOV	BL,CH
	MOV	BH,((0) and 0FFh)
	CALL	@LINPRT  ;Display the Key number.
	MOV	AL,((" ") and 0FFh)
	CALL	@OUTDO
	POP	CX
	POP	SI
	PUSH	SI
	PUSH	CX
@GWSTS@_KEYLS1:
	CLD
	LODSB
	OR	AL,AL
	JZ	@GWSTS@_KEYLS2  ;Brif end of String.
	CALL	@GWSTS@_KEYLSP
	JMP	@GWSTS@_KEYLS1
@GWSTS@_KEYLS2:
	MOV	AL,((13) and 0FFh)  ;Output carriage return
	CALL	@OUTDO
	MOV	AL,((10) and 0FFh)  ;Output a line feed
	CALL	@OUTDO
	POP	CX
	POP	SI
	ADD	SI,16  ;Next key address
	INC	CH  ;Next key number
	DEC	CL
	JNZ	@GWSTS@_KEYLS0
	POP	BX
	JMP	@GWSTS@_KEYOXX

@GWSTS@_KEYLSP:
	PUSH	SI
	CMP	AL,((13) and 0FFh)  ;check for Carriage-Return
	JNZ	@GWSTS@_KEYLSQ
	MOV	AL,((27) and 0FFh)
@GWSTS@_KEYLSQ:	CALL	@OUTDO
	POP	SI
	RET
; SUBTTL  KEYON,  KEYOFF, and KEYDSP

; PUBLIC	KEYDSP,TKEYOF
; EXTRN	FKYFMT:NEAR
end if
; EXTRN	FKCNUM:WORD
if @GW_PASS = 1

;TKEYOF is called to turn function key display off

@TKEYOF:	MOV	byte [@KEYSW],((0) and 0FFh)  ;turn function key display switch off

; KEYDSP -      Display Softkeys on last line of Screen.

	@GWSTS@_REVNMS=1  ;Key Numbers are normal video, contents are rev-video
@KEYDSP:	PUSH	DX
	MOV	DH,((1) and 0FFh)  ;Set for col = 1
	MOV	DL,byte [@LINCNT]  ;Set for last line
	MOV	AL,byte [@KEYSW]
	OR	AL,AL  ;Key on or off?
	JNZ	@GWSTS@_KEYDS0  ;Softkey display switch on
	CALL	@CLREOL  ;Clear from (DH,DL) to EOL
	POP	DX
	RET

@GWSTS@_KEYDS0:
; EXTRN	SETCSR:NEAR
	MOV	byte [@CSRTYP],((0) and 0FFh)  ;Set off mode cursor
	CALL	@SETCSR  ;Turn the cursor off
	PUSH	BX
@GWSTS@_KEYDS1:	CALL	@GWSTS@_GETFMT  ;Get function key display format
@GWSTS@_KNXTST:	PUSH	AX  ;Save Key disp no.
	CMP	AH,(("0") and 0FFh)  ;Single digit case?
	JZ	@GWSTS@_SINDIG  ;Print only one digit
	XCHG	AH,AL
	CALL	@GWSTS@_KEYDCH  ;Display first digit
	XCHG	AH,AL
@GWSTS@_SINDIG:	CALL	@GWSTS@_KEYDCH  ;Display last digit
	PUSH	SI
	MOV	CL,byte [@FKCNUM]  ;Count of chars per fun. key (set by GETFMT
	CALL	@GWSTS@_XFGBG  ;Swap Forground & background colors
@GWSTS@_KNXTCH:  ;Write the next key character
	PUSH	CX
	CLD
	LODSB
	OR	AL,AL  ;End of string?
	PUSHF
	PUSH	SI
	JNZ	@GWSTS@_KEYDS4  ;No, Display char
	XOR	AL,AL  ;else blank
@GWSTS@_KEYDS4:
	CALL	@GWSTS@_KEYDCH  ;Display char, adv cursor
	POP	SI
	POPF
	JNZ	@GWSTS@_KEYDS5  ;Brif not EOS
	DEC	SI
@GWSTS@_KEYDS5:
	POP	CX
	DEC	CL
	JNZ	@GWSTS@_KNXTCH  ;Loop for next character
	CALL	@GWSTS@_XFGBG  ;Swap Forground & background colors
	CALL	@GWSTS@_KEYDB  ;Follow with blank
	POP	SI
	POP	AX
	CALL	@GWSTS@_KEYADV  ;Advance to next key
	DEC	CH
	JNZ	@GWSTS@_KNXTST  ;Loop for next key string
@GWSTS@_KEYDSX:	POP	BX  ;Retrieve cursor position
	POP	DX
	MOV	byte [@CSRTYP],((3) and 0FFh)  ;Set user mode cursor
	CALL	@SETCSR  ;Turn on cursor
	RET

@GWSTS@_KEYDB:	XOR	AL,AL  ;For Blank at end of Key field
@GWSTS@_KEYDCH:
	PUSH	AX
	PUSH	BX
	OR	AL,AL  ;Separating keys?
	JNZ	@GWSTS@_KEYDC1  ;Brif not.
	MOV	AL,((" ") and 0FFh)  ;else write space
@GWSTS@_KEYDC1:	CMP	AL,((@GWSTS@_CR) and 0FFh)  ;CR?
	JNZ	@GWSTS@_KEYNCR  ;Not CR.
	MOV	AL,((@GWSTS@_FKEYCR) and 0FFh)  ;Subs Greater-Than-Sign
@GWSTS@_KEYNCR:	CMP	AL,((@GWSTS@_LF) and 0FFh)  ;Line feed?
	JNZ	@GWSTS@_KEYNLF  ;Not line feed
	MOV	AL,((60) and 0FFh)  ;Substitute Greater-Than-Sign
@GWSTS@_KEYNLF:	PUSH	CX
	MOV	AH,((0) and 0FFh)
	CALL	@SCROUT  ;Write the character at (DH,DL)
	INC	DH
	POP	CX
	POP	BX
	POP	AX  ;Restore key number
	RET
;Get function key display format

@GWSTS@_GETFMT:	PUSH	BX
	CALL	@FKYFMT  ;OEM routine
	MOV	CX,word [BX+0]  ;CH=key count, CL=Chrs/key
	PUSH	CX
	MOV	byte [@FKCNUM],CL
	MOV	SI,@STRTAB  ;SI=address of first fkey in table
	MOV	AL,byte [BX+2]
	CBW
	PUSH	AX  ;Save number of first function key
	DEC	AL  ;Set to zero relative
	MOV	CL,((4) and 0FFh)  ;Multiply by 16 (bytes/key)
	SHL	AX,CL  ;AX = index of first display key
	ADD	SI,AX
	POP	AX
	CALL	@GWSTS@_INTOCH  ;Get key number to character code
	CMP	AH,(("0") and 0FFh)
	JZ	@GWSTS@_ONEDIG  ;Only one digit
	DEC	byte [@FKCNUM]  ;Adjust function key format for two digits
@GWSTS@_ONEDIG:	CALL	@GWSTS@_KADNRM  ;Normalize key address
	POP	CX
	POP	BX
	RET
;INTOCH: Translate integer AL to characters in AX.
;        Integers must be in the range (100,0].
;        Radix is 10.
;USES -  none

@GWSTS@_INTOCH:	PUSH	CX
	XOR	AH,AH
	MOV	CL,((10) and 0FFh)  ;Load radix
	DIV	CL
	ADD	AX,12336  ;3030H forms character codes
	XCHG	AH,AL  ;AH represents significant digit
	POP	CX
	RET
;KEYADV - Advance to next key
;Entry - AX = key number characters
;        SI = index into STRTAB (key code table)

@GWSTS@_KEYADV:	ADD	SI,16  ;Move to next key table entry
	INC	AL
	CMP	AL,(("9") and 0FFh)
	JLE	@GWSTS@_KADNRM
	MOV	AL,(("0") and 0FFh)
@GWSTS@_KADNRM:
	CMP	SI,@STRTAB+@NMKEYF*16
	JB	@GWSTS@_KADNMX
	MOV	SI,@STRTAB  ;Wrap around to the first function key
;Print function key 10 number as 0
; except when it is the first key
	CMP	AH,(("1") and 0FFh)  ;Only true if 1st function key is key 10
	JNZ	@GWSTS@_KADNMX  ; all other wraps are for 1 digit only
	MOV	AH,(("0") and 0FFh)
	MOV	AL,(("1") and 0FFh)
	INC	byte [@FKCNUM]  ;Re-adjust format
@GWSTS@_KADNMX:	RET
; SUBTTL  Swap Forground & Background Colors

;Swap Forground & Background Colors (Toggle Reverse Video Mode)

; EXTRN	GETFBC:NEAR,SETFBC:NEAR

@GWSTS@_XFGBG:	CLC  ;Signal text attributes
	CALL	@GETFBC  ;Get forground/background attributes
	XCHG	AX,BX
	CALL	@SETFBC  ;Set forground/background attributes
	RET
; SUBTTL PEN Statement and Event Trapping

; PUBLIC	PENS,PENF
; EXTRN	MAKINT:NEAR

; Dispatch PEN statement depending upon following clauses:

; PEN   ON      Enable  PEN Trapping.
; PEN   OFF     Disable PEN Trapping.
; PEN   STOP    Suspend PEN Trapping.

;               Attempts to read Light pen when off
;               result in "Illegal Function Call" Error.

@PENS:
	JZ	@GWSTS@_SNERR2  ;Syntax error if end-of-statement
	PUSH	AX  ;save $ON/$OFF/$STOP
	CALL	@GWSTS@_EOSCH1  ;Syntax Error if not End-Of-Statement
	MOV	DX,@TRPTBL+(3*@GWSTS@_PENOFF)  ;[DX]=adr of event flag
	POP	AX  ;[AL]=$ON, $OFF, or $STOP
	CMP	AL,((@@SSTOP) and 0FFh)
	JE	@GWSTS@_NTONOF  ;branch if not ON/OFF
	PUSH	AX
	SUB	AL,((@@SON) and 0FFh)
	JE	@GWSTS@_PENS1  ;branch if "PEN ON"
	MOV	AL,((1) and 0FFh)  ;better be OFF
@GWSTS@_PENS1:	SUB	AL,((2) and 0FFh)  ;Map (ON, OFF) to (254, 255)
	PUSH	BX  ;preserve text pointer (destroyed by RDPEN)
	CALL	@RDPEN  ;enable/disable light pen interrupts
	POP	BX
	POP	AX  ;restore [AL] = $ON/$OFF
@GWSTS@_NTONOF:
	JMP	@GWSTS@_SET1EV  ;Set Event Flag

@GWSTS@_SNERR2:	JMP	@SNERR
@GWSTS@_FCERR3:	JMP	@FCERR

;PEN Function:
; Syntax: x=PEN(n)
;         n=0: Return -1 if pen was down since last poll, else 0.
;         n=1: Return X Graphics Coordinate where pen was last activated.
;         n=2: Return Y Graphics Coordinate where pen was last activated.
;         n=3: Return -1 if pen is currently down, 0 if currently up.
;         n=4: Return last known valid X Graphics Coordinate.
;         n=5: Return last known valid Y Graphics Coordinate.
;         n=6: Return character row where pen was last activated.
;         n=7: Return character column where pen was last activated.
;         n=8: Return last known character row.
;         n=9: Return last known character column.

; EXTRN	RDPEN:NEAR
@PENF:
	CALL	@GWSTS@_ONESUB  ;[AL] = pen function
	PUSH	BX  ;save text pointer
	CMP	AL,((10) and 0FFh)
	JB	@GWSTS@_PENOK
	JMP	@GWSTS@_FCERR3  ;Error if Parm exceeds 9
@GWSTS@_PENOK:
	OR	AL,AL
	JNE	@GWSTS@_NPEN0  ;branch if not PEN(0)

;Whenever a PEN interrupt occurs, it is detected by POLPEN (called by CHKINT).
; PEN(0) tells whether a PEN event has occured since the last PEN(0).
; It determines this by testing-and-clearing the bit set by POLPEN.
; NOTE: PEN(0) always returns false when event trapping has been enabled
;       (by PEN ON statement)

	MOV	AL,((@GWSTS@_PENOFF) and 0FFh)
	CALL	@GWSTS@_TSTCEV  ;test and clear event [AL]
	JMP	@GWSTS@_PENRET  ;return -1 in BX if event has occured
@GWSTS@_NPEN0:
	CALL	@RDPEN
@GWSTS@_PENRET:	CALL	@MAKINT  ;Return [BX] as signed integer
	POP	BX  ;restore text pointer
	RET

;POLPEN is called by CHKINT at beginning of every BASIC statement (NEWSTT).
; If a PEN interrupt has occured, it sets the appropriate bit in TRPTBL
; which will cause the BASIC program's pen service routine (ON PEN GOSUB)
; to be invoked.
; Exit - AX, BX, CX, DX can be used (restored by CHKINT).
;        All other registers are preserved.

@GWSTS@_POLPEN:
	XOR	AL,AL  ;See if lightpen has interrupted
	CALL	@RDPEN
	OR	BX,BX
	JE	@GWSTS@_NOPENI  ;branch if no lightpen interrupt
	MOV	AL,((@GWSTS@_PENOFF) and 0FFh)
	CALL	@GWSTS@_EVTRP  ;Signal the occurance of a PEN EVENT
@GWSTS@_NOPENI:	RET
;Parse "(n)" and return n in [AL]
@GWSTS@_ONESUB:
;In non-IBMTOK versions, EVAL doesn't parse the argument
; EXTRN	INTFR2:NEAR
	PUSH	DX
	CALL	@INTFR2  ;[DX] = function to be performed (argument)
	JNE	@GWSTS@_FCERRI  ;branch if [DX] is not [0..255]
	MOV	AL,DL  ;return argument in [AL]
	POP	DX  ;restore caller's [DX]
	RET
; SUBTTL STRIG Statement and Event Trapping

; PUBLIC	STRIGS,STRIGF,STICKF
; EXTRN	RDSTIK:NEAR,RDTRIG:NEAR

;STRIG statement

; Syntax:

;   In IBM BASIC, STRIG ON enables trigger trapping while STRIG OFF
;     disables trigger event trapping.
;   It is parsed in GW-BASIC for syntax compatibility only.

;   STRIG(n)      ON      Enable  STRIG(n) Trapping.
;   STRIG(n)      OFF     Disable STRIG(n) Trapping.
;   STRIG(n)      STOP    Suspend STRIG(n) Trapping.

;       WHERE:
;               (n) is Trigger 0 for joystick trigger #1,
;                              2 for joystick trigger #2,
;                              4 for joystick trigger #3, etc.

@STRIGS:
	CMP	AL,(("(") and 0FFh)
	JNE	@GWSTS@_STRIG1  ;branch if STRIG ON or STRIG OFF
	MOV	CX,(256*@GWSTS@_STROFF)+@NMSTRT
	JMP	@GWSTS@_SEVSTT  ;branch to common code
@GWSTS@_STRIG1:
	CMP	AL,((@@SON) and 0FFh)
	JE	@GWSTS@_STROK
	CMP	AL,((@@SOFF) and 0FFh)
	JE	@GWSTS@_STROK
	JMP	@SNERR  ;SYNTAX ERROR if not $ON or $OFF or (n)
@GWSTS@_STROK:	JMP	@GWSTS@_EOSCH1  ;SYNTAX ERROR if not end-of-statement

;STRIG Function:

; Syntax:

;  x=STRIG(n)
;    n=0: return -1 if button 1 was pressed since last STRIG(0), else 0.
;    n=1: return -1 if button 1 is currently pressed, else 0.
;    n=2: return -1 if button 2 was pressed since last STRIG(0), else 0.
;    n=3: return -1 if button 2 is currently pressed, else 0.
;         etc.

@STRIGF:
	CALL	@GWSTS@_ONESUB  ;Parse "(n)", [AL] = n
	PUSH	BX  ;save text pointer
	MOV	AH,AL  ;Map AL to AH: (0,1,2,...) to (1,0,1,...)
	INC	AH
	AND	AH,((1) and 0FFh)  ;[AH] = 1 for latched, 0 for current
	SHR	AL,1  ;[AL] = 0 relative joystick trigger id
	CMP	AL,((@NMSTRT) and 0FFh)
	JB	@GWSTS@_STRGOK
@GWSTS@_FCERRI:	JMP	@FCERR  ;branch if illegal trigger id
@GWSTS@_STRGOK:
	OR	AH,AH
	JE	@GWSTS@_NSTR0  ;brif current (not latched) was requested
	PUSH	AX
	ADD	AL,((@GWSTS@_STROFF) and 0FFh)  ;see if STRIG(n) ON has been executed
	CALL	@GWSTS@_EVADR  ;if not, POLSTR will not call RDTRIG for
	MOV	BX,DX  ; this trigger, so we must call it directly
	TEST	byte [BX+0],((@T_ON) and 0FFh)
	POP	AX
	JE	@GWSTS@_NSTR0  ;branch if event is not enabled

;Whenever a STRIG interrupt occurs, it is detected by POLSTR (called by CHKINT).
; STRIG(0) tells whether a STRIG event has occured since the last STRIG(0).
; It determines this by testing-and-clearing the bit set by POLSTR.
; NOTE: STRIG(0) always returns false when event trapping has been enabled
;       (by STRIG(n) ON statement)

	ADD	AL,((@GWSTS@_STROFF) and 0FFh)  ;[AL]=0 relative event index
	CALL	@GWSTS@_TSTCEV  ;test and clear event [AL]
	JMP	@GWSTS@_STRRET  ;return -1 in BX if event has occured
@GWSTS@_NSTR0:	CALL	@RDTRIG  ;[AL] = 0/1 for not-pressed/pressed
	CBW  ;[AX] = 0/1 for not-pressed/pressed
	NEG	AX  ;[AX] = 0/-1 for not-pressed/pressed
	MOV	BX,AX
@GWSTS@_STRRET:	CALL	@MAKINT  ;return [BX] as signed integer
	POP	BX  ;restore text pointer
	RET

;STICK Function:

; Syntax:

;  x=STICK(n)
;    n=0:    return x coordinate for joystick 1.
;    n=1:    return y coordinate for joystick 1.
;    n=2:    return x coordinate for joystick 2.
;    n=3:    return y coordinate for joystick 2.
;            etc.

@STICKF:
	CALL	@GWSTS@_ONESUB  ;AL=stick id
	PUSH	BX  ;save text pointer
	CALL	@RDSTIK  ;[BX] = stick coordinate
	JAE	@GWSTS@_STKOK
	JMP	@FCERR  ;branch if bad parameter
@GWSTS@_STKOK:
	CALL	@MAKINT  ;return [BX] as signed integer
	POP	BX  ;restore text pointer
	RET

;POLSTR is called by CHKINT at beginning of every BASIC statement (NEWSTT).
; If a STRIG interrupt has occured, it sets the appropriate bit in TRPTBL
; which will cause the BASIC program's pen service routine (ON STRIG(N) GOSUB)
; to be invoked.
; Exit - AX, BX, CX, DX can be used (restored by CHKINT).
;        All other registers are preserved.

@GWSTS@_POLSTR:
	XOR	AX,AX  ;[AL] = joystick trigger #0 (for RDTRIG)
	INC	AH  ;[AH] = latched (not current) flag
@GWSTS@_STRILP:
	PUSH	AX  ;save current trigger id
	ADD	AL,((@GWSTS@_STROFF) and 0FFh)
	CALL	@GWSTS@_EVADR  ;[DX] points to event mask
	MOV	BX,DX  ;[BX] points to event mask
	TEST	byte [BX+0],((@T_ON) and 0FFh)  ;see if STRIG(n) ON has been done
	POP	AX
	PUSH	AX
	JE	@GWSTS@_STRI1  ;don't call RDTRIG if event not enabled
	CALL	@RDTRIG  ;[AL]=0/1 if trig is not-pressed/pressed
	OR	AL,AL
	JE	@GWSTS@_STRI1  ;brif this trigger has not interrupted
	POP	AX  ;restore [AL] = joystick trigger id
	PUSH	AX
	ADD	AL,((@GWSTS@_STROFF) and 0FFh)  ;[AL] = global event id
	CALL	@GWSTS@_EVTRP  ;Signal the occurance of a TRIGGER EVENT
@GWSTS@_STRI1:	POP	AX
	INC	AL
	CMP	AL,((@NMSTRT) and 0FFh)
	JB	@GWSTS@_STRILP  ;brif there are more triggers to poll
	RET

; SUBTTL DATE - Get/Set Date.

; PUBLIC	DATES,DATEF
end if
; EXTRN	DAYSPM:WORD
if @GW_PASS = 1

;DATE$="[M]M/[D]D/[YY]YY" or "[M]M-[D]D-[YY]YY"USA Date format

@DATES:	CALL	@GWSTS@_PRSDAT  ;CX=year, DH=month, DL=day
	JMP	@GWSTS@_SETDAT  ;set system date

;X$=DATE$ returns "YYYY-MM-DD" if KANABS&KANADT else "MM-DD-YYYY"

@DATEF:
	CALL	@CHRGTR  ;skip DATE$
	PUSH	BX  ;Save Text pointer
	MOV	AL,((10) and 0FFh)
	CALL	@STRINI  ;Get space for 10 char string
	PUSH	DX  ;save adr of string
	CALL	@GWSTS@_GETDAT  ;CX=year, DH=month, DL=day
	POP	BX  ;[BX]=adr of string
	SUB	CX,1900  ;Reduce year by two digits
	CMP	CL,((100) and 0FFh)  ;See if in 20th century
	MOV	CH,((19) and 0FFh)  ;Setup 20th century in case
	JB	@GWSTS@_DATEF2  ;Brif so.
	SUB	CL,((100) and 0FFh)  ;subtract into next century
	INC	CH  ;21st century
@GWSTS@_DATEF2:
	MOV	AL,DH
	CALL	@GWSTS@_PUTCHR  ;Store ascii month
	MOV	AL,(("-") and 0FFh)
	CALL	@GWSTS@_PUTCH2  ;put separater
	MOV	AL,DL
	CALL	@GWSTS@_PUTCHR  ;Store ascii day
	MOV	AL,(("-") and 0FFh)
	CALL	@GWSTS@_PUTCH2  ;put separater
	MOV	AL,CH
	CALL	@GWSTS@_PUTCHR  ;Store ascii century
	MOV	AL,CL
	CALL	@GWSTS@_PUTCHR  ;Store ascii year.
	JMP	@PUTNEW  ;Put result and ret (Txt ptr on stack).

@GWSTS@_PUTCHR:
	AAM  ;Convert to unpacked BCD
	XCHG	AL,AH
	OR	AX,12336  ;Add "0" bias to both digits.
	CALL	@GWSTS@_PUTCH2
	MOV	AL,AH
@GWSTS@_PUTCH2:
	MOV	byte [BX+0],AL  ;store char in string
	INC	BX
	RET

;PRSDAT parses a string containing
;   "[YY]YY/MM/DD" if KANABS&KANADT else "MM/DD/[YY]YY"
; Exit - CX=year, DH=month, DL=day,
;         [BX]=new text pointer.  All other regs preserved.

@GWSTS@_PRSDAT:
	CALL	@SYNCHR
	DB	@EQULTK  ;Must be DATE$ = string
	CALL	@FRMEVL
	PUSH	BX  ;Save Text pointer
	CALL	@FRESTR
	MOV	CL,byte [BX+0]  ;Save string len in [CL]
	CMP	CL,((1) and 0FFh)  ;String must not be null
	JB	@GWSTS@_DATERR  ;Brif null str
	MOV	SI,word [BX+1]  ;[SI] has addr of string.
	MOV	BL,CL  ;Working reg for string len.
	CALL	@GWSTS@_GNUM8  ;[AX]=month
	MOV	DH,AL  ;[DH] = month
	CALL	@GWSTS@_DATSEP  ;skip / or -
	CALL	@GWSTS@_GNUM8  ;[AL]=day of month
	MOV	DL,AL  ;[DL] = day
	CALL	@GWSTS@_DATSEP  ;skip / or -
	CALL	@GWSTS@_GNUM16  ;[AX]=year (16 BITS)
	CMP	AX,1978
	JNB	@GWSTS@_DATE2  ;branch if .GE. 1978
	CMP	AX,100
	JNB	@GWSTS@_DATERR  ;error if between 100 and 1977
	CMP	AX,78
	JNB	@GWSTS@_DATE1  ;add 1900 if .GE. 78
	ADD	AX,100  ;add 2000 if .LE. 77
@GWSTS@_DATE1:	ADD	AX,1900
@GWSTS@_DATE2:
	CMP	AX,2100
	JNB	@GWSTS@_DATERR  ;branch if year too large
	MOV	CX,AX  ;CX=year
	POP	BX  ;Text pointer
	RET  ;Exit.

;DATSEP checks for a date separator (- or /) and returns if found.

@GWSTS@_DATSEP:
	OR	BL,BL
	JZ	@GWSTS@_DATERR  ;Error if string empty.
	MOV	AL,byte [SI+0]
	CMP	AL,(("/") and 0FFh)
	JZ	@GWSTS@_DIGITX
	CMP	AL,(("-") and 0FFh)
	JZ	@GWSTS@_DIGITX  ;branch if found
	JMP	@GWSTS@_DATERR

@GWSTS@_GNUM8:	CALL	@GWSTS@_GNUM16  ;[AX]=16-bit number
	OR	AH,AH
	JNZ	@GWSTS@_DATERR  ;error if larger than 255
	RET

@GWSTS@_GNUM16:	PUSH	CX  ;save caller's [CX], [DX]
	PUSH	DX
	MOV	AX,0  ;initialize accumulator
@GWSTS@_GNUML:	CALL	@GWSTS@_DIGIT  ;[CX]=0..9
	JB	@GWSTS@_GNUMX  ;branch if not legal digit
	MOV	DX,10
	MUL	DX  ;[AX]=[AX]*10
	JO	@GWSTS@_DATERR  ;branch if overflow
	ADD	AX,CX  ;add in new digit
	JMP	@GWSTS@_GNUML
@GWSTS@_GNUMX:	POP	DX
	POP	CX
@GWSTS@_RET2:	RET

@GWSTS@_DIGIT:	CMP	BL,((1) and 0FFh)  ;End-of-string?
	JB	@GWSTS@_RET2  ;Brif END-OF-STRING
	MOV	CL,byte [SI+0]
	SUB	CL,(("0") and 0FFh)
	JB	@GWSTS@_RET2  ;branch if illegal digit
	CMP	CL,((10) and 0FFh)
	CMC
	JB	@GWSTS@_RET2  ;branch if illegal digit
	MOV	CH,((0) and 0FFh)  ;[CX]=digit
@GWSTS@_DIGITX:	DEC	BL  ;Length -1
	INC	SI  ;[SI] points to next byte in string
	RET

@GWSTS@_DATERR:	JMP	@FCERR

if (@IBMTOK OR @CPM86) = 0
;DYOFYR converts YEAR, MONTH, DAY to binary DAY-OF-YEAR
; Entry - [CX]=binary year (19xx/20xx)
;         [DH]=binary month (1..12)
;         [DL]=binary day-of-month (1..31)
; Exit  - [BX]=binary day of year (0..364/365)
;         [CX] is preserved, all other registers are destroyed.

@GWSTS@_DYOFYR:	SUB	CX,1978  ;[CX]=year - 1978
	DEC	DL  ;[DL]=day of month - 1
	DEC	DH  ;[DH]=month - 1
	MOV	BL,DL
	XOR	BH,BH  ;[BX]=day accumulator=day-of-month - 1
	MOV	AH,BH
	MOV	AL,DH  ;[AX]=month - 1
	MOV	SI,AX  ;[SI]=month - 1
	CALL	@GWSTS@_SETFEB  ;DAYSPM(2)=28 or 29
	CMP	DH,((12) and 0FFh)
	JNB	@GWSTS@_DATERR  ;error if month is too large
	CMP	DL,byte [@DAYSPM+SI]
	JNB	@GWSTS@_DATERR  ;error if day-of-month too large
	OR	SI,SI
@GWSTS@_MONTHL:	JNZ	@GWSTS@_MONTHS
	RET
@GWSTS@_MONTHS:	MOV	AL,byte [@DAYSPM-1+SI]
	ADD	BX,AX  ;days=days+DAYSPM(month)
	DEC	SI
	JMP	@GWSTS@_MONTHL

;SETFEB sets DAYSPM(2) to 28 or 29 depending on year

@GWSTS@_SETFEB:	CALL	@GWSTS@_CKLEAP  ;[AX]=1 if [CX]=leap-year
	ADD	AL,((28) and 0FFh)  ;[AL]=29 if leap, 28 if not
	MOV	byte [@DAYSPM+1],AL  ;DAYSPM(2)=28 or 29
	RET

;CKLEAP returns with [AX]=1 if [CX]+1978 is a leap year, else [AX]=0.

@GWSTS@_CKLEAP:	MOV	AH,((0) and 0FFh)
	MOV	AL,CL
	AND	AL,((3) and 0FFh)
	SUB	AL,((2) and 0FFh)  ;[AX]=0 if leap year
	JZ	@GWSTS@_CKLEA1  ;branch if it is leap-year
	MOV	AL,((255) and 0FFh)
@GWSTS@_CKLEA1:	INC	AL
	RET
end if

if @CPM86
;SETDAT sets the system clock's date.
; Entry - [CX]=year (19xx/20xx)
;         [DH]=month (1..12)
;         [DL]=binary day-of-month (1..31)
; Exit  - [BX] preserved.  All other registers destroyed.

@GWSTS@_SETDAT:	PUSH	BX  ;save BX
	CALL	@GWSTS@_GDTIME  ;get current date/time into DATIME
	CALL	@GWSTS@_DYOFYR  ;[BX]=day of year (0..364/365)
;[CX]=year - 1978
	OR	CX,CX  ;test year
	JZ	@GWSTS@_YEARSX  ;branch if 1978
	JMP	@GWSTS@_YEARS1
@GWSTS@_YEARSL:	CALL	@GWSTS@_CKLEAP  ;[AX]=1 if CX is leap-year
	ADD	BX,AX  ;days=days+1 if leap-lear
@GWSTS@_YEARS1:	ADD	BX,365  ;days=days+365
	LOOPNZ	@GWSTS@_YEARSL
@GWSTS@_YEARSX:	MOV	word [@DATIME],BX  ;DATIME=count of days since 1/1/1978
	CALL	@GWSTS@_SDTIME  ;set current date/time from DATIME
	POP	BX  ;restore text pointer
	RET

;GETDAT returns with [CX]=year, DH=month, DL=day-of-month.
; Exit - BX, AX are used.

@GWSTS@_GETDAT:	CALL	@GWSTS@_GDTIME  ;get current date/time into DATIME
	MOV	DX,word [@DATIME]  ;[DX]=no of days since JAN 1,1978
	MOV	CX,0  ;years=0
@GWSTS@_FNDYR:	CALL	@GWSTS@_CKLEAP  ;[AX]=1 if leap-year
	ADD	AX,365  ;[AX]=366 if leap-year
	CMP	DX,AX
	JB	@GWSTS@_GOTYR  ;branch if CX=year
	SUB	DX,AX  ;days=days-365 or 366
	INC	CX  ;year=year+1
	JMP	@GWSTS@_FNDYR

@GWSTS@_GOTYR:	CALL	@GWSTS@_SETFEB  ;set DAYSPM(2)=28 or 29
	MOV	BX,0
	MOV	AH,BH
@GWSTS@_FNDMON:	MOV	AL,byte [@DAYSPM+BX]  ;[AX]=days in month BX
	INC	BX
	CMP	DX,AX
	JB	@GWSTS@_GOTMON  ;branch if BX is month
	SUB	DX,AX
	JMP	@GWSTS@_FNDMON

@GWSTS@_GOTMON:	MOV	DH,BL  ;[DH]=month (1..12)
	INC	DL  ;[DL]=day of month (1..31)
	ADD	CX,1978  ;[CX]=year
	RET
end if
@GWSTS@_SETDAT:	PUSH	BX
	@DOSIO	@GWSTS@_SDAT  ;Give Date to MS-DOS.
	OR	AL,AL  ;Date OK?
	JNZ	@GWSTS@_DATERR  ;Brif not.
	POP	BX
	RET

;GETDAT returns with [CX]=year, DH=month, DL=day-of-month.
; Exit - BX, AX are used.

@GWSTS@_GETDAT:	@DOSIO	@GWSTS@_GDAT  ;Get Date from MS-DOS
	RET
; SUBTTL TIME - Get/Set Time.

; PUBLIC	TIMES,TIMEF
; EXTRN	STRINI:NEAR,PUTNEW:NEAR,FCERR:NEAR
; EXTRN	CHRGTR:NEAR,SYNCHR:NEAR,GETYPR:NEAR,FRMEVL:NEAR,FRESTR:NEAR
end if
; EXTRN	DATIME:WORD,EQULTK:WORD
if @GW_PASS = 1

; TIME$=[H]H[:[M]M[:[S]S[:[T]T]]]

@TIMES:	CALL	@GWSTS@_PRSTIM  ;CH=hour, CL=min, DH=sec, DL=.01sec
	JMP	@GWSTS@_SETTIM  ;set system time

;X$=TIME$ returns "HH:MM:SS"

@TIMEF:
	CALL	@CHRGTR  ;skip TIME$ (it was CPI'ed in FRMEVL)
	PUSH	BX  ;Save Text pointer
	MOV	AL,((8) and 0FFh)
	CALL	@STRINI  ;Get space for 8 char string
	PUSH	DX  ;Save addr of string
	CALL	@GWSTS@_GETTIM  ;CH=hour, CL=min, DH=sec
	POP	BX  ;Restore addr of String
	MOV	AL,CH
	CALL	@GWSTS@_PUTCHR  ;Store ascii hours
	MOV	AL,((":") and 0FFh)
	CALL	@GWSTS@_PUTCH2
	MOV	AL,CL
	CALL	@GWSTS@_PUTCHR  ;Store ascii minutes
	MOV	AL,((":") and 0FFh)
	CALL	@GWSTS@_PUTCH2
	MOV	AL,DH
	CALL	@GWSTS@_PUTCHR  ;Store ascii seconds.
	JMP	@PUTNEW  ;Put result and ret (Txt ptr on stack).

; EXTRN	FMULT:NEAR,CONIA:NEAR,FRCSNG:NEAR,FADD:NEAR,PUSHF:NEAR

;PRSTIM parses a string containing "HH[:MM[:SS[.TT]]]
; Exit - CH=hours, CL=minutes, DH=seconds, DL=.01 secs,
;         [BX]=new text pointer.  All other regs preserved.

@GWSTS@_PRSTIM:
	CALL	@SYNCHR
	DB	@EQULTK  ;Must be TIME$ = string
	CALL	@FRMEVL
	PUSH	BX  ;Save Text pointer
	CALL	@FRESTR
	MOV	CL,byte [BX+0]  ;Save string len in [CL]
	CMP	CL,((1) and 0FFh)  ;String must not be null
	JB	@GWSTS@_TIMERR  ;Brif null str
	MOV	SI,word [BX+1]  ;[SI] has addr of string.
	MOV	BL,CL  ;Working reg for string len.
	CALL	@GWSTS@_GNUM8  ;[AX]=hours
	CMP	AL,((24) and 0FFh)
	JNB	@GWSTS@_TIMERR
	MOV	CH,AL  ;[CH] = hours
	CALL	@GWSTS@_TIMSEP
	CALL	@GWSTS@_GNUM8
	CMP	AL,((60) and 0FFh)
	JNB	@GWSTS@_TIMERR
	MOV	CL,AL  ;[CL] = minutes
	CALL	@GWSTS@_TIMSEP
	CALL	@GWSTS@_GNUM8
	CMP	AL,((60) and 0FFh)
	JNB	@GWSTS@_TIMERR
	MOV	DH,AL  ;[DH] = seconds.
	CALL	@GWSTS@_TIMSEP
	CALL	@GWSTS@_GNUM8
	CMP	AL,((100) and 0FFh)
	JNB	@GWSTS@_TIMERR
	MOV	DL,AH  ;[DL] = 100ths.
	POP	BX  ;Text pointer
	RET  ;Exit.

@GWSTS@_TIMSEP:
	OR	BL,BL
	JZ	@GWSTS@_TIMSXX
	DEC	BL
	CLD  ;Set to increment
	LODSB
	CMP	AL,((":") and 0FFh)
	JZ	@GWSTS@_TIMSXX
	CMP	AL,((".") and 0FFh)
	JNZ	@GWSTS@_TIMERR
@GWSTS@_TIMSXX:
	RET

@GWSTS@_TIMERR:	JMP	@FCERR

if @CPM86
@GWSTS@_SETTIM:	CALL	@GWSTS@_GDTIME  ;get current date/time into DATIME
	PUSH	BX  ;save text pointer
	MOV	BX,@DATIME+2  ;BX points to hours digit of buffer
	MOV	AL,CH
	CALL	@GWSTS@_BINBCD  ;DT.HRS=BINBCD(CH)
	MOV	AL,CL
	CALL	@GWSTS@_BINBCD  ;DT.MIN=BINBCD(CL)
	MOV	AL,DH
	CALL	@GWSTS@_BINBCD  ;DT.SEC=BINBCD(DH)
	CALL	@GWSTS@_SDTIME  ;set current date/time from DATIME
	POP	BX  ;restore text pointer
	RET

;BINBCD converts [AL] to 2-digit BCD and stores the result at [BX]
; Exit  - BX is incremented

@GWSTS@_BINBCD:
	PUSH	DX  ;save caller's [DX]
	MOV	AH,((0) and 0FFh)
	MOV	DL,((10) and 0FFh)
	DIV	DL  ;[AL]=[AX]/10, [AH]=remainder
	ADD	AL,AL  ;[AL]=1st digit * 2
	ADD	AL,AL  ; * 4
	ADD	AL,AL  ; * 8
	ADD	AL,AL  ; * 16
	ADD	AL,AH  ; + second digit
	POP	DX  ;restore caller's [DX]
	JMP	@GWSTS@_PUTCH2

@GWSTS@_GETTIM:	CALL	@GWSTS@_GDTIME  ;get current date/time into DATIME
	MOV	BX,@DATIME+2  ;BX points to hours digit of buffer
	CALL	@GWSTS@_BCDBIN
	MOV	CH,AL  ;[CH]=BCDBIN(DT.HRS)
	CALL	@GWSTS@_BCDBIN
	MOV	CL,AL  ;[CL]=BCDBIN(DT.MIN)
	CALL	@GWSTS@_BCDBIN
	MOV	DH,AL  ;[DH]=BCDBIN(DT.SEC)
	RET

;GDTIME sets DATIME to the current date-time.
; Exit - All registers preserved.

@GWSTS@_GDTIME:	PUSH	ES
	PUSH	AX
	PUSH	BX
	PUSH	CX
	PUSH	DX
	CLD  ;Because of Melco BIOS Bug
	MOV	DX,@DATIME
	@CPMXIO	155  ;CPM86 system call
	JMP	@GWSTS@_SDTIMX

;SDTIME sets the system clock to DATIME
; Exit - All registers preserved.

@GWSTS@_SDTIME:	PUSH	ES
	PUSH	AX
	PUSH	BX
	PUSH	CX
	PUSH	DX
	MOV	DX,@DATIME
	@CPMXIO	104  ;CPM86 system call
@GWSTS@_SDTIMX:	POP	DX
	POP	CX
	POP	BX
	POP	AX
	POP	ES
	RET

;BCDBIN converts [[BX]] from 2-digit BCD to binary and
; returns it in [AL]
; Exit  - BX is incremented, AH, DL are destroyed.

@GWSTS@_BCDBIN:	MOV	AL,byte [BX+0]
	INC	BX
	MOV	AH,AL  ;[AH]=copy of input parameter
	AND	AL,((240) and 0FFh)  ;[AL]=D1*16 (most significant digit)
	ROR	AL,1  ;[AL]=D1*8
	MOV	DL,AL  ;[DL]=D1*8
	ROR	AL,1  ;[AL]=D1*4
	ROR	AL,1  ;[AL]=D1*2
	ADD	AL,DL  ;[AL]=D1*10
	AND	AH,((15) and 0FFh)  ;[AH]=D2
	ADD	AL,AH  ;[AL]=10*D1+D2=binary result
	RET
end if
@GWSTS@_SETTIM:	PUSH	BX
	@DOSIO	@GWSTS@_STIM  ;Give Time to MS-DOS.
	OR	AL,AL  ;Date OK?
	JNZ	@GWSTS@_TIMERR  ;Brif not.
	POP	BX
	RET

@GWSTS@_GETTIM:	@DOSIO	@GWSTS@_GTIM  ;Get Time from MS-DOS
	RET

; SUBTTL  Error Handlers for Features not supported in a version

; EXTRN	DERDNA:NEAR
	JMP	@DERDNA  ;Device unavailable error

; PUBLIC	PALETE
@PALETE:
	JMP	@SNERR

end if
; EXTRN	ERRADV:WORD
if @GW_PASS = 1
; EXTRN	ERROR:NEAR

; PUBLIC	TIMER
@TIMER:
; PUBLIC	ERDEV
@ERDEV:
; PUBLIC	IOCTL
@IOCTL:
; PUBLIC	CHDIR
@CHDIR:
; PUBLIC	MKDIR
@MKDIR:
; PUBLIC	RMDIR
@RMDIR:
; PUBLIC	SHELL
@SHELL:
; PUBLIC	ENVIRON
@ENVIRON:
; PUBLIC	VIEW
@VIEW:
; PUBLIC	WINDOW
@WINDOW:
; PUBLIC	PMAP
@PMAP:
@GWSTS@_ADVERR:
	MOV	DL,((@ERRADV) and 0FFh)
	JMP	@ERROR

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
