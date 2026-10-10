; [ This translation created 10-Feb-83 by Version 4.3 ]

if @GW_PASS = 1

include 'OEM.H'

; TITLE   SCNEDT  Screen Oriented Editor for GW-BASIC
; SUBTTL  DATA DEFINITIONS

; COMMENT	*
;         --------- --- ---- -- ---------
;         COPYRIGHT (C) 1982 BY MICROSOFT
;         --------- --- ---- -- ---------
;         *

include 'GIO86U'

;OEM IFNDEF'S:
@SCNEDT@_MELCO=0
@SCNEDT@_HAL=0

;GENERIC IFNDEF'S:
@SCNEDT@_TERMSW=0
@SCNEDT@_HLPTRP=0
@SCNEDT@_STPTRP=0
@SCNEDT@_HLPEDT=0
@SCNEDT@_SCRKEY=0
@SCNEDT@_NMPAGE=0
@SCNEDT@_IBMCSR=@IBMLIK

;INTERNAL ROUTINES:

; PUBLIC	PINLIN
;on exit:       BX=addr of input -1

; PUBLIC	INLIN
;on exit:       BX=addr of input -1

; PUBLIC	SINLIN
;on exit:       BX=addr of input -1

; PUBLIC	QINLIN
;on exit:       BX=addr of input -1

; PUBLIC	SCNSEM
;on exit:       SEMFLG flag set
; PUBLIC	EDTBRK

; PUBLIC	ERREDT
;on exit:       Removes return and jumps to MAIN after
;               listing ERRLIN and positioning cursor at
;               start of line.

; PUBLIC	EDIT
;on exit:       Same as ERREDT, except takes line number
;               to list as argument.

;       INTERN  EDITRT          ; AUTO Program line input processing
;on exit:       BX=addr of input(BUF)
;               it also puts PSW on stack with carry
;               set and jumps to EDENT for exit

;EXTERNAL ROUTINES:

; EXTRN	OUTDO:NEAR
; EXTRN	KEYIN:NEAR
; EXTRN	SCNMRK:NEAR
; EXTRN	SCNRDL:NEAR
; EXTRN	CRDO:NEAR
; EXTRN	CHRGTR:NEAR

;DATA (DEFINED IN RAM MODULE)
end if
; EXTRN	F_EDPG:WORD
; EXTRN	SEMFLG:WORD
;       at end of input line)
; EXTRN	F_INST:WORD
; EXTRN	BUF:WORD
;   NOTE: assumes non-blank at BUF-1
; EXTRN	F_EDIT:WORD
; EXTRN	AUTFLG:WORD
; EXTRN	CSRX:WORD
; EXTRN	CSRY:WORD
if @GW_PASS = 1
;LITERALS NEEDED ELSEWHERE
; PUBLIC	CHRLNF
; PUBLIC	CHRRET

;CHARACTER DEFINITIONS

	@SCNEDT@_CHREDT=1  ; EDiT
	@SCNEDT@_CHRBKW=2  ; BacK Word
	@SCNEDT@_CHRCAN=3  ; CANcel
	@SCNEDT@_CHRHCN=4  ; Hard CaNcel
	@SCNEDT@_CHRCLE=5  ; CLear to End of line
	@SCNEDT@_CHRFDW=6  ; ForwarD Word
	@SCNEDT@_CHRBEL=7  ; BELl
	@SCNEDT@_CHRBAK=8  ; BAcKspace
	@SCNEDT@_CHRTAB=9  ; TAB
	@CHRLNF=10  ; LiNeFeed
	@SCNEDT@_CHRHOM=11  ; HOMe
	@SCNEDT@_CHRERA=12  ; ERAse
	@CHRRET=13  ; RETurn
	@SCNEDT@_CHRAPP=14  ; APPend
	@SCNEDT@_CHRINS=18  ; INSert
	@SCNEDT@_CHRLDL=21  ; Line DeLete
	@SCNEDT@_CHRADV=28  ; cursor RiGhT
	@SCNEDT@_CHRREG=29  ; cursor LeFT
	@SCNEDT@_CHRUP=30  ; cursor UP
	@SCNEDT@_CHRDWN=31  ; cursor DoWN
	@SCNEDT@_CHRDEL=127  ; DELete
; SUBTTL  Entry points for editing

;ENTRY: PINLIN, QINLIN, INLIN, SINLIN

