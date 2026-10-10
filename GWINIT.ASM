; [ This translation created 10-Feb-83 by Version 4.3 ]

if @GW_PASS = 1

include 'OEM.H'

; TITLE   GWINIT GW-BASIC-86 Initialization

;Assumes LEN2, FIVMEM, FIVEO, I8086, PURE

@GWINIT@_TRACEF=0  ;for Debugging when DEBUG can't be used
@CPM86=0
@GWINIT@_DYNBUF=0
@GWINIT@_BSEGSZ=0  ;Size of Buffer segment for Misc. Buffers

end if
; EXTRN	LSTVAR:WORD
; EXTRN	FILTAB:WORD,STKLOW:WORD,MAXMEM:WORD
; EXTRN	TSTACK:WORD,ERRFLG:WORD
; EXTRN	MEMSIZ:WORD,TOPMEM:WORD,SAVSTK:WORD,FRETOP:WORD,TXTTAB:WORD
; EXTRN	PROFLG:WORD,CHNFLG:WORD,MRGFLG:WORD,ERRFLG:WORD
; EXTRN	CHNFLG:WORD,MRGFLG:WORD,ERRFLG:WORD
; EXTRN	PRMSTK:WORD,PRMPRV:WORD
if @GW_PASS = 1

; EXTRN	FCERR:NEAR,SNERR:NEAR

	@GWINIT@_SWTCHR=47  ;DEFAULT SWITCH CHARACTER IS SLASH
; EXTRN	MAKUPL:NEAR
; EXTRN	CNSGET:NEAR
; EXTRN	CHRGTR:NEAR
; EXTRN	OUTDO:NEAR,LINPRT:NEAR,CRDO:NEAR,OMERRR:NEAR
; EXTRN	REASON:NEAR
; EXTRN	READY:NEAR,STKINI:NEAR
; EXTRN	DCOMPR:NEAR
; EXTRN	SYNCHR:NEAR

end if
; EXTRN	BUF:WORD
; EXTRN	SNERR:NEAR,FCERR:NEAR,ATN:NEAR,COS:NEAR
; EXTRN	MSWFLG:WORD,MSWSIZ:WORD,CSWFLG:WORD,CSWSIZ:WORD,NEWDS:WORD
; EXTRN	MAPCLC:NEAR,MAPINI:NEAR
; EXTRN	INITSA:NEAR
; SUBTTL  INIT - System Initialization Code

; PUBLIC	INIT
; EXTRN	STROUT:NEAR,HEDING:NEAR,WORDS:NEAR
; EXTRN	GWINI:NEAR
; EXTRN	BUF:WORD,KBUF:WORD
if @GW_PASS = 1

@INIT:
; For safety, a label has been defined in BINTRP.MAC that contains the
; start of the data segment.  That is where the O.S. control block will
; be copied to, so it MUST be first in the DSEG.
; BEGDSG is declared as a code segment external here even though it
; really is in the data segment.  This makes it easier to get the offset
; of the beginning of the data segment from the beginning of the code
; segment.  The beginning of DATASG MUST be within 64K of the beginning
; of CODESG for this to work.  No error will be generated, so be careful.

; EXTRN	BEGDSG:NEAR
	@INS86	272,,@GWBASIC_DSEG_BASE  ;MOVI DX,BEGDSP
	@INS86	261,4  ;MOVI CL,4   Divide by 16 to ...
	@INS86	323,352  ;SHR  DX,CL  get paragraph address
	@INS86	214,311  ;MOV  CX,CS  add in code segment
	@INS86	3,321  ;ADD  DX,CS
	@INS86	264,46  ;MOVBI AH,38 SPECIAL FUNCTION TO CALC END
;            OF CS AND RETURN START OF DS
	@INS86	315,41  ;INT  33     CALL SCP DOS
	@INS86	214,330  ;MOV  AX,DS  SAVE DS FOR EXIT VECTOR
	@INS86	216,332  ;MOV  DS,DX  SET UP SEG REGS
	@INS86	216,302  ;MOV  ES,DX