;PROGRAM STATEMENT INPUT
; PUBLIC	PINLIN
@PINLIN:	CALL	@SCNEDT@_DSKCHI  ; Don't return if Loading ASCII File
	STC  ; Indicate program statement input
	JMP	@SCNEDT@_INLIN0

;PRINT "?" BEFORE GETTING INPUT
; PUBLIC	QINLIN
@QINLIN:	MOV	AL,(("?") and 0FFh)
	CALL	@OUTDO  ; Output a "?"
	MOV	AL,((" ") and 0FFh)
	CALL	@OUTDO  ; Followed by a space

;INPUT STATEMENT
; PUBLIC	INLIN
@INLIN:

;INPUT STATEMENT REDO
; PUBLIC	SINLIN
@SINLIN:	OR	AL,AL  ; Indicate INPUT statement line input

@SCNEDT@_INLIN0:
	SBB	AL,AL  ; If INPUT statement AL=0, else AL=-1
	MOV	byte [@F_EDPG],AL  ; Save flag
	MOV	AL,byte [@F_EDIT]  ; Get old value of F.EDIT(in case of EDIT statement)
	MOV	byte [@F_EDIT],((255) and 0FFh)  ; Indicate executing INLIN
	CALL	@SCNMRK  ; Set up for edit
;   If AL=1 then move cursor to start of logical
;       line which preceeds current.
;   Else if ZF=1 then set up FSTPOS, LSTPOS
;        if ZF=0 then FSTPOS=0,0; LSTPOS=max,max
; SUBTTL  MAIN loop of editor

;WHILE EOL.NE.TRUE BEGIN
;** GET A KEY
@SCNEDT@_INLLOP:
; EXTRN	STCTYP:NEAR
	CLC  ; Signal for insert or overwrite cursor
	CALL	@STCTYP  ; Set new cursor type
	CALL	@KEYIN  ; AX=key value
;At this point we can have three classes of characters:
;   CF=1 indicates 2 byte char with 2 sub classes:
;       AH=FF indicates editor control function
;       AH<>FF indicates 2 byte character to echo
;   CF=0 indicates 1 or 3 byte key
;       AL=FF indicates a 3 byte key with scan code in DX - these are ignored
;       AL<>FF indicates a 1 byte key to echo, except if char is CR.
	JB	@SCNEDT@_INL2BY  ; BRIF 2-byte character, check for editor controls
	CMP	AL,((@CHRRET) and 0FFh)
	JZ	@SCNEDT@_INLRET  ; BRIF CR, terminate line input
;** IF CURRENT_CHAR IS SPECIAL THREE BYTE CHAR
	CMP	AL,((254) and 0FFh)  ; Test for 3-byte character
;** *** IGNORE THIS CHAR
	JZ	@SCNEDT@_INLLOP  ; BRIF to ignore 3-byte character
	JMP	@SCNEDT@_INLOP0  ; Not 3-bytes, just echo single byte
@SCNEDT@_INL2BY:
;** IF CURRENT_CHAR IS CONTROL_CHAR
	CMP	AH,((255) and 0FFh)
	JNZ	@SCNEDT@_INLOP0  ; BRIF not editor control character, echo char
	CMP	AL,((127) and 0FFh)
	JZ	@SCNEDT@_INLP0  ; BRIF is a control character
	CMP	AL,((" ") and 0FFh)
	JNB	@SCNEDT@_INLOP0  ; BRIF is not a control character
@SCNEDT@_INLP0:
;** IF CURRENT_CHAR IS <CR> RETURN CURRENT LOGICAL LINE
	CMP	AL,((@CHRRET) and 0FFh)
	JZ	@SCNEDT@_INLRET  ; BRIF is carriage return(EOL)
;** IF (CURRENT_CHAR=<HELP> AND INPUT_MODE=PROGRAM) DO EDIT ON KBUF
	CMP	AL,((@SCNEDT@_CHREDT) and 0FFh)
	JNZ	@SCNEDT@_INLOP0
	JMP	@SCNEDT@_INLHLP  ; BRIF help char, do edit on KBUF
;Echo character in AX
@SCNEDT@_INLOP0:
	OR	AH,AH
	JZ	@SCNEDT@_INLOP3  ; Single byte character
	XCHG	AL,AH  ; Output AH first
	CALL	@OUTDO  ; Output a char
	XCHG	AL,AH  ; Restore AL