;Initialize the jump vector for exit to MSDOS.  MSDOS 2.0 requires that
; exit is made through the segment prefix table which is located at DS:0.
; For .EXE files, DS is not the same as CS at program initiation time (NOW).
end if
; EXTRN	CPMEXT:WORD
if @GW_PASS = 1
	@INS86	307,6,@CPMEXT  ;MOVI CPMEXT,^D0
	@INS86	0,0  ;            INS86 has 4 params
;            & some may not be words
	@INS86	220,243,@CPMEXT+2  ;NOP         NOP - pad to item 3 of INS86
;MOV  CPMEXT+2,AX
	CLI  ;Setting the stack segment and stack
;pointer must be an indivisable
;operation.
	@INS86	216,322  ;MOV SS,DX
	MOV	BX,@BUF+128  ;Use BUF for a temporary stack.
	MOV	[@MEMSIZ],BX
	MOV	SP,BX
	XOR	AL,AL  ;INITIALIZE PROTECT FLAG
	MOV	byte [@PROFLG],AL
	MOV	byte [@MSWFLG],AL  ;Init /M: flag
	MOV	byte [@CSWFLG],AL  ;Init /C: flag
; EXTRN	CNSLEN:NEAR,CONSTR:NEAR
end if
; EXTRN	ENDBUF:WORD,RAMLOW:WORD
if @GW_PASS = 1
	MOV	CH,((@CNSLEN+3) and 0FFh)  ;Get number of bytes to move
	MOV	BX,@RAMLOW  ;WHERE THE CONSTANTS ARE STORE IN RAM
	MOV	DX,@CONSTR  ;WHERE THE CONSTANTS ARE HELD IN ROM
@GWINIT@_MORMOV:  ;MOVE ROM INITIALIZATION VALUES TO RAM
	@INS86	213,362,56,254  ;CODE SEGMENT FETCH
	MOV	byte [BX],AL  ;STORE IT AWAY IN RAM
	INC	BX
	INC	DX
	DEC	CH
	JNZ	@GWINIT@_MORMOV  ;IF NOT, KEEP SHOVELING THEM DOWN
	STI
; EXTRN	SCNIPL:NEAR
	CALL	@SCNIPL  ;Screen editor initialization
	CALL	@GWINI  ;OEM specific initialization
; EXTRN	SNDRST:NEAR
	CALL	@SNDRST  ;reset sound queue, disable speaker
; EXTRN	GIOINI:NEAR
	CALL	@GIOINI
	MOV	BX,[@MEMSIZ]
	MOV	[@TOPMEM],BX
	MOV	BX,@KBUF-1  ;INITIALIZE KBUF-1 WITH A COLON
	MOV	byte [BX],((":") and 0FFh)  ;DIRECT INPUTS RESTART OK.
	CALL	@STKINI  ;REALLY SET UP INIT'S TEMPORARY STACK

;       Check CP/M Version Number

end if
; EXTRN	CPMREA:WORD
if @GW_PASS = 1

	MOV	BX,34*256+33+0  ;2.x Read / Write
@GWINIT@_CPMVR1:	MOV	[@CPMREA],BX  ;Save Read/Write Codes
end if
; EXTRN	CNTOFL:WORD
if @GW_PASS = 1
	XOR	AL,AL
	MOV	byte [@CNTOFL],AL
end if
; EXTRN	ENDBUF:WORD
if @GW_PASS = 1
	MOV	byte [@ENDBUF],AL  ;MAKE SURE OVERRUNS STOP
end if
; EXTRN	DSEGZ:WORD
if @GW_PASS = 1
	MOV	byte [@DSEGZ],AL  ;(DS) LOCATED ZERO
	MOV	byte [@CHNFLG],AL  ;MAKE SURE CHAINS AND MERGES
	MOV	byte [@MRGFLG],AL  ;DONT TRY TO HAPPEN
	MOV	byte [@ERRFLG],AL  ;DON'T ALLOW EDIT TO BE CALLED ON ERRORS
end if
; EXTRN	TEMPST:WORD,TEMPPT:WORD
if @GW_PASS = 1
	MOV	BX,@TEMPST
	MOV	[@TEMPPT],BX
	MOV	BX,@PRMSTK  ;INITIALIZE PARAMETER BLOCK CHAIN
	MOV	[@PRMPRV],BX

; SUBTTL Read Operating System Parameters (memsiz etc.)

; THE FOLLOWING CODE SCANS A CP/M COMMAND LINE FOR BASIC.

; THE FOLLOWING SWITCHES ARE RECOGNIZED:

;       /M:<TOPMEM>
;       /F:<FILES>
;       /S:<MAX RECORD SIZE>
;       /C:<COM INPUT QUEUE SIZE>

end if
; EXTRN	CPMMEM:WORD
if @GW_PASS = 1
	MOV	BX,[@CPMMEM]  ;Load bytes free within segment
;For DYNCOM, CPMMEM holds the last segment addr of the system(i.e. CPMMEM=2)
; EXTRN	SEGOFF:NEAR
	CALL	@SEGOFF  ;Return byte offset of segment from current DS
	MOV	[@MEMSIZ],BX  ;USE AS DEFAULT
	MOV	[@MAXMEM],BX  ;set MAX DS size for CLEAR statement
end if
; EXTRN	DSEGZ:WORD
if @GW_PASS = 1
	MOV	BX,@DSEGZ  ;IN THE DATA SEGMENT
	MOV	[@TEMP8],BX  ;SO IF RE-INITAILIZE OK
; EXTRN	CPMWRM:NEAR
	@GWINIT@_TBUFF = @CPMWRM+128  ;WHERE CP/M COMMAND BUFFER IS LOCATED

	MOV	BX,@GWINIT@_TBUFF  ;POINT TO FIRST CHAR OF COMMAND BUFFER
	MOV	AL,byte [BX]  ;WHICH CONTAINS # OF CHARS IN COMMAND
	OR	AL,AL  ;IS THERE A COMMAND?
	MOV	[@TEMP8],BX  ;SAVE POINTER TO THIS ZERO
	JNZ	@GWINIT@_@Q@QL000
	JMP	@GWINIT@_DONCMD  ;NOTHING IN COMMAND BUFFER
@GWINIT@_@Q@QL000:
	MOV	CH,byte [BX]  ;AND [B]
	INC	BX  ;POINT TO FIRST CHAR IN BUFFER
@GWINIT@_TBFLP:	MOV	AL,byte [BX]  ;GET CHAR FROM BUFFER
	DEC	BX  ;BACK UP POINTER
	MOV	byte [BX],AL  ;STORE CHAR BACK
	INC	BX  ;NOW ADVANCE CHAR TO ONE PLACE
	INC	BX  ;AFTER PREVIOUS POSIT.
	DEC	CH
	JNZ	@GWINIT@_TBFLP  ;KEEP MOVING CHARS
	DEC	BX  ;BACK UP POINTER
@GWINIT@_ENDCMD:	MOV	byte [BX],((0) and 0FFh)  ;STORE TERMINATOR FOR CHRGET (0)
	MOV	[@TEMP8],BX  ;SAVE POINTER TO NEW ZERO (OLD DESTROYED)
	MOV	BX,@GWINIT@_TBUFF-1  ;POINT TO CHAR BEFORE BUFFER
	CALL	@CHRGTR  ;IGNORE LEADING SPACES
	OR	AL,AL
	JNZ	@GWINIT@_@Q@QL001
	JMP	@GWINIT@_DONCMD  ;END OF COMMAND