@SCNEDT@_INLOP3:	CALL	@OUTDO  ; Output a char
	JMP	@SCNEDT@_INLLOP
;** END

;SCAN FOR SEMICOLON

@SCNSEM:	CMP	AL,((";") and 0FFh)
	JNZ	@SCNEDT@_SCNSMR  ; BRIF not semicolon, return
	MOV	byte [@SEMFLG],AL
	JMP	@CHRGTR  ; Skip semicolon and return
@SCNEDT@_SCNSMR:	RET
; SUBTTL  Exit, return current logical line

;READ LOGICAL LINE INTO BUF
@SCNEDT@_INLRET:	MOV	BX,@BUF  ; Put data into BUF
	MOV	CX,255  ; CX=Max number of bytes to move
	TEST	byte [@F_EDPG],((255) and 0FFh)  ; Set zero flag if program statement input
	PUSHF
	MOV	DL,byte [@CSRY]  ; (DH,DL) = (CSRX,CSRY)
	MOV	DH,byte [@CSRX]
	CALL	@SCNRDL  ; Read the logical line into BUF
; BX=address of last char in BUF plus one
;IF PROGRAM_STATEMENT_INPUT BEGIN
	POPF
	JZ	@SCNEDT@_INCRTX  ; BRIF not statement input
;** WHILE POSN.NE.BEGIN_OF_LINE AND [POSN].NE.BLANK AND [POSN].NE.LF BEGIN
	MOV	CX,BX
	SUB	CX,@BUF  ; CX=count of chars in BUF
	JZ	@SCNEDT@_INCRTX  ; BUF is empty
	PUSH	DI
	MOV	DI,BX
	DEC	DI  ; Start scan at last valid data
@SCNEDT@_INLOT0:	MOV	AL,((" ") and 0FFh)
;** *** POSN=POSN-1
@SCNEDT@_INLOT1:	STD  ; Scan backwards
 REPE	SCASB  ; This works for blank line("," at BUF-1)
	INC	DI  ; [DI] = last valid data
	MOV	AL,((" ") and 0FFh)
	CMP	byte [DI+0],AL
	JZ	@SCNEDT@_INLOT2  ; BRIF more trailing blanks
	MOV	AL,((@CHRLNF) and 0FFh)
	CMP	AL,byte [DI+0]
	JNZ	@SCNEDT@_INLOT3  ; BRIF not more trailing linefeeds
@SCNEDT@_INLOT2:	OR	CL,CL
	JNZ	@SCNEDT@_INLOT1  ; BRIF not at beginning of buffer
;** *** END
;** END
@SCNEDT@_INLOT3:	MOV	BX,DI
	POP	DI
	INC	BX
@SCNEDT@_INCRTX:	MOV	byte [BX+0],((0) and 0FFh)  ; Terminate BUF
;** UPDATE CURSOR POSN, RETURN
	TEST	byte [@SEMFLG],((255) and 0FFh)
	JNZ	@SCNEDT@_INCRTF  ; BRIF if INPUT<semicolon> statement
	MOV	AX,@SCNEDT@_CHRAPP
	CALL	@OUTDO  ; Move to end of logical
	MOV	byte [@F_EDIT],((0) and 0FFh)
	CALL	@CRDO  ; Move to first posn beyond this logical
@SCNEDT@_INCRTF:	MOV	BX,@BUF-1  ; Return BUF - 1
	PUSHF
	CALL	@SCNEDT@_CLRFLG  ; Clear miscellaneous status flags
	POPF
	RET

;SUBROUTINE EDTBRK              ; Routine which initializes when break detected
;**                             ; This is called by the STOP code
;**
@EDTBRK:
; EXTRN	SETCSR:NEAR
end if
; EXTRN	CSRTYP:WORD
if @GW_PASS = 1
	MOV	byte [@CSRTYP],((0) and 0FFh)  ; Indicate cursor off
	CALL	@SETCSR
	CALL	@SCNEDT@_CLRFLG  ; Clear editor flags
	PUSH	AX
	MOV	AL,((@SCNEDT@_CHRAPP) and 0FFh)
	MOV	byte [@F_EDIT],AL
	CALL	@OUTDO  ; Move cursor to end of logical line
	MOV	byte [@F_EDIT],((0) and 0FFh)  ; Reset edit mode
	CALL	@CRDO  ; Move cursor to next physical line
	POP	AX
	MOV	byte [@AUTFLG],((0) and 0FFh)  ; Reset AUTO mode
	RET