@GWINIT@_@Q@QL001:
	CMP	AL,((@GWINIT@_SWTCHR) and 0FFh)  ;IS IT A SLASH
	JZ	@GWINIT@_FNDSLH  ;YES
	DEC	BX  ;BACK UP POINTER
	MOV	byte [BX],((34) and 0FFh)  ;STORE DOUBLE QUOTE
	MOV	[@TEMP8],BX  ;SAVE POINTER TO START OF FILE NAME
	INC	BX  ;BUMP POINTER
@GWINIT@_ISSLH:	CMP	AL,((@GWINIT@_SWTCHR) and 0FFh)  ;OPTION?
	JZ	@GWINIT@_FNDSLH  ;YES
	CALL	@CHRGTR  ;SKIP OVER CHAR IN FILE NAME
	OR	AL,AL  ;SET CC'S
	JNZ	@GWINIT@_ISSLH  ;KEEP LOOKING FOR OPTION
	JMP	@GWINIT@_DONCMD  ;THATS IT
@GWINIT@_FNDSLH:	MOV	byte [BX],((0) and 0FFh)  ;STORE TERMINATOR OVER "/"
@GWINIT@_SCANSW:
	CALL	@CHRGTR  ;GET CHAR AFTER SLASH
@GWINIT@_SCANS1:
	CALL	@MAKUPL  ;CONVERT SWITCH TO UPPER CASE
	CMP	AL,(("S") and 0FFh)  ;IS IT /S: ? (SET MAX RECORD SIZE)
	JZ	@GWINIT@_WASS
	CMP	AL,(("C") and 0FFh)  ;COM buffer size option
	JZ	@GWINIT@_WASC
	CMP	AL,(("F") and 0FFh)  ;FILES OPTION
	JZ	@GWINIT@_WASF
	CMP	AL,(("M") and 0FFh)  ;MEMORY OPTION
	JZ	@GWINIT@_@Q@QL002
	JMP	@SNERR  ;Branch if couldn't recognize option
@GWINIT@_@Q@QL002:
	CALL	@GWINIT@_GETVAL  ;[DX]=requested MEMSIZ
	MOV	[@MSWSIZ],DX  ;Record memory request
	MOV	AL,((255) and 0FFh)
	MOV	byte [@MSWFLG],AL  ;Set /M: option flag
@GWINIT@_FOK:	DEC	BX  ;RESCAN LAST CHAR
	CALL	@CHRGTR  ;BY CALLING CHRGET
	JZ	@GWINIT@_DONCMD  ;END OF COMMAND
	CALL	@SYNCHR
	DB	@GWINIT@_SWTCHR  ;SLASH SHOULD FOLLOW
	JMP	@GWINIT@_SCANS1  ;SCAN NEXT SWITCH

@GWINIT@_WASC:	MOV	AL,((255) and 0FFh)
	MOV	byte [@CSWFLG],AL  ;Set /C: option flag
	CALL	@GWINIT@_GETVAL  ;Get COM request to D,E
	MOV	[@CSWSIZ],DX  ;Record for future memory map calc.
	JMP	@GWINIT@_FOK
@GWINIT@_WASS:  ;GIO has dynamic record size
@GWINIT@_WASF:  ;GIO has dynamic number of files
	CALL	@GWINIT@_GETVAL  ;Get value
	JMP	@GWINIT@_FOK  ;Any value OK (and ignored)

@GWINIT@_GETVAL:	CALL	@CHRGTR  ;skip M,F or S
	CALL	@SYNCHR
	DB	":"  ;MAKE SURE COLON FOLLOWS
	JMP	@CNSGET  ;[DE]=VALUE FOLLOWING COLON
end if
; EXTRN	TEMP8:WORD
if @GW_PASS = 1
@GWINIT@_ERRCMD:
@GWINIT@_DONCMD:
	CALL	@MAPCLC  ;Calc. (but don't set) the new mem. map

;Now copy the command line file name (if there is one) to BUF
;Move required since DS: segment header will be overwritten when the
;DS: is coppied to the new DS: location.

	MOV	BX,[@TEMP8]  ;Load address of command line file name
	MOV	DX,@BUF  ;Destination address
	MOV	[@TEMP8],DX  ;New command line buffer address
@GWINIT@_NXTBYT:	MOV	AL,byte [BX]  ;File name character
	XCHG	BX,DX
	MOV	byte [BX],AL  ;Store at BUF
	INC	BX
	XCHG	BX,DX
	INC	BX
	OR	AL,AL  ;Test for zero byte terminator
	JNZ	@GWINIT@_NXTBYT  ;Get next file name character

; SUBTTL Allocate Space for Disk Buffers

; Disk Initialization Routine

; setup  file info blocks
; the number of each and information for
; getting to pointers to each is stored. no locations are
; initialized, this is done by nodsks, first closing all files.
; the number of files is the file pointer table

	MOV	BX,[@MEMSIZ]  ;get size of memory
	DEC	BX  ;always leave top byte unused because
;val(string) makes byte in memory
;beyond last char of string=0
	MOV	[@MEMSIZ],BX  ;save in real memory size
	DEC	BX  ;one lower is stktop
	PUSH	BX  ;save it on stack

; SUBTTL INIT TXTAB, STKTOP, VARTAB, MEMSIZ, FRETOP, STREND

; Memory map for GW-BASIC:

;               [MAXMEM]--}     highest byte of physical memory in system
;                               user managed memory
;               [TOPMEM]--}     highest byte available to BASIC
;                               basic stack
;               [STKLOW]--}     lowest byte available for STACK
;                           +--}FDB---}[STKEND] {end of chain}
;                           +---FDB{--+
;               [FILTAB]-------}FDB---+ (FILTAB points to lowest byte of lowest FDB)
;                               0 (1 byte string space terminator for VAL)
;               [MEMSIZ]--}     highest byte of IN-USE string space
;               [FRETOP]--}     highest byte of FREE string space
;               [STREND]--}     lowest  byte of FREE string space
;               [ARYTAB]--}     lowest  byte of Array Table
;               [VARTAB]--}     lowest  byte of Variable Table
;               [TXTTAB]--}     lowest  byte of BASIC Program Text

; note:  when [FILTAB] = [STKLOW], no FDB's are allocated.
;        when [FRETOP] = [MEMSIZ], IN-USE string space is empty.
;        when [SP] = [STKLOW], STACK is full.

; At this point, MEMSIZ-1 is on stack, [HL]=TXTTAB-1

	MOV	BX,@LSTVAR  ;LSTVAR resides in last linked module with DS:
	MOV	[@TXTTAB],BX  ;save bottom of memory
	POP	DX  ;GET CURRENT MEMSIZ
	MOV	AL,DL  ;WANT AN EVEN STACK PTR. FOR 8086
	AND	AL,((254) and 0FFh)  ;SO WE'LL CLEAR LOW BIT
	MOV	DL,AL  ;OF THE STACK PTR.
	MOV	AL,DL  ;CALC TOTAL FREE/8
	SUB	AL,BL
	MOV	BL,AL
	MOV	AL,DH
	SBB	AL,BH
	MOV	BH,AL
	JAE	@GWINIT@_@Q@QL003
	JMP	@OMERRR
@GWINIT@_@Q@QL003:
	MOV	CL,((3) and 0FFh)  ;SHIFT RIGHT THREE BITS (DIVIDE BY 8)
	@INS86	323,353  ;SHR BX,CL
	MOV	AL,BH  ;SEE HOW MUCH
	CMP	AL,((2) and 0FFh)  ;IF LESS THAN 512 USE 1 EIGHTH
	JB	@GWINIT@_SMLSTK
	MOV	BX,512
@GWINIT@_SMLSTK:	MOV	AL,DL  ;SUBTRACT STACK SIZE FROM TOP MEM
	SUB	AL,BL
	MOV	BL,AL
	MOV	AL,DH
	SBB	AL,BH
	MOV	BH,AL
	JAE	@GWINIT@_@Q@QL004
	JMP	@OMERRR