;** END SUBROUTINE EDTBRK

;SUBROUTINE CLRFLG              ; Routine which clears flags
;**
@SCNEDT@_CLRFLG:	MOV	byte [@F_EDIT],((0) and 0FFh)  ; No longer in INLIN
	MOV	byte [@F_EDPG],((0) and 0FFh)  ; Not program edit
	MOV	byte [@F_INST],((0) and 0FFh)  ; Not insert mode
	MOV	byte [@SEMFLG],((0) and 0FFh)  ; Not INPUT; statement
	RET
;** END SUBROUTINE CLRFLG

; SUBTTL  EDIT code

; EXTRN	MAIN:NEAR,LINSPC:NEAR,FNDLIN:NEAR,DEPTR:NEAR,LISPRT:NEAR
; EXTRN	LINPRT:NEAR,FCERR:NEAR,USERR:NEAR,BUFLIN:NEAR
end if
; EXTRN	DOT:WORD,ERRFLG:WORD,ERRLIN:WORD
if @GW_PASS = 1

;EDIT COMMAND

; PUBLIC	EDIT
@EDIT:	CALL	@LINSPC  ; LINE NUMBER IN DE
	JNZ	@SCNEDT@_EFCERR  ; STATEMENT MUST HAVE ENDED
@SCNEDT@_EREDIT:	POP	BX  ; REMOVE NEWSTT(OR CALL FROM MAIN)RETURN
	MOV	word [@DOT],DX
	CALL	@FNDLIN  ; FIND LINE
	JNB	@SCNEDT@_EUSERR  ; LINE DOES NOT EXIST
	MOV	BX,CX  ; CX=LINE PTR
@SCNEDT@_ERED2:	INC	BX
	INC	BX
	MOV	DX,word [BX+0]  ; DE=LINE NUMBER
	INC	BX
	INC	BX
@SCNEDT@_ERED3:	PUSH	BX
	MOV	byte [@F_EDIT],((1) and 0FFh)  ; SET FLAG INDICATING IN EDIT MODE
; (FORCES OPEN LINES DURING LIST)
; (AND TELLS INLIN TO START AT BEGIN OF LOGICAL)
	XCHG	BX,DX
@SCNEDT@_ERED4:	CALL	@LINPRT  ; PRINT THE LINE NUMBER
	POP	BX
	CMP	byte [BX+0],((9) and 0FFh)  ; LINE START WITH TAB?
	JZ	@SCNEDT@_ERED5
	MOV	AL,((" ") and 0FFh)
	CALL	@OUTDO  ; NO, PUT SPACE OUT
;ENTRY FOR EDIT ON KBUF IS HERE
@SCNEDT@_ERED5:
	MOV	byte [@F_EDIT],((1) and 0FFh)  ; SET FLAG INDICATING IN EDIT MODE
; (FORCES OPEN LINES DURING LIST)
; (AND TELLS INLIN TO START AT BEGIN OF LOGICAL)
	CALL	@BUFLIN  ; PUT LINE IN BUF AND SET UP HLPBFA
	MOV	BX,@BUF
	CALL	@LISPRT  ; PRINT THE LINE AND SET UP HLPCSR
	MOV	BL,byte [@CSRY]
	MOV	BH,byte [@CSRX]
	JMP	@MAIN
@SCNEDT@_EFCERR:	JMP	@FCERR  ; Indirect jump to FCERR
@SCNEDT@_EUSERR:	JMP	@USERR  ; Indirect jump to USERR

;Help key edit

@SCNEDT@_INLHLP:	TEST	byte [@F_EDPG],((255) and 0FFh)
	JNZ	@SCNEDT@_INLHL0  ; BRIF do help edit on program statement
;Help during input statement
	JMP	@SCNEDT@_INLOP3  ; Just output char

;DO EDIT ON DOT
@SCNEDT@_INLHL0:	POP	AX  ; Remove call to this routine

;See if edit on error line number
	MOV	DX,word [@ERRLIN]
	CALL	@SCNEDT@_ERRED2  ; If exists,do edit on error line number

;See if edit on current line number
	MOV	DX,word [@CURLIN]
	CALL	@SCNEDT@_ERRED2  ; If exists,do edit on current line number
;ERRLIN AND CURLIN ARE DIRECT, DO EDIT ON KBUF
end if
; EXTRN	KBUF:WORD,CURLIN:WORD
if @GW_PASS = 1
; EXTRN	SCNEXT:NEAR,DEPTR:NEAR
	CALL	@DEPTR  ; Remove line pointers from program
	MOV	BX,@KBUF
	PUSH	BX
	DEC	BX
	CALL	@SCNEXT  ; Remove any line pointers from KBUF
	POP	BX
	JMP	@SCNEDT@_ERED5

;AUTOMATIC EDIT FOR ERRORS

; PUBLIC	ERREDT
@ERREDT:	MOV	byte [@ERRFLG],AL  ; Reset the flag to call edit
	MOV	DX,word [@ERRLIN]  ; Get the line number
@SCNEDT@_ERRED2:	CMP	DX,65535  ; See if it was direct
	JZ	@SCNEDT@_ERRED3  ; Go back if direct
	OR	DX,DX
	JZ	@SCNEDT@_ERRED3  ; Go back if zero
	JMP	@SCNEDT@_EREDIT
@SCNEDT@_ERRED3:	RET
; SUBTTL  ASCII LOAD and SAVE line handler

;LOAD ASCII:
;  PROGRAM LINE INPUT FROM DISK

; EXTRN	ISFLIO:NEAR,OUTDO:NEAR,INCHR:NEAR,LBOERR:NEAR
@SCNEDT@_DSKCHI:
	CALL	@ISFLIO  ; Set FLAGS.NZ if PTRFIL points to active file
	JNZ	@SCNEDT@_ISLOAD  ; BRIF LOAD statement
	RET  ; If so use special screen io
@SCNEDT@_ISLOAD:	POP	AX  ; Discard Return Address
	MOV	CL,((@BUFLEN) and 0FFh)  ; Setup the maximum character count
	MOV	BX,@BUF  ; Place we are going to stoer the line
@SCNEDT@_LOPBUF:	CALL	@INCHR  ; Get a character from the file
; (will call indskc and handle eof)
	MOV	byte [BX+0],AL  ; Store the character
	CMP	AL,((13) and 0FFh)  ; Is it the end (a CR)
	JNZ	@SCNEDT@_INOTCR  ; Not a [CR]
	CMP	byte [BX-1],((10) and 0FFh)  ; Preceeded by a line feed?
	JZ	@SCNEDT@_LOPBUF  ; Yes, ignore the [CR]
	JMP	@SCNEDT@_FINLIN  ; No, this is the end of a line
@SCNEDT@_INOTCR:
	OR	CL,CL
	JE	@SCNEDT@_LTLONG  ; Branch if line is too long to fit in BUF
	CMP	AL,((10) and 0FFh)  ; LEADING LINE FEEDS MUST BE IGNORED
	JNZ	@SCNEDT@_INOTLF
	CMP	CL,((@BUFLEN) and 0FFh)  ; CL=BUFLEN if this is the 1st char on the line
	JZ	@SCNEDT@_LOPBUF  ; Branch if this was a leading line-feed
@SCNEDT@_INOTLF:	INC	BX  ; ADVANCE THE POINTER
	DEC	CL
	JMP	@SCNEDT@_LOPBUF  ; DO NEXT CHAR
	DEC	CL
@SCNEDT@_FINLIN:
	MOV	byte [BX+0],((0) and 0FFh)
	MOV	BX,@BUF-1  ; POINT AT BUFMIN
	RET

@SCNEDT@_LTLONG:	JMP	@LBOERR  ; Report LINE BUFFER OVERFLOW error
; (This program wasn't created by BASIC)

;SAVE ASCII:
;   PROGRAM LISTING CHAR OUTPUT TO DISK(CONVERT <LF> TO <LF><CR>)

; PUBLIC	OUTCH1
@OUTCH1:	CMP	AL,((@CHRLNF) and 0FFh)
	JZ	@SCNEDT@_OUTCH0  ; IS LF
	JMP	@OUTDO
@SCNEDT@_OUTCH0:
; EXTRN	ISFLIO:NEAR
	CALL	@ISFLIO
	JNZ	@SCNEDT@_OUTCH2  ; branch if outputting to file
	CALL	@OUTDO
	RET

@SCNEDT@_OUTCH2:	CALL	@OUTDO
	MOV	AL,((@CHRRET) and 0FFh)
	CALL	@OUTDO
	MOV	AL,((@CHRLNF) and 0FFh)
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