@GWINIT@_@Q@QL004:

	MOV	[@STKLOW],BX  ;Save lowest legal value for [SP]
	MOV	[@FILTAB],BX  ;Initially there are no FDB's
	DEC	BX
	MOV	byte [BX],((0) and 0FFh)  ;String space should be terminated by 0 for VAL
	DEC	BX
	MOV	[@MEMSIZ],BX  ;Save highest byte to be used by strings
	XCHG	BX,DX
	MOV	[@TOPMEM],BX
	MOV	[@FRETOP],BX  ;REASON USES THIS...
	MOV	SP,BX  ;SET UP NEW STACK
	MOV	[@SAVSTK],BX
	MOV	BX,[@TXTTAB]
	XCHG	BX,DX
	CALL	@REASON
end if
; EXTRN	FREFLG:WORD
if @GW_PASS = 1
	XOR	AL,AL
	MOV	byte [@FREFLG],AL  ;Clear to print free bytes message
; EXTRN	GETHED:NEAR
end if
; EXTRN	KEYSW:WORD
if @GW_PASS = 1
	MOV	AL,((255) and 0FFh)  ;if heading is printed, display Fn keys also
	MOV	byte [@KEYSW],AL
	CALL	@GETHED  ;Get OEM specific portion of the heading
	JNZ	@GWINIT@_PRNTIT  ;Always print the heading option
	PUSH	BX  ;Print heading if no program option
	MOV	BX,[@TEMP8]  ;Get pointer to file or 0
	MOV	AL,byte [BX]  ;Test for file on command line
	POP	BX  ;Retrieve OEM heading pointer
	OR	AL,AL
	JZ	@GWINIT@_PRNTIT  ;No program - go print heading
	MOV	byte [@FREFLG],AL  ;Set to inhibit free bytes message
	XOR	AL,AL  ;Turn keys off if there is a program
	MOV	byte [@KEYSW],AL  ; otherwise allow OEM default
	JMP	@GWINIT@_PRNTND  ;Skip heading

@GWINIT@_PRNTIT:	CALL	@STROUT  ;Print it
	MOV	BX,@HEDING  ;GET HEADING ("BASIC VERSION...")
	CALL	@STROUT  ;PRINT IT
@GWINIT@_PRNTND:
; EXTRN	SKEYON:NEAR
	MOV	AL,byte [@KEYSW]  ;Get function key display switch
	OR	AL,AL  ;Keys need to be turned on?
	JNZ	@GWINIT@_@Q@QL005
	JMP	@GWINIT@_KEYSOF  ;Leave keys off
@GWINIT@_@Q@QL005:
	XOR	AL,AL
	MOV	byte [@KEYSW],AL  ;Show current status of keys
	CALL	@SKEYON  ;Set function key display on
@GWINIT@_KEYSOF:	MOV	AL,((255) and 0FFh)
	MOV	byte [@INITFG],AL  ;Set the initialization complete flag
;indicating errors no longer result in an exit
;to the OS
	JMP	@INITSA
;CMDERR This routine is called when an error is detected before the
;       completion of initialization (before INITFG is set to non-zero).
;       CMDERR performs the following:
;               1. Write the heading
;               2. Write an error message implicating the command line.
;               3. Exit to the operating system through SYSTME

end if
; EXTRN	INITFG:WORD
if @GW_PASS = 1
; EXTRN	SYSTME:NEAR,CERMSG:NEAR
; PUBLIC	CMDERR

@CMDERR:	MOV	BX,@HEDING  ;Get heading ("BASIC VERSION...")
	CALL	@STROUT  ;Print it
	MOV	BX,@CERMSG  ;Get command error message
	CALL	@STROUT  ;Print it
	JMP	@SYSTME  ;Exit to the OS

; PUBLIC	$LAST
	@@SLAST=$
; PUBLIC	LASTWR
	@LASTWR=$
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
