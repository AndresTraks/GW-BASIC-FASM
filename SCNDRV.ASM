; [ This translation created 10-Feb-83 by Version 4.3 ]

if @GW_PASS = 1

include 'OEM.H'

; TITLE   SCNDRV  This is the OS independent Screen Driver for GW BASIC
; SUBTTL  DATA DEFINITIONS - Miscellaneous

; COMMENT	*
; 	--------- --- ---- -- ---------
; 	COPYRIGHT (C) 1982 BY MICROSOFT
; 	--------- --- ---- -- ---------

; 	PROGRAMMER: MARC WILSON

; 	*
include 'GIO86U'

;OEM IFNDEFs
@SCNDRV@_MELCO=0
@SCNDRV@_CANON=0

;GENERIC IFNDEF'S:
@SCNDRV@_TERMSW=0
@SCNDRV@_HLPEDT=0
@SCNDRV@_NMPAGE=1  ;Number of pages
@SCNDRV@_NEWCHP=1  ;New change page routine
@SCNDRV@_IBMEOL=@IBMLIK  ;Clear to EOL for COMPATIBILITY
@SCNDRV@_IBMCSR=@IBMLIK  ;IBM COMPATIBILITY for cursor

;Definition of scroll types
; Choice of scroll type is by switch SCROLT.
; Switches defined here are used to implement a specific SCROLT type.
; If other scroll types are needed then additional SCROLT types should be
;   defined here.
	@SCNDRV@_INVLIN=@SCROLT  ;Invisible (function key) Line
	@SCNDRV@_FKFSRL=(@SCROLT-1) AND 1  ;Clear fkeys/full scroll/rewrite fkeys

;OTHER GENERIC SWITCHES(OEM SPECIFIC)
	@SCNDRV@_TXTWDO=0  ;list of OEM's which have window setting capability

; SUBTTL  DATA DEFINITIONS - Internal routines(with usage description)

;Entry points
; PUBLIC	SCNSWI
;on entry:  AL=width, CL=height

; PUBLIC	SCNCLR
; Home Graphics and Text Cursors
;on entry:  none

; PUBLIC	SCNLOC
;on entry:  AH=column(x), AL=line(y)

; PUBLIC	SCNOUT
;on entry:  AX=character

; PUBLIC	SCNRDL
;on entry:  DI=address of where to put string, CX=max count
;on exit:   CX=CX-number of characters read
;           DI=DI+number of characters read

; PUBLIC	SCNPOS
;on exit:   DL=cursor line, DH=cursor column

; PUBLIC	SCNRDT
;on entry:  DL=line number
;on exit:   AH= terminator column, AL=terminator value
;           Flags indicate terminator value:
;           CF=EOL, ZF=Linefeed

; PUBLIC	SCNGWI
;on exit:   AH=logical width of lines

; PUBLIC	SCNMRK
;on entry:  ZF set indicates use WDOLFT as column
;           ZF clear indicates use CSRX as column

; PUBLIC	SCNIPL

; PUBLIC	SCNBRK
; SUBTTL  DATA DEFINITIONS - External routines and data

;EXTERNAL ROUTINES
; EXTRN	SCROLL:NEAR
; EXTRN	SCROUT:NEAR
; EXTRN	SCRINP:NEAR
; EXTRN	CLREOL:NEAR

;THE FOLLOWING IS DATA UNIQUE TO THE SCNDRV MODULE
;       ALL DATA IS ONE BYTE LONG UNLESS STATED OTHERWISE
end if
; EXTRN	LINCNT:WORD
; EXTRN	CRTWID:WORD
; EXTRN	WDOTOP:WORD
; EXTRN	WDOBOT:WORD
; EXTRN	WDOLFT:WORD
; EXTRN	WDORGT:WORD
; EXTRN	LINLEN:WORD
; EXTRN	LINTTB:WORD
; Two items per entry:
;   Terminator, last column
; EXTRN	TRMCUR:WORD
; EXTRN	FSTLIN:WORD
; EXTRN	FSTCOL:WORD
; EXTRN	LSTLIN:WORD
;   logical line grows.
; EXTRN	LSTCOL:WORD
;   line grows(always reflects last col on LSTLIN).
; EXTRN	F_CRET:WORD
; EXTRN	CSRY:WORD
; EXTRN	CSRX:WORD
; EXTRN	KEYSW:WORD

;THE FOLLOWING DATA IS ACCESSED BY SCNDRV BUT SET ELSEWHERE
; EXTRN	F_EDIT:WORD
; EXTRN	F_INST:WORD
if @GW_PASS = 1
; SUBTTL  DATA DEFINITIONS - Literals

;CHARACTER DEFINITIONS

	@SCNDRV@_CHREDT=1  ; EDiT
	@SCNDRV@_CHRBKW=2  ; BacK Word
	@SCNDRV@_CHRCAN=3  ; CANcel
	@SCNDRV@_CHRHCN=4  ; Hard CaNcel
	@SCNDRV@_CHRCLE=5  ; CLear to End of line
	@SCNDRV@_CHRFDW=6  ; ForwarD Word
	@SCNDRV@_CHRBEL=7  ; BELl
	@SCNDRV@_CHRBAK=8  ; BAcKspace
	@SCNDRV@_CHRTAB=9  ; TAB
	@SCNDRV@_CHRLNF=10  ; LiNeFeed
	@SCNDRV@_CHRHOM=11  ; HOMe
	@SCNDRV@_CHRERA=12  ; ERAse
	@SCNDRV@_CHRRET=13  ; RETurn
	@SCNDRV@_CHRAPP=14  ; APPend
	@SCNDRV@_CHRINS=18  ; INSert
	@SCNDRV@_CHRFKD=20  ; Function Key Display key
	@SCNDRV@_CHRLDL=21  ; Line DeLete
	@SCNDRV@_CHRADV=28  ; cursor RiGhT
	@SCNDRV@_CHRREG=29  ; cursor LeFT
	@SCNDRV@_CHRUP=30  ; cursor UP
	@SCNDRV@_CHRDWN=31  ; cursor DoWN
	@SCNDRV@_CHRDEL=127  ; DELete

;TERMINATOR TABLE LITERALS
; PUBLIC	TRMLNF
	@TRMLNF=10  ; LINEFEED terminator
; PUBLIC	TRMEOL
	@TRMEOL=127  ; EOL terminator
; PUBLIC	TRMWRP
	@TRMWRP=0  ; WRAP terminator
; PUBLIC	TRMNWP
	@TRMNWP=1  ; NULL WRAP terminator
; PUBLIC	TRMNUL
	@TRMNUL=128  ; Sign bit indicates initialize line

;DEFAULT SCREEN SIZE
; PUBLIC	SCNSIZ
	@SCNSIZ=20+(40*256)  ; Height = 20, Width = 40

; SUBTTL  SCNIPL, SCNSWI AND SCNWDO   The parameter setting routines

;SUBROUTINE SCNIPL():           ; Initialize
;**
@SCNIPL:
end if
; EXTRN	ESCFLG:WORD
if @GW_PASS = 1
	MOV	byte [@ESCFLG],((0) and 0FFh)
	RET
;** END SUBROUTINE SCNIPL

;BREAK - reset flags etc. when ^C typed.

@SCNBRK:	MOV	byte [@FSTLIN],((0) and 0FFh)
	MOV	byte [@LSTLIN],((255) and 0FFh)  ; Set FSTPOS, LSTPOS to impossible values
	MOV	byte [@F_CRET],((255) and 0FFh)  ; Clear "last char was CR" flag
	RET

;SUBROUTINE SCNSWI(WIDTH,HEIGHT):       ; Set screen width(logical/physical) and height
;**                     on entry:   AL=width, CL=height
;**
@SCNSWI:	MOV	byte [@CRTWID],AL  ; Save physical width
	MOV	byte [@LINLEN],AL  ; Set logical line length
	MOV	byte [@LINCNT],CL  ; Save physical height
	MOV	byte [@WDOTOP],((1) and 0FFh)  ; Init window top
	PUSH	CX
	DEC	CL  ; Reserve status line
	MOV	byte [@WDOBOT],CL  ; Set window bottom
	POP	CX
	MOV	byte [@WDOLFT],((1) and 0FFh)  ; Set window left
	MOV	byte [@WDORGT],AL  ; Set window right
	RET
;** *** END
;** END SUBROUTINE SCNSWI

;SUBROUTINE SCNWDO(POSN,COUNT): ; Set text window
;**
;**                             on entry:   AH=column posn, AL=line posn
;**                                         CH=width, CL=height
;**                             on exit:    AX,CX=values actually set
;**                                         CF indicates posn outside screen
;**
;**                             NOTE: This routine truncates width and height.
;**
;** IF POSN IS CONTAINED WITHIN PHYSICAL SCREEN BEGIN
; SUBTTL CURSOR READ/WRITE

;SUBROUTINE SCNLOC(X,Y):        ; Locate cursor on physical screen
;**                         on entry:   AH=column, AL=line(1,1 is home)
;**
@SCNLOC:	MOV	byte [@CSRX],AH
	MOV	byte [@CSRY],AL
	RET
;** END SUBROUTINE SCNLOC

;SUBROUTINE SCNCLR(X,Y):        ; Clear Screen, Home Text & Graphics Cursor,
;                               ; Refresh Function Key Display
;**                         on entry:

; EXTRN	KEYDSP:NEAR,GRPINI:NEAR
@SCNCLR:
	CALL	@SCNDRV@_TTBINI  ;Clear the terminator table
	CALL	@GRPINI  ;Home the graphics cursor
	CALL	@SCNDRV@_WHOME  ;DX=cursor home
	MOV	AX,DX
	CALL	@SCNLOC  ;set cursor position
	JMP	@KEYDSP  ;Conditionally display softkeys and return
;** END SUBROUTINE SCNCLR

;SUBROUTINE SCNPOS              ; Read current cursor location
@SCNPOS:	MOV	DH,byte [@CSRX]
	MOV	DL,byte [@CSRY]
	PUSHF
	CMP	DH,byte [@LINLEN]
	JBE	@SCNDRV@_SCNPS1  ;BRIF not beyond edge of screen
	MOV	DH,byte [@LINLEN]  ;Force posn within screen
@SCNDRV@_SCNPS1:	POPF
	RET
;** END SUBROUTINE SCNPOS

;SUBROUTINE SCNGWI              ; Read current logical width
;**                         on exit:    AH=width
;**
@SCNGWI:	MOV	AH,byte [@LINLEN]
	RET
;** END SUBROUTINE SCNGWI
; SUBTTL  TERMINATOR TABLE READ/WRITE/INITIALIZE

;SUBROUTINE SCNRDT(Y):          ; Read terminator value and column
;**                         on entry:   DL=line number
;**                         on exit:    AH=terminator posn, AL=terminator value
;**                                     If CF=1; EOL
;**                                     If CF=0 and ZF=1; LF terminated
;**
@SCNRDT:	PUSH	BX
	MOV	BL,DL  ; BX = Displacement into table
	ADD	BL,BL
	MOV	BH,((0) and 0FFh)
	MOV	word [@TRMCUR],BX  ; Save address of terminator reading(for set term)
	MOV	AH,byte [@LINTTB-2+BX]  ; Get terminator posn
	MOV	AL,byte [@LINTTB-1+BX]  ; Get terminator value
	AND	AL,((255-@TRMNUL) and 0FFh)  ; Get rid of initialize line status bit
	CMP	AL,((@TRMEOL) and 0FFh)
	STC
	JZ	@SCNDRV@_SCNRTX  ; BRIF EOL terminator(CF=1)
	CMP	AL,((@TRMLNF) and 0FFh)  ; CF=0, set ZF if linefeed terminated
	JNB	@SCNDRV@_SCNRTX  ; BRIF carry not set
	CMC  ; clear carry
@SCNDRV@_SCNRTX:	POP	BX
	RET
;** END SUBROUTINE SCNRDT

;SUBROUTINE SCNWTT(TERM)        ; Set new value for terminator last read
;**                     on entry:   AH=column where physical line ends
;**                                 AL=terminator type(one of: TRMEOL, TRMLNF
;**                                     TRMWRP, TRMNWP)
;**
@SCNDRV@_SCNWTT:	PUSH	BX
	MOV	BX,word [@TRMCUR]  ; Get address of terminator last read
	MOV	byte [@LINTTB-2+BX],AH
	AND	byte [@LINTTB-1+BX],((@TRMNUL) and 0FFh)
	OR	byte [@LINTTB-1+BX],AL  ; Write new terminator, leaving NULL bit
	POP	BX
	RET
;** END SUBROUTINE SCNWTT

;TERMINATOR TABLE INIT

@SCNDRV@_TTBINI:	MOV	CX,@NMLINE+1  ; CX=count of line term table entries
	MOV	BX,@LINTTB  ; BX=addr of line term table
@SCNDRV@_TTBIN0:	MOV	byte [BX+0],((0) and 0FFh)  ; Clear column number
	MOV	byte [BX+1],((@TRMEOL) and 0FFh)  ; Set terminator to <CR>
	INC	BX
	INC	BX
	LOOP	@SCNDRV@_TTBIN0  ; Init entire line terminator table
	RET
; SUBTTL  CHARACTER OUTPUT

;SUBROUTINE SCNOUT(CHAR):       ; Output character
;**                         on entry:   AX= character
;**

@SCNOUT:	PUSH	DX
	PUSH	CX
	PUSH	BX
	CALL	@SCNDRV@_CTLDSP  ; If control char or ESC sequence, do operation
	JB	@SCNDRV@_SCNOTX  ; No char to output
	CALL	@SCNDRV@_CHWRAP  ; Do wrap for char in AX, return DX=posn for output
; EXTRN	SETCSR:NEAR
end if
; EXTRN	CSRTYP:WORD
if @GW_PASS = 1
	MOV	byte [@CSRTYP],((0) and 0FFh)  ; Set next cursor type to off
	CALL	@SETCSR  ; Insure that the cursor is off

	CALL	@SCROUT  ; Send char in AX to BIOS at DX posn
	MOV	byte [@F_CRET],((255) and 0FFh)  ; Clear last char was Carriage return flag
@SCNDRV@_SCNOTX:	POP	BX
	POP	CX
	POP	DX
	RET
;** END SUBROUTINE SCNOUT

;SUBROUTINE MKRMCI              ; Open up sapce for char if insert mode

@SCNDRV@_MKRMCI:	PUSHF
	TEST	byte [@F_INST],((255) and 0FFh)
	JZ	@SCNDRV@_MKRCIX  ; BRIF not insert mode(do nothing)
	POPF
	MOV	CH,AL
	INC	CH  ; CH=space needed
	CALL	@SCNDRV@_MKRMCH  ; Open up space at (DH,DL) for count of CH
	CALL	@SCNDRV@_SCNRDX  ; Put terminator table values in CX
	RET
@SCNDRV@_MKRCIX:	POPF
	RET

@SCNDRV@_SCNRDX:	XCHG	AX,CX
	CALL	@SCNRDT
	XCHG	AX,CX
	RET
; SUBTTL  LINE WRAP LOGIC - Character wrap

;THE LINE WRAP LOGIC IS USED PRIOR TO OUTPUTTING CHARACTERS OR STRINGS
;   IT WILL RESERVE THE NECESSARY NUMBER OF CHARACTERS ON THE CURRENT
;   LOGICAL LINE OR WILL RETURN CARRY SET AND DX=POSN WHERE CHARACTER
;   CAN BE OUTPUT(I.E. IT RETURNS A POSN LESS THAN CURRENT POSN)

;SUBROUTINE CHWRAP(CHAR):       ; Do single character wrap
;**                     on entry:   AX=character
;**                                 DH=CSRX, DL=CSRY
;**                     on exit:    if cannot wrap, CF=1
;**                                 DX=posn where character can be output
;**                                 cursor posn and terminator table are updated
;**                     NOTE: if CF=1 then DX may be set to a previous posn
;**                         where there is enough room to EOL.
;**
@SCNDRV@_CHWRAP:	PUSH	AX
	XOR	CH,CH
	OR	AH,AH
	JZ	@SCNDRV@_CHWRP0  ; BRIF Single byte character
	MOV	CH,((1) and 0FFh)  ; It's two byte character
@SCNDRV@_CHWRP0:	MOV	CL,CH
	ADD	CH,DH  ; CH=column after char is output
	CALL	@SCNRDT  ; Read terminator
	XCHG	CX,AX
;** IF POSN .LT. EOL BEGIN
;** AT THIS POINT AH=POSN(WHERE GOING TO), DX=CURRENT POSN,
;** AL=LENGTH OF CHARACTER, CX=CURRENT TERMINATORS
	PUSHF
	CMP	AH,byte [@LINLEN]
	JA	@SCNDRV@_CHWRP1  ; BRIF not space before end of physical line
	POPF
	CALL	@SCNDRV@_MKRMCI  ; If insert mode, open up space for character
;** *** IF NOT(LINEFEED .EQ. TERMINATOR(CURRENT_LINE) AND POSN .EQ. LINLEN)
;** *** *** RETURN, OUTPUT IS AT CURRENT POSN
	JB	@SCNDRV@_CHWPXI  ; EOL terminated, output at current posn
	JZ	@SCNDRV@_CHWPLF  ; BRIF LF terminated
	CMP	CL,((@TRMWRP) and 0FFh)
	JZ	@SCNDRV@_CHWPXI  ; BRIF WRAP(always room)
	CMP	AH,byte [@LINLEN]
	JB	@SCNDRV@_CHWPXI  ; BRIF NUL_WRAP and not overwriting NULL
	MOV	CL,((@TRMWRP) and 0FFh)
@SCNDRV@_CHWPXI:	JMP	@SCNDRV@_CHWRPX  ; Overwriting NULL_WRAP, set to WRAP
@SCNDRV@_CHWPLF:	CMP	AH,byte [@LINLEN]
	JAE	@SCNDRV@_CHWPL1  ; LF terminated and no room for LF
	INC	AH  ; Need to terminate at one past posn printing at
	XCHG	AX,CX
	CMP	AH,CH
	MOV	AH,CH
	JA	@SCNDRV@_CHWPL0  ; BRIF current posn below terinator posn
	CALL	@SCNDRV@_SCNWTT  ; Terminate line at one more than print posn
@SCNDRV@_CHWPL0:	CLC
	XCHG	AX,CX
	PUSHF
	DEC	AH  ; Restore column actually printing at
	JMP	@SCNDRV@_CHWRP9  ; Update LSTPOS, FSTPOS, cursor posn, exit
;** *** *** ELSE MOVE LINEFEED TO NEXT LINE
@SCNDRV@_CHWPL1:	CALL	@SCNDRV@_WRAPLF  ; Move linefeed to next line
	JB	@SCNDRV@_CHWRNI  ; Error, output at posn-(char length)
	CLC
	PUSHF
	MOV	AH,CH
	JMP	@SCNDRV@_CHWRP9  ; Exit without updating terminator
@SCNDRV@_CHWRNI:	JMP	@SCNDRV@_CHWRNO
;** *** END

;** *** DO CASE TERMINATOR(CURRENT_LINE) OF
;** *** There is not enough room on current line for character
@SCNDRV@_CHWRP1:	POPF
	JB	@SCNDRV@_CHWREL  ; BRIF EOL terminated
	JZ	@SCNDRV@_CHWRLF  ; BRIF LF terminated
;** *** CASE: WRAP; NULL_WRAP; BEGIN
;** *** *** *** SET WRAP TERMINATOR
@SCNDRV@_CHWRWP:	MOV	CL,((@TRMWRP) and 0FFh)
	MOV	CH,byte [@LINLEN]
	XCHG	AX,CX
	CALL	@SCNDRV@_SCNWTT  ; Set wrap terminator at last column
	CMP	DL,byte [@LSTLIN]
	JNZ	@SCNDRV@_CHWRN0  ; BRIF not on last line
	INC	byte [@LSTLIN]  ; Wrap LSTLIN
	MOV	byte [@LSTCOL],((0) and 0FFh)  ; Force update of LSTCOL at CHWRPZ
@SCNDRV@_CHWRN0:	INC	DL  ; Next line
	CALL	@SCNRDT  ; Set up for write at new line
	MOV	DH,byte [@WDOLFT]  ; First column is output posn
	MOV	CH,DH
	ADD	CH,CL  ; CH=POSN going to
	XCHG	AX,CX
	CALL	@SCNDRV@_MKRMCI  ; If insert mode, open up space for character
	CMP	CL,((@TRMLNF) and 0FFh)
	JNZ	@SCNDRV@_CHWRPX  ; BRIF not linefeed terminated
	XCHG	AX,CX  ; CH=POSN, AX=current terminators
	INC	CH  ; Need terminator one beyond actual output
	CMP	AH,CH
	MOV	AH,CH
	JA	@SCNDRV@_CHWRN2  ; BRIF Current terminator beyond posn for output
	CALL	@SCNDRV@_SCNWTT  ; Set current terminator to new max posn
@SCNDRV@_CHWRN2:	DEC	CH  ; Restore POSN going to
	XCHG	AX,CX
@SCNDRV@_CHWRPX:	CLC
	JMP	@SCNDRV@_CHWRPZ  ; All done
;** *** *** *** END
;** *** *** END
;** *** CASE: EOL
@SCNDRV@_CHWREL:	CALL	@SCNDRV@_MKRMNL  ; Make room on next line(make it EOL term'd)
	JB	@SCNDRV@_CHWRP3  ; If error, make room for char on this line
	CALL	@SCNDRV@_SCNRDX  ; Reread terminator for this line
	JMP	@SCNDRV@_CHWRWP  ; Wrap to next line
;** *** CASE: LF
@SCNDRV@_CHWRLF:	XCHG	AX,CX
	CALL	@SCNDRV@_WRAPLF  ; First wrap LF to next line
	MOV	AL,((@TRMNWP) and 0FFh)  ; Set to temporary NULL_WRAP at last column
	MOV	AH,byte [@LINLEN]
	CALL	@SCNDRV@_SCNWTT
	XCHG	AX,CX
	JNB	@SCNDRV@_CHWRWP  ; Go do wrap for char
;No room, abort
@SCNDRV@_CHWRP3:	MOV	AH,byte [@LINLEN]  ; AH=POSN going to
@SCNDRV@_CHWRNO:	MOV	DH,AH
	SUB	DH,AL  ; DH=POSN-(char len)
	STC  ; Error return
;** *** END CASE TERMINATOR(CURRENT_LINE)

;** EXIT
@SCNDRV@_CHWRPZ:	PUSHF
	XCHG	AX,CX  ; CH=POSN, AX=current terminators
	CMP	AH,CH
	MOV	AH,CH
	JA	@SCNDRV@_CHWRP9  ; BRIF Current terminator beyond posn for output
	PUSH	AX
	CALL	@SCNRDT
	POP	AX
	CALL	@SCNDRV@_SCNWTT  ; Set current terminator to new max posn
@SCNDRV@_CHWRP9:	MOV	byte [@CSRY],DL
	CMP	DL,byte [@LSTLIN]
	JNZ	@SCNDRV@_CHWNTL  ; BRIF not on last logical line
	CMP	AH,byte [@LSTCOL]
	JB	@SCNDRV@_CHWNTL  ; BRIF not new last position
	MOV	byte [@LSTCOL],AH  ; Set new last posn
@SCNDRV@_CHWNTL:	CMP	DL,byte [@FSTLIN]
	JNZ	@SCNDRV@_CHWNTF  ; BRIF not on first logical line
	CMP	DH,byte [@FSTCOL]
	JAE	@SCNDRV@_CHWNTF  ; BRIF not new first position
	MOV	byte [@FSTCOL],DH
@SCNDRV@_CHWNTF:	INC	AH
	MOV	byte [@CSRX],AH  ; Set new posn(one past last posn printed at)
	CMP	byte [@LINLEN],AH
	JAE	@SCNDRV@_CHWNTG  ; BRIF does not go beyond end of physical line
	CALL	@SCNRDT
	JB	@SCNDRV@_CHWNTG  ; BRIF line does not continue
	INC	byte [@CSRY]  ;   Logical line continues, put cursor at
	MOV	AH,byte [@WDOLFT]  ;       start of next physical line
	MOV	byte [@CSRX],AH
@SCNDRV@_CHWNTG:	POPF
	POP	AX
	RET
;Wrap linefeed on end of line to next line
@SCNDRV@_WRAPLF:	PUSH	word [@TRMCUR]
	PUSH	CX
	PUSH	DX
	MOV	DH,byte [@LINLEN]
	MOV	CH,((1) and 0FFh)
	CALL	@SCNDRV@_MKRMCH  ; Insert one space before LF
	POP	CX
	MOV	CL,DL
	POP	DX
	XCHG	CX,DX
	POP	word [@TRMCUR]
	RET
; SUBTTL  LINE WRAP LOGIC - Open next line for wrap

;SUBROUTINE MKRMNL(line)        ; Make the next line a blank, empty line
;**                     on entry:   DL=current line number
;**                     on exit:    DL=current line number(may change from entry)
;**                                 if CF=1 no room available
;**
@SCNDRV@_MKRMNL:	PUSH	AX
	PUSH	BX
	PUSH	CX
	PUSH	DX
@SCNDRV@_MKRMN0:	CALL	@SCNRDT
	JB	@SCNDRV@_MKRMN5
	CMP	DL,byte [@WDOBOT]
	JZ	@SCNDRV@_MKRMN6
	JB	@SCNDRV@_MKRMN4
	MOV	DL,byte [@WDOBOT]
	JMP	@SCNDRV@_MKRMN0
@SCNDRV@_MKRMN4:	INC	DL
	JMP	@SCNDRV@_MKRMN0

;** IF CURRENT_PHYSICAL .LT. WINDOW_BOTTOM
@SCNDRV@_MKRMN5:	CMP	DL,byte [@WDOBOT]
@SCNDRV@_MKRMN6:	POP	DX
	PUSH	DX  ; Get back posn to scroll from
	JZ	@SCNDRV@_MKRMN7  ; BRIF at bottom of window(scroll up)
	CMC
	JB	@SCNDRV@_MKRMNZ  ; BRIF outside of window
	CMP	DL,byte [@WDOTOP]
	JB	@SCNDRV@_MKRMNZ  ; BRIF outside of window
	TEST	byte [@F_EDIT],((255) and 0FFh)
	JZ	@SCNDRV@_MKRMNZ  ; BRIF not editing, no need to scroll
	INC	DL  ; Scroll down starting at next line
;** *** SCROLL DOWN
	CALL	@SCNDRV@_SCRLD0  ; Scroll down to end of window
@SCNDRV@_MKRMNY:	CLC  ; Indicate successful
@SCNDRV@_MKRMNZ:	POP	DX  ; Restore current line number
	JMP	@SCNDRV@_MKRMNX
;** *** ELSE IF (FIRST_PHYSICAL(LOGICAL) .NE. WINDOW_TOP) OR NOT(INPUT_EDIT)
@SCNDRV@_MKRMN7:	TEST	byte [@F_EDIT],((255) and 0FFh)
	JZ	@SCNDRV@_MKRMN9  ; BRIF not input edit, always allow scroll
@SCNDRV@_MKRMN8:	CALL	@SCNDRV@_CSRUP
	JB	@SCNDRV@_MKRMNZ  ; BRIF logical line starts at top of window(abort)
	PUSH	AX
	CALL	@SCNRDT
	POP	AX
	JNB	@SCNDRV@_MKRMN8  ; BRIF previous physical part of this logical
;** *** SCROLL UP
@SCNDRV@_MKRMN9:	POP	DX
	PUSH	DX
	CMP	DL,byte [@WDOBOT]  ; Full screen scroll?
	JAE	@SCNDRV@_MKRMNF  ; BRIF scroll up entire screen
	CALL	@SCNDRV@_SCRLUD  ; Scroll up from DL to WDOTOP
	JMP	@SCNDRV@_MKRMNU
@SCNDRV@_MKRMNF:	CALL	@SCNDRV@_SCRLUP  ; Scroll up entire window
@SCNDRV@_MKRMNU:	POP	DX
	CALL	@SCNDRV@_CSRUP  ; Return line number of original line
	CLC
@SCNDRV@_MKRMNX:	POP	CX
	POP	BX
	POP	AX
	RET
; SUBTTL  SCROLL ROUTINES - Scroll up and down

;Scroll up from DL to WDOTOP
@SCNDRV@_SCRLUD:	PUSH	CX
	MOV	CL,DL
	MOV	DL,byte [@WDOTOP]
	JMP	@SCNDRV@_SCRLU1
;SCROLL UP
@SCNDRV@_SCRLUP:	MOV	DL,byte [@WDOTOP]  ; Top line number
;Scroll up from DL to bottom
@SCNDRV@_SCRLU0:	PUSH	CX
	MOV	CL,byte [@WDOBOT]
@SCNDRV@_SCRLU1:	PUSH	AX
	PUSH	BX
	PUSH	DX
	MOV	AL,DL
	MOV	BL,DL  ; From = To = Top line number
	INC	AL  ; From = To + 1
	MOV	BH,byte [@WDOLFT]
	MOV	AH,BH  ; From column = To column = left margin
	SUB	CL,BL  ; CL = line count
	JA	@SCNDRV@_SCRUL1  ; BRIF two or more line scroll
	JB	@SCNDRV@_SCRUL4  ; BRIF TOP > BOTTOM(should never happen)
	PUSH	AX
	MOV	DL,BL
	JMP	@SCNDRV@_SCRUL3  ; TOP=BOTTOM, just init line
@SCNDRV@_SCRUL1:	PUSH	AX
	MOV	CH,byte [@CRTWID]  ; Scroll entire lines
	CALL	@SCROLL  ; Scroll screen
;If CSRY, FSTLIN, LSTLIN are within scroll, decrement their values
	ADD	AL,CL  ; AL=Last line scrolled + 1
	DEC	AL  ; AL=Bottom line scrolled
; BL=Top line scrolled
	MOV	AH,((255) and 0FFh)  ; decrement line# variables in scroll window
	CALL	@SCNDRV@_TSTSCR
	MOV	DL,AL  ; DL=bottom line of scroll (initialize it)
;Clear the last line of the scroll
@SCNDRV@_SCRUL3:	MOV	DH,byte [@WDOLFT]
	POP	AX
	OR	CL,CL
	JE	@SCNDRV@_SCRUL4  ; No scroll(one line init)
	CALL	@SCNDRV@_SCRUTT  ; Scroll up terminator table
@SCNDRV@_SCRUL4:	CALL	@SCNDRV@_PLINIT  ; Init physical line from (DL,DH) to (DL,WDORGT)
	POP	DX
	POP	BX
	POP	AX
	POP	CX
	RET

;TSTSCR is called after Scrolling Up or Down to update Line Number variables
; which may be in the scroll window
; Entry - BL=top line number of scroll window
;         AL=bottom line number of scroll window
;         AH=1 if line# variables are to be incremented, -1 if decremented

@SCNDRV@_TSTSCR:	PUSH	SI
	PUSH	AX
	MOV	SI,@CSRY
	CALL	@SCNDRV@_TSTWDO  ; Adjust CSRY if its within scroll window
	MOV	AH,byte [@WDOTOP]
	CMP	byte [SI+0],AH
	JB	@SCNDRV@_TCSRY1  ; BRIF CSRY above top of window
	MOV	AH,byte [@WDOBOT]
	CMP	byte [SI+0],AH
	JNA	@SCNDRV@_CSRYOK  ; BRIF CSRY didn't increment beyond bottom
@SCNDRV@_TCSRY1:	MOV	byte [SI+0],AH  ; Bring it back to within scroll window
@SCNDRV@_CSRYOK:	MOV	SI,@FSTLIN
	POP	AX
	CALL	@SCNDRV@_TSTWDO  ; Adjust FSTLIN if its within scroll window
	MOV	SI,@LSTLIN
	CALL	@SCNDRV@_TSTWDO  ; Adjust LSTLIN if its within scroll window
	POP	SI
	RET

; If BL .LEQ. [SI] .LEQ. AL then [SI]=[SI]+AH

@SCNDRV@_TSTWDO:
	CMP	AL,byte [SI+0]
	JB	@SCNDRV@_NINWDO  ; BRIF [SI] not within scroll
	CMP	BL,byte [SI+0]
	JA	@SCNDRV@_NINWDO  ; BRIF [SI] not within scroll
	ADD	byte [SI+0],AH  ; Adjust [SI] for scroll
@SCNDRV@_NINWDO:	RET

;SCROLL DOWN
@SCNDRV@_SCRLDN:	MOV	DL,byte [@WDOTOP]
;Scroll down from DL to WDOBOT
@SCNDRV@_SCRLD0:	PUSH	AX
	PUSH	BX
	PUSH	CX
	MOV	AL,DL
	MOV	BL,DL  ; From = To = top of scroll
	INC	BL  ; To = From + 1
	MOV	BH,byte [@WDOLFT]  ; Column = left margin
	MOV	AH,BH
	MOV	CL,byte [@WDOBOT]
	SUB	CL,AL  ; Count of lines =(window bottom)-top of scroll
	PUSH	AX
	JBE	@SCNDRV@_SCRDL3  ; BRIF null scroll, just clear line
	MOV	CH,byte [@WDORGT]  ; Scroll lines, not columns
@SCNDRV@_SCRLD1:	CALL	@SCROLL  ; Scroll screen
;If CSRY, FSTLIN, LSTLIN are within scroll, increment their values
	ADD	AL,CL  ; AL=Last line scrolled
	DEC	AL
	MOV	AH,((1) and 0FFh)  ; increment line# variables in scroll window
	CALL	@SCNDRV@_TSTSCR
;Clear the last line of the scroll(in DL)
@SCNDRV@_SCRDL3:	MOV	DH,byte [@WDOLFT]
	POP	AX
	OR	CL,CL
	JS	@SCNDRV@_SCRDL4  ; No scroll(out of window)
	JE	@SCNDRV@_SCRDL4  ; No scroll(one line init)
	CALL	@SCNDRV@_SCRDTT  ; Scroll down term table(mark last line init'd)
@SCNDRV@_SCRDL4:	CALL	@SCNDRV@_PLINIT  ; Init physical line from (DL,DH) to (DL,WDORGT)
	POP	CX
	POP	BX
	POP	AX
	RET

;SCROLL DOWN current line to next line
@SCNDRV@_SCRDLN:	PUSH	AX
	PUSH	BX
	PUSH	CX
	MOV	AX,DX  ; Start of scroll is current line
	MOV	AH,byte [@WDOLFT]
	MOV	BX,AX
	INC	BL  ; TO start is next line
	MOV	CH,byte [@WDORGT]
	MOV	CL,((1) and 0FFh)  ; Scroll one entir line
	PUSH	AX
	JMP	@SCNDRV@_SCRLD1  ; Do scroll and update LSTPOS, FSTPOS, CSRY
; SUBTTL  SCROLL ROUTINES - Support routines: scroll terminator table, line init

;Scroll up terminator table(same parameters as SCROLL)
;                   on entry:   (see SCROLL)
;                   on exit:    modifies AX, BX, CX

@SCNDRV@_SCRUTT:	PUSH	DX
	MOV	DL,BL
	CALL	@SCNRDT  ; TRMCUR=address of top of scroll
	MOV	BX,word [@TRMCUR]
	MOV	CH,((0) and 0FFh)
@SCNDRV@_SCRUTL:	MOV	AX,word [@LINTTB+BX]  ; Get a terminator
	MOV	word [@LINTTB-2+BX],AX  ; Save a terminator
	INC	BX
	INC	BX
	LOOP	@SCNDRV@_SCRUTL  ; Continue till done
	MOV	byte [@LINTTB-2+BX],((0) and 0FFh)  ; Terminate end line of scroll
	MOV	byte [@LINTTB-1+BX],((@TRMEOL) and 0FFh)
	POP	DX
	RET

;Scroll down terminator table(same parameters as SCROLL)
;                   on entry:   (see SCROLL)
;                   on exit:    modifies AX, BX, CX

@SCNDRV@_SCRDTT:
	PUSH	DX
	MOV	DL,AL
	ADD	DL,CL
	CALL	@SCNRDT  ; TRMCUR=displacement of bottom of scroll + 2
	MOV	BX,word [@TRMCUR]
	MOV	CH,((0) and 0FFh)
@SCNDRV@_SCRDTL:	SUB	BX,2  ; Next posn
	MOV	AX,word [@LINTTB-2+BX]  ; Get a terminator
	MOV	word [@LINTTB+BX],AX  ; Save a terminator
	LOOP	@SCNDRV@_SCRDTL  ; Continue till done
	MOV	byte [@LINTTB-2+BX],((0) and 0FFh)  ; Terminate end line of scroll
	MOV	byte [@LINTTB-1+BX],((@TRMEOL) and 0FFh)
	MOV	DL,byte [@WDOBOT]
	CALL	@SCNDRV@_SCNRTL
	JB	@SCNDRV@_SCRDT1  ; EOL term'd, all done
	JNZ	@SCNDRV@_SCRDT1
	DEC	AH
@SCNDRV@_SCRDT1:	MOV	AL,((@TRMEOL) and 0FFh)
	CALL	@SCNDRV@_SCNWTT  ; Make sure last line in window is EOL term'd
	POP	DX
	RET

;Physical line initialization
;               on entry:   (DH,DL) = start of initialization

@SCNDRV@_PLINIT:	PUSH	CX
	PUSH	AX
	CALL	@SCNRDT
	MOV	AH,DH
	DEC	AH
	PUSH	BX
	MOV	BX,word [@TRMCUR]  ; Terminate line to left of DH
	MOV	byte [@LINTTB-1+BX],((@TRMEOL) and 0FFh)
	MOV	byte [@LINTTB-2+BX],AH
	POP	BX
	POP	AX
@SCNDRV@_PLINI2:	CALL	@CLREOL  ; Clear to end of line from (DH,DL)
	POP	CX
	RET
; SUBTTL  LABEL Key Processing

;LABELK - If function key display is off then turn on and exit.
;         If function key display is on then advance display line and
;         redisplay.
;ENTRY  - DX = cursor position
;EXIT   - DX unmodified
;USES   - AX,BX,CX

; EXTRN	FKYADV:NEAR,KEYDSP:NEAR,FKYFMT:NEAR
end if
; EXTRN	KEYSW:WORD
if @GW_PASS = 1
@SCNDRV@_LABELK:	PUSH	AX
	PUSH	BX
	PUSH	CX
	PUSH	DX
	PUSH	SI
	PUSH	DI
	CMP	byte [@KEYSW],((0) and 0FFh)  ;Test for key on
	CALL	@FKYADV  ;If KEYSW was 0(ZF=0) then init PF start key,
;   else advance to next set of PF keys
;   return ZF=1 if advance beyond last of PF keys
	JZ	@SCNDRV@_LABOFF  ;Process key off request
	MOV	byte [@KEYSW],((255) and 0FFh)  ;Turn on key display flag
@SCNDRV@_LABDSP:	CALL	@KEYDSP  ;Display function keys
	POP	DI
	POP	SI
	POP	DX
	POP	CX
	POP	BX
	POP	AX
	RET

@SCNDRV@_LABOFF:
	MOV	byte [@KEYSW],((0) and 0FFh)  ;Turn the key flag off
	JMP	@SCNDRV@_LABDSP  ;Go clear the function key display line
; SUBTTL  Miscellaneous editor interface routines

;SUBROUTINE SCNMRK              ; Mark current position as first posn of logical
;**                 on entry:   ZF=1 indicates INPUT statement, AL=1 indicates
;**                                 EDIT statement.
;**                 on exit:    -
;**
@SCNMRK:	PUSHF
	MOV	DL,byte [@CSRY]
	MOV	DH,byte [@CSRX]
	DEC	AL
	JNZ	@SCNDRV@_SCNMK0  ; Not begin of EDIT statement
	CALL	@SCNDRV@_LSTART  ; Set (DH,DL)=start of current line
	PUSH	BX
	JMP	@SCNDRV@_SCNMK2
;** IF NOT TOP OF WINDOW
@SCNDRV@_SCNMK0:	CALL	@SCNDRV@_CSRUP  ; Move to previous line
	JB	@SCNDRV@_SCNMK1  ; BRIF at top of window
;** *** TERMINATE PREVIOUS PHYSICAL LINE
	CALL	@SCNDRV@_SCNRTL
	MOV	AL,((@TRMEOL) and 0FFh)  ; Make sure current line is start of logical line
	CALL	@SCNDRV@_SCNWTT
	INC	DL  ; Restore current line number
;** IF LINE IS MARKED WITH NULL
@SCNDRV@_SCNMK1:	CALL	@SCNRDT
	PUSH	BX
	MOV	BX,word [@TRMCUR]
	TEST	byte [@LINTTB-1+BX],((@TRMNUL) and 0FFh)
	JZ	@SCNDRV@_SCNMK2  ; BRIF not specially marked line
	PUSH	DX
	PUSH	CX
;** SCAN LINE FOR NULL CHAR(255 DECIMAL)
	MOV	DH,byte [@WDOLFT]
	MOV	CL,byte [@LINLEN]
@SCNDRV@_SCNMKL:	CALL	@SCRINP
	CMP	AL,((255) and 0FFh)
	JZ	@SCNDRV@_SCNML3  ; BRIF is specially marked line
@SCNDRV@_SCNML2:	INC	DH
	SUB	CL,((1) and 0FFh)
	JA	@SCNDRV@_SCNMKL  ; BRIF more chars to check
	OR	SP,SP
@SCNDRV@_SCNML3:
	POP	CX
	POP	DX
	JNZ	@SCNDRV@_SCNMK2  ; BRIF char was not on line, don't clear line
;** *** DELETE IT
	CALL	@SCNDRV@_LDELET  ; Delete this line
;** IF NOT DIRECT, SET LSTPOS, FSTPOS = CURRENT_POSN
@SCNDRV@_SCNMK2:
	MOV	byte [@CSRY],DL
	MOV	byte [@CSRX],DH  ; Update CURS_POSN in case of change
	POP	BX
	POPF
	JZ	@SCNDRV@_SCNMK3  ; INPUT statement, use current posn
	MOV	byte [@LSTLIN],((255) and 0FFh)  ; Direct, set FSTPOS, LSTPOS to min and max
	MOV	byte [@FSTLIN],((0) and 0FFh)
	JMP	@SCNDRV@_SCNMKX
@SCNDRV@_SCNMK3:	MOV	byte [@LSTLIN],DL
	MOV	byte [@FSTLIN],DL
	DEC	DH
	MOV	byte [@LSTCOL],DH  ; Mark LSTCOL one to left of current posn
	INC	DH
	MOV	byte [@FSTCOL],DH
@SCNDRV@_SCNMKX:	RET
;** END SUBROUTINE SCNMRK
; SUBTTL  Read logical line

;SUBROUTINE SCNRDL              ; Read a logical line
;**                     on entry:   ZF=1 indicates ignore FSTPOS, LSTPOS(statement
;**                                     line input).
;**                                 DX=current posn(within logical line to return)
;**                                 BX=buffer address
;**                                 CX=max count
;**                     on exit:    BX=last char address plus one
;**                                 CX=CX - (count of chars moved)
;**                                 DX=destroyed
;**
@SCNRDL:	PUSHF  ; Save statement input flag
;** Set DX=start of move
;** WHILE ((DL .NE FSTLIN) AND DL IN_SAME_LOGICAL_LINE)
@SCNDRV@_SCRD00:	CMP	DL,byte [@FSTLIN]
	JZ	@SCNDRV@_SCRD01  ; Found first line of logical
;** *** DL = PREVIOUS LINE
	CALL	@SCNDRV@_CSRUP
	JB	@SCNDRV@_SCRD01  ; At top of window, stop here
	CALL	@SCNRDT
	JNB	@SCNDRV@_SCRD00  ; Still same logical, continue
	INC	DL  ; Set DL = first physical of logical
;** IF (STATEMENT_INPUT OR (NOT ON FIRST_LINE))
@SCNDRV@_SCRD01:	POPF  ; We have start line, now get start column
	PUSHF
;** *** START_COLUMN=LEFT_MARGIN
	MOV	DH,byte [@WDOLFT]  ; Assume start at left margin
	JNZ	@SCNDRV@_SCRD02  ; BRIF statement input
	CMP	DL,byte [@FSTLIN]
	JNZ	@SCNDRV@_SCRD02  ; BRIF not on FIRST_LINE
;** *** ELSE START_COLUMN=FIRST_COLUMN
	MOV	DH,byte [@FSTCOL]

;** WHILE (POSN IS ON SAME LOGICAL) AND ((POSN .LTE. LSTPOS) OR STATEMENT_INPUT) BEGIN
@SCNDRV@_SCRD02:	POPF
	PUSHF
	JNZ	@SCNDRV@_SCRD03  ; BRIF statement input, ignore LSTPOS
	CMP	DL,byte [@LSTLIN]
	JA	@SCNDRV@_SCRDXZ  ; **BRIF passed LSTPOS(was at prev. line term'r)
	JNZ	@SCNDRV@_SCRD03  ; BRIF not at LSTPOS
	CMP	DH,byte [@LSTCOL]
	JA	@SCNDRV@_SCRDXZ  ; BRIF beyond LSTPOS, all done
;** *** READ A CHARACTER INTO THE BUFFER
;** *** DO CASE TERMINATOR OF LINEFEED, NULL_WRAP, WRAP, BEFORE EOL, AT EOL
@SCNDRV@_SCRD03:	CALL	@SCNRDT
	PUSH	AX
	JB	@SCNDRV@_SCRD04  ; BRIF not reading a linefeed
	JNZ	@SCNDRV@_SCRD04  ; BRIF not reading a linefeed
	CMP	AH,DH
	JNZ	@SCNDRV@_SCRD04  ; BRIF not reading a linefeed
;** *** *** CASE: LINEFEED
@SCNDRV@_SCRDLF:	MOV	AX,@SCNDRV@_CHRLNF+0
	JMP	@SCNDRV@_SCRD08  ; At linefeed terminator, pass linefeed
@SCNDRV@_SCRD04:	CMP	AH,DH
	JA	@SCNDRV@_SCRD07  ; BRIF within data on screen
	JB	@SCNDRV@_SCRD06  ; BRIF beyond terminator
;** *** *** CASE: NULL_WRAP
	CMP	AL,((@TRMNWP) and 0FFh)
	JNZ	@SCNDRV@_SCRD07  ; BRIF not at NULL_WRAP terminator
@SCNDRV@_SCRD06:	CMP	AL,((@TRMEOL) and 0FFh)
	POP	AX
	JZ	@SCNDRV@_SCRDXZ  ; BRIF beyond EOL
;** *** *** CASE: WRAP
	INC	DL  ; Wrap to next line
	MOV	DH,byte [@WDOLFT]
	JMP	@SCNDRV@_SCRD02
;** *** *** CASE: BEFORE EOL
@SCNDRV@_SCRD07:
	CLC  ; Indicate call is from Screen Editor
	CALL	@SCRINP  ; AX=Character at (DH,DL)
@SCNDRV@_SCRD08:	MOV	byte [BX+0],AL
	DEC	CX
	POP	AX
	JZ	@SCNDRV@_SCRDEX
	CMP	AL,((@TRMEOL) and 0FFh)
	JNZ	@SCNDRV@_SCRD09  ; BRIF not at EOL
	CMP	AH,DH
	JBE	@SCNDRV@_SCRDEX  ; BRIF at EOL(or beyond), all done
@SCNDRV@_SCRD09:	INC	BX
	CALL	@SCNDRV@_CSRADV
	JB	@SCNDRV@_SCRDXZ  ; If end of window, all done
	JMP	@SCNDRV@_SCRD02  ; Pass next character
;** *** *** CASE: AT(OR BEYOND) EOL
@SCNDRV@_SCRDEX:	INC	BX  ; Set BX= last posn written plus one
@SCNDRV@_SCRDXZ:	POPF
	CALL	@SCNBRK  ; Clear any flags associated with INPUT
	RET
;** *** *** END
;** *** END
;** END SUBROUTINE SCNRDL
; SUBTTL  CONTROL CHARACTER ROUTINES

;CONTROL CHARACTER DISPATCH TABLE
;**
@SCNDRV@_FUNTAB:	DW	@SCNDRV@_CTLIGN  ; ^@  -  Ignore
	DW	@SCNDRV@_CTLIGN  ; ^A  -  Ignore
	DW	@SCNDRV@_BCKWRD  ; ^B  -  Back one word
	DW	@SCNDRV@_CTLIGN  ; ^C  -  Ignore
	DW	@SCNDRV@_CTLIGN  ; ^D  -  Ignore
	DW	@SCNDRV@_LTRUNC  ; ^E  -  Truncate logical line
	DW	@SCNDRV@_FWDWRD  ; ^F  -  Forward one word
	DW	@SCNDRV@_CBEEP  ; ^G  -  Beep
	DW	@SCNDRV@_BAKSPC  ; ^H  -  Destructive backspace
	DW	@SCNDRV@_LTAB  ; ^I  -  Destructive tab
	DW	@SCNDRV@_LFEED  ; ^J  -  Linefeed
	DW	@SCNDRV@_WHOME  ; ^K  -  Home within window
	DW	@SCNDRV@_CCLRSN  ; ^L  -  Clear window, home cursor
	DW	@SCNDRV@_LCARET  ; ^M  -  Carriage return
	DW	@SCNDRV@_LAPPND  ; ^N  -  Append to end of line
	DW	@SCNDRV@_CTLIGN  ; ^O  -  Ignore
	DW	@SCNDRV@_CTLIGN  ; ^P  -  Ignore
	DW	@SCNDRV@_CTLIGN  ; ^Q  -  Ignore
	DW	@SCNDRV@_LINSRT  ; ^R  -  Insert a blank
	DW	@SCNDRV@_CTLIGN  ; ^S  -  Ignore
	DW	@SCNDRV@_LABELK  ; ^T  -  LABEL Key
	DW	@SCNDRV@_LDELET  ; ^U  -  Delete a line
	DW	@SCNDRV@_CTLIGN  ; ^V  -  Ignore
	DW	@SCNDRV@_WDELET  ; ^W  -  Delete a word
	DW	@SCNDRV@_CTLIGN  ; ^X  -  Ignore
	DW	@SCNDRV@_CTLIGN  ; ^Y  -  Ignore
	DW	@SCNDRV@_WERASE  ; ^Z  -  Erase to end of window
	DW	@SCNDRV@_CTLIGN  ; ^[ or ESC - Ignore
	DW	@SCNDRV@_WCSADV  ; ^\  -  Cursor advance within window
	DW	@SCNDRV@_WCSREG  ; ^]  -  Cursor regress within window
	DW	@SCNDRV@_WCSUP  ; ^^  -  Cursor up within window
	DW	@SCNDRV@_WCSDWN  ; ^_  -  Cursor down within window
	DW	@SCNDRV@_CDELET  ; DEL -  Delete a character

;SUBROUTINE CTLDSP(CONTROL_CHAR); Do control char logic
;**                         on entry:   AX=control character
;**                         on exit:    if CF=0 then AX=character to output
;**                                     if CF=1 then AX is undefined
@SCNDRV@_CTLDSP:
	CALL	@SCNPOS  ; DH=column, DL=row
end if
; EXTRN	CSRTYP:WORD
if @GW_PASS = 1
; EXTRN	SETCSR:NEAR
	MOV	byte [@CSRTYP],((0) and 0FFh)  ; Set for off cursor
	CALL	@SETCSR  ; Ensure that the cursor is off
	MOV	DH,byte [@CSRX]  ; Set DH=true posn(not width truncated)
	TEST	byte [@ESCFLG],((255) and 0FFh)
	JNZ	@SCNDRV@_DOESC  ; BRIF in middle of escape sequence
	CMP	AL,((27) and 0FFh)
	JZ	@SCNDRV@_DOESC
@SCNDRV@_CTLDS0:

@SCNDRV@_CTLDP0:
@SCNDRV@_CTLDP1:
; EXTRN	EDTMAP:NEAR,PRTMAP:NEAR
	TEST	byte [@F_EDIT],((255) and 0FFh)  ; Test for Screen Edit mode
	JZ	@SCNDRV@_CTLPRT  ; BRIF not edit mode
	CMP	AH,((1) and 0FFh)  ; Set PSW.C if two byte character
	CMC
	CALL	@EDTMAP  ; Map edit function/output character code
	JMP	@SCNDRV@_CTLEDT

@SCNDRV@_CTLPRT:	CMP	AH,((1) and 0FFh)  ; Set PSW.C if two byte character
	CMC
	CALL	@PRTMAP  ; Map print function/output character codes
@SCNDRV@_CTLEDT:	JZ	@SCNDRV@_CTLDPY  ; Ignore this character
; Print or perform the editor function
	CMP	AH,((255) and 0FFh)  ; Is it an editor function (&HFF)?
	JNZ	@SCNDRV@_CTLDSX  ; No - print the character
	XOR	AH,AH  ; Clear (no longer needed) editor function flag
	CMP	AL,((127) and 0FFh)  ; Delete function?
	JNZ	@SCNDRV@_CTLNDL  ; BRIF not DEL
	MOV	AL,((" ") and 0FFh)  ; DEL code
@SCNDRV@_CTLNDL:	CMP	AL,((255) and 0FFh)
	JNZ	@SCNDRV@_CTLNMK  ; BRIF not "mark line for deletion"
	PUSH	AX
	PUSH	BX
	CALL	@SCNRDT
	MOV	BX,word [@TRMCUR]
	OR	byte [@LINTTB-1+BX],((@TRMNUL) and 0FFh)  ; Set "not for input" flag on this line
	POP	BX
	POP	AX
;       STC
	RET
@SCNDRV@_CTLNMK:	CMP	AL,((" "+1) and 0FFh)  ; Test for legal function code
	JNB	@SCNDRV@_CTLDPY  ; Ignore this code
	PUSH	AX
	CALL	@SCNDRV@_CTLIRS  ; Possibly reset insert flag
	ADD	AX,AX  ; Two bytes per entry
	MOV	BX,AX
	MOV	AX,@SCNDRV@_CTLDPX
	PUSH	AX  ; Put return on stack
	MOV	AX,word [cs:@SCNDRV@_FUNTAB+BX]
	PUSH	AX  ; Put routine address on stack
@SCNDRV@_CTLDSX:	CLC
	RET  ; Go do control routine
;** *** UPDATE CURRENT_POSN, RETURN
@SCNDRV@_CTLDPX:	MOV	byte [@CSRY],DL
	MOV	byte [@CSRX],DH  ; Update cursor posn
	POP	AX
	SUB	AL,((@SCNDRV@_CHRRET) and 0FFh)
	MOV	byte [@F_CRET],AL  ; F.CRET = 0 if character was Carriage return
@SCNDRV@_CTLDPY:
	STC
@SCNDRV@_CTLIGN:
@SCNDRV@_CTLDPZ:	RET
;** ESCAPE SEQUENCE PROCESSING
@SCNDRV@_DOESC:	CALL	@SCROUT  ; Returns carry set if continuation of escape sequence
	SBB	AL,AL  ; If ESC sequence, AL=FF else AL=0
	MOV	byte [@ESCFLG],AL  ; Set/Reset flag
	JMP	@SCNDRV@_CTLDPY
;** END SUBROUTINE CTLDSP

;THE CONTROL CHARACTERS WHICH RESET INSERT FLAG ARE IN TABLE BELOW:

@SCNDRV@_CTLITB:
	DB	@SCNDRV@_CHRLDL  ; LINE_DELETE
	DB	@SCNDRV@_CHRERA  ; ERASE_SCREEN
	DB	@SCNDRV@_CHRFDW  ; FORWARD_WORD
	DB	@SCNDRV@_CHRBKW  ; BACKWARD_WORD
	DB	@SCNDRV@_CHRAPP  ; APPEND_TO_LINE
	DB	@SCNDRV@_CHREDT  ; EDIT_PREVIOUS_LINE
	DB	@SCNDRV@_CHRCLE  ; CLEAR_TO_END
	DB	@SCNDRV@_CHRBEL  ; BELL
	DB	@SCNDRV@_CHRHOM  ; HOME
	DB	@SCNDRV@_CHRADV  ; CURSOR_ADV
	DB	@SCNDRV@_CHRREG  ; CURSOR_REG
	DB	@SCNDRV@_CHRUP  ; CURSOR_UP
	DB	@SCNDRV@_CHRDWN  ; CURSOR_DOWN
	@SCNDRV@_CTLCNT=$-@SCNDRV@_CTLITB

;SUBROUTINE CTLIRS              ; Reset insert flag for specified characters
;**                 on entry:   AL=character
;**                 on exit:    DI garbaged
;**
@SCNDRV@_CTLIRS:	PUSH	AX
	PUSH	BX
	PUSH	CX
	PUSH	DI
;** IF (SPECIAL_ACTION(CTLKEY))
	MOV	DI,@SCNDRV@_CTLITB  ; DI= [control char table]
	MOV	CX,@SCNDRV@_CTLCNT  ; CX= count of entries in table
	MOV	BX,CX
	PUSH	ES
	PUSH	CS  ; Scan in code segment
	POP	ES
	CLD  ; Scan forward
 REPNE	SCASB  ; Scan for character in table
	POP	ES
	JNE	@SCNDRV@_INCNOT  ; BRIF did not find the control character
;** *** F.INSRT=FALSE
	MOV	byte [@F_INST],((0) and 0FFh)  ; Reset insert flag
@SCNDRV@_INCNOT:	POP	DI
	POP	CX
	POP	BX
	POP	AX
	RET
;** END SUBROUTINE CTLIRS
;** *** END

; SUBTTL  CONTROL CHARACTER ROUTINES - Cursor movement by character, line and TAB

;The control character routines are entered with DH=current column and
;   DL=current line. They return updated posn in the same registers. They
;   can modify AX, BX, CX but must save any other registers used.

;CURSOR CONTROL
;   The cursor control routines are somewhat special. Except for cursor advance,
;   the cursor is made to stay within previously printed data. The cursor
;   advance routine will append blanks by changing the logical right margin,
;   without actually printing anything. All of the cursor control routines
;   will update FSTPOS and LSTPOS as long as the cursor stays within a logical
;   line. When the cursor leaves a logical line, the FSTPOS and LSTPOS values
;   do not change. If the cursor is then moved back onto the original logical
;   line, the values are updated once more.

;Cursor advance
@SCNDRV@_WCSADV:	CALL	@SCNDRV@_CSRADV  ; Advance cursor
	JB	@SCNDRV@_WCSABT  ; BRIF can't do, quit
;       CALL    SCNRDT          ; AH=end of this physical, AL=terminator
;       CMPB    DH,AH
;If cursor beyond previously printed data, don't update LSTCOL
;       JAE     WCSABT          ; BRIF not to left of line terminator posn
;If cursor beyond previous LSTPOS and on same logical, update LSTPOS
@SCNDRV@_UPDPOS:	PUSH	DX
	DEC	DH  ; LSTCOL is to left of cursor
	CMP	DL,byte [@LSTLIN]
	JB	@SCNDRV@_UPDPS3  ; BRIF not new LSTPOS
	JZ	@SCNDRV@_UPDPS2  ; BRIF on same line, possibly update LSTPOS
	PUSH	DX
	CALL	@SCNDRV@_LSTART  ; Get start line of current logical
	CMP	DL,byte [@LSTLIN]
	POP	DX
	JA	@SCNDRV@_UPDPS3  ; BRIF LSTPOS not on current logical line
;LSTPOS on current logical, previous physical
	MOV	byte [@LSTLIN],DL  ; Set LSTPOS to current
	MOV	byte [@LSTCOL],DH
@SCNDRV@_UPDPS2:	CMP	DH,byte [@LSTCOL]
	JBE	@SCNDRV@_UPDPS3  ; BRIF not new last posn
	MOV	byte [@LSTCOL],DH  ; Set new last posn
;If cursor before previous FSTPOS and on same logical, update FSTPOS
@SCNDRV@_UPDPS3:	INC	DH  ; Restore column
	CMP	DL,byte [@FSTLIN]
	JNZ	@SCNDRV@_UPDPSX  ; BRIF not on same line as first position
	CMP	DH,byte [@FSTCOL]
	JAE	@SCNDRV@_UPDPSX  ; BRIF not new first position
	MOV	byte [@FSTCOL],DH  ; Set new first position to current position
@SCNDRV@_UPDPSX:	POP	DX
@SCNDRV@_WCSABT:	RET

;Cursor regress
@SCNDRV@_WCSREG:	CALL	@SCNDRV@_CSRREG  ; Move cursor
	JB	@SCNDRV@_WCSABT  ; Can't move, quit
@SCNDRV@_WCSRET:	CALL	@SCNRDT
	CMP	AH,DH
	JNB	@SCNDRV@_UPDPOS  ; Within logical, update FSTPOS, LSTPOS, return
;Cursor to right of line terminator, don't update LSTCOL
	JMP	@SCNDRV@_WCSABT  ; Return

;Cursor up
@SCNDRV@_WCSUP:	CALL	@SCNDRV@_CSRUP  ; Move cursor
	JNB	@SCNDRV@_WCSRET  ; BRIF successful, possibly update FSTPOS, LSTPOS
	RET  ; Unsuccessful, return(NOP)

;Cursor down
@SCNDRV@_WCSDWN:	CALL	@SCNDRV@_CSRDWN  ; Move cursor
	JNB	@SCNDRV@_WCSRET  ; BRIF successful, possibly update FSTPOS, LSTPOS
	RET  ; Unsuccessful, return(NOP)

;TAB                            ; Move cursor to next TAB stop

@SCNDRV@_LTAB:	TEST	byte [@F_INST],((255) and 0FFh)
	JZ	@SCNDRV@_LTABL  ; BRIF not insert TAB
;Insert spaces until CSRX is at TAB stop or LINLEN
@SCNDRV@_LTABIL:	MOV	AX," "
	CALL	@SCNOUT  ; Insert a blank
	MOV	DL,byte [@CSRY]
	MOV	DH,byte [@CSRX]
	CMP	DH,byte [@LINLEN]
	JA	@SCNDRV@_LTABZ  ; All done, at end of line
	DEC	DH
	TEST	DH,((7) and 0FFh)
	JNZ	@SCNDRV@_LTABIL  ; Keep inserting
	INC	DH
	JMP	@SCNDRV@_LTABZ  ; All done, at TAB stop
;Non-insert TAB, just pass over characters
@SCNDRV@_LTABL:	CMP	DH,byte [@LINLEN]
	JAE	@SCNDRV@_LTABX0  ; BRIF need to wrap
	INC	DH
	TEST	DH,((7) and 0FFh)
	JNZ	@SCNDRV@_LTABL
	INC	DH
	JMP	@SCNDRV@_LTABX  ; BRIF reached good posn
@SCNDRV@_LTABX0:	CMP	DL,byte [@WDOBOT]
	JAE	@SCNDRV@_LTABZ  ; BRIF no room to end of page
	INC	DL
	MOV	DH,byte [@WDOLFT]  ; Else move to start of next line
@SCNDRV@_LTABX:	CALL	@SCNDRV@_UPDPOS  ; Update LSTPOS
@SCNDRV@_LTABZ:	RET
; SUBTTL  CONTROL CHARACTER ROUTINES - Cursor movement by word

;Advance cursor to beginning of next word within screen
@SCNDRV@_FWDWRD:	PUSH	DX
	PUSH	word [@LSTLIN]
	CMP	DL,byte [@LSTLIN]
	JNZ	@SCNDRV@_FWDWR0  ; BRIF LSTPOS not on this line
	CMP	DH,byte [@LSTCOL]
	JB	@SCNDRV@_FWDWR0  ; BRIF within logical line
	MOV	byte [@LSTLIN],((255) and 0FFh)  ; Ignore LSTPOS in scan
@SCNDRV@_FWDWR0:	CLC
@SCNDRV@_FWDWR1:	CALL	@SCNDRV@_FWDWDL  ; Try within logical
	JB	@SCNDRV@_FWDWR2  ; BRIF unsuccessful
	POP	word [@LSTLIN]
	CALL	@SCNDRV@_UPDPOS
	POP	AX  ; Remove old posn from stack
	RET
;Reached end of logical line, try next logical
@SCNDRV@_FWDWR2:	CALL	@SCNDRV@_CSRDWN
	JB	@SCNDRV@_FWDWRZ  ; BRIF end of screen
	MOV	DH,byte [@WDOLFT]  ; Start scan again at next line
	STC
	JMP	@SCNDRV@_FWDWR1  ; Continue scan
;Unsuccessful, return cursor to original posn
@SCNDRV@_FWDWRZ:	POP	word [@LSTLIN]
	POP	DX
	RET

@SCNDRV@_FWDWD0:	CALL	@SCNDRV@_LCSADV
	JB	@SCNDRV@_FWDWD3  ; At end of logical line
;Advance cursor to beginning of next word within logical line
@SCNDRV@_FWDWDL:	JB	@SCNDRV@_FWDWD2  ; Start as though between words
	CALL	@SCNDRV@_ANCHK  ; Check if current char is within word
	JNB	@SCNDRV@_FWDWD0  ; BRIF still within previous word
;At space between words
@SCNDRV@_FWDWD1:	CALL	@SCNDRV@_LCSADV
	JB	@SCNDRV@_FWDWD3  ; At end of logical line, check next logical
@SCNDRV@_FWDWD2:	CALL	@SCNDRV@_ANCHK
	JB	@SCNDRV@_FWDWD1
@SCNDRV@_FWDWDX:	RET  ; Return, DX=posn of new word or end of logical line
@SCNDRV@_FWDWD3:	JNZ	@SCNDRV@_FWDWDX  ; BRIF not stop at LSTPOS
;Stopped at LSTPOS, continue scan to end of physical line
	CMP	AH,DH
	JA	@SCNDRV@_FWDWD4  ; BRIF more this line
	STC
	RET
@SCNDRV@_FWDWD4:	MOV	byte [@LSTLIN],((255) and 0FFh)  ; Ignore LSTPOS from here on
	JMP	@SCNDRV@_FWDWD1  ; Since crossed LSTPOS, passed end of current word

;Regress cursor to start of previous word
@SCNDRV@_BCKWRD:	PUSH	word [@FSTCOL]
	PUSH	DX
	CMP	DH,byte [@FSTLIN]
	JNZ	@SCNDRV@_BCKWD2
	CMP	DH,byte [@FSTCOL]
	JA	@SCNDRV@_BCKWD2
	MOV	byte [@FSTLIN],((0) and 0FFh)
;Assume passed beginning of current word, continue to start of next
@SCNDRV@_BCKWD2:	CALL	@SCNDRV@_LCSREG
	JB	@SCNDRV@_BCKWD7  ; BRIF At start of line
@SCNDRV@_BCKWD4:	CALL	@SCNDRV@_ANCHK
	JB	@SCNDRV@_BCKWD2  ; BRIF still between words
;Scanning previous word, any termination is good
@SCNDRV@_BCKWD5:	CALL	@SCNDRV@_LCSREG
	JB	@SCNDRV@_BCKWD6  ; BRIF at beginning of line, found previous word
	CALL	@SCNDRV@_ANCHK
	JNB	@SCNDRV@_BCKWD5  ; BRIF not at beginning of word
	CALL	@SCNDRV@_CSRADV  ; Advance back to start of word
@SCNDRV@_BCKWD6:	POP	AX
	PUSH	DX  ; Push new posn on stack
@SCNDRV@_BCKWDX:	POP	DX
	POP	word [@FSTCOL]
	CALL	@SCNDRV@_UPDPOS
	RET  ; Return, DL=posn of previous word
@SCNDRV@_BCKWD7:	JNZ	@SCNDRV@_BCKWD8  ; BRIF not stop at FSTPOS
	MOV	byte [@FSTLIN],((0) and 0FFh)  ; Ignore FSTPOS from here on
	JMP	@SCNDRV@_BCKWD2  ; Since passed begginning of logical, between words
@SCNDRV@_BCKWD8:	CALL	@SCNDRV@_CSRUP  ; Try previous logical line
	JB	@SCNDRV@_BCKWDX  ; At beginning of screen
	CALL	@SCNRDT  ; Read previous line teminator
	OR	AH,AH
	JZ	@SCNDRV@_BCKWD8  ; Previous line is null, try next previous
	MOV	DH,AH
	JMP	@SCNDRV@_BCKWD4  ; Continue scan
; SUBTTL  CONTROL CHARACTER ROUTINES - Screen home, truncate and clear

; EXTRN	BEEP:NEAR
@SCNDRV@_CBEEP:	CALL	@BEEP  ; Sound Bell
	JMP	@SCNPOS  ; return current cursor location

; EXTRN	CLRSCN:NEAR
;Clear the screen
@SCNDRV@_CCLRSN:
	CLC  ; no-carry = internal parameter
	MOV	AL,((2) and 0FFh)  ; specify text only
	CALL	@CLRSCN  ; OEM supplied Clear-Screen Routine
;fall into WHOME

;Home the cursor
@SCNDRV@_WHOME:	MOV	DL,byte [@WDOTOP]
	MOV	DH,byte [@WDOLFT]
	RET

;Erase to the end of the screen
@SCNDRV@_WERASE:	CALL	@SCNDRV@_PLINIT  ; Clear current physical to end of line
	PUSH	DX
	MOV	DH,byte [@WDOLFT]  ; Clear rest of lines from left margin
;WHILE POSN .LTE. WDOBOT
;** IF DATA_EXISTS(POSN) THEN INITIALIZE LINE
@SCNDRV@_WERAS0:	INC	DL
	CMP	DL,byte [@WDOBOT]
	JA	@SCNDRV@_WERASX  ; Beyond window, exit
	CALL	@SCNDRV@_PLINIT  ; Clear this line
	JMP	@SCNDRV@_WERAS0  ; Init next line
@SCNDRV@_WERASX:	POP	DX  ; Return DX=cursor posn
	RET
; SUBTTL  CONTROL CHARACTER ROUTINES - Line truncate and delete

;Delete entire logical line
@SCNDRV@_LDELET:	CALL	@SCNDRV@_LSTART  ; Get start of logical line in DX

;Truncate line from posn in DX
@SCNDRV@_LTRUNC:	PUSH	DX
	CALL	@SCNDRV@_SCNRTL  ; AH=last valid data on physical line
	PUSHF
	STC  ; Indicate don't clear line by scrolling
	CALL	@SCNDRV@_LCLEAR  ; Clear this physical line
	JB	@SCNDRV@_LTRUN9  ; Reached LSTPOS, all done
	INC	DL
;"Suck up" remaining physical lines attached to current logical
@SCNDRV@_LTRUN1:	POPF
	JB	@SCNDRV@_LTRUNX  ; Reached end of logical line
	CALL	@SCNDRV@_SCNRTL
	PUSHF
	MOV	DH,byte [@WDOLFT]
	CLC
	CALL	@SCNDRV@_LCLEAR  ; Clear this line from start of line
	JB	@SCNDRV@_LTRUN9  ; Reached LSTPOS, all done
	JMP	@SCNDRV@_LTRUN1
@SCNDRV@_LTRUN9:	POPF
@SCNDRV@_LTRUNX:	POP	DX
	RET

;Clear current physical to end of physical or LSTPOS, whichever is smallest
; (DH,DL)=start posn, AH=TERM_POSN, if CF=1, don't scroll
@SCNDRV@_LCLEAR:	PUSHF
	CMP	DL,byte [@LSTLIN]
	JZ	@SCNDRV@_LCLER2  ; BRIF clear up to LSTPOS
@SCNDRV@_LCLER0:	CMP	DH,byte [@WDORGT]
	JA	@SCNDRV@_LCLER5  ; BRIF beyond end of physical(just exit)
	POPF
	JNB	@SCNDRV@_LCLER1  ; BRIF clear line by scroll
	CALL	@SCNDRV@_PLINIT  ; Clear this physical line
	CLC
	RET
@SCNDRV@_LCLER1:	CALL	@SCNDRV@_SCRLU0  ; Scroll up from bottom to current line
	CLC
	RET
@SCNDRV@_LCLER2:	POPF
	CALL	@SCNDRV@_PLINIT
	STC
	RET
@SCNDRV@_LCLER5:	POPF
	CLC
	RET

; SUBTTL  CONTROL CHARACTER ROUTINES - Character and word delete

;Word delete

@SCNDRV@_WDELET:
	CMP	DH,byte [@LINLEN]
	JBE	@SCNDRV@_WDELT0  ; BRIF on physical line
	CALL	@SCNDRV@_CSRADV  ; Put cursor on next line
	JB	@SCNDRV@_WDELTZ  ; BRIF at end of screen
@SCNDRV@_WDELT0:
	CMP	DL,byte [@LSTLIN]  ; **
	JNZ	@SCNDRV@_WDELT2  ; **BRIF not on LSTPOS line
	CMP	DH,byte [@LSTCOL]  ; **
	JAE	@SCNDRV@_WDELTZ  ; **BRIF at or beyond LSTPOS(don't do word delete)
@SCNDRV@_WDELT2:  ; **
	PUSH	DX
	CMP	DH,byte [@LINLEN]
	JBE	@SCNDRV@_WDELT4  ; Good delete posn(within physical line)
	CALL	@SCNDRV@_LCSADV  ; Advance cursor to next physical of logical
@SCNDRV@_WDELT4:	PUSH	DX
	CLC
	PUSH	word [@LSTLIN]
	CALL	@SCNDRV@_FWDWDL  ; Set (DH,DL)= start of next word or end of line
	POP	word [@LSTLIN]
	JNB	@SCNDRV@_WDELT6  ; BRIF found another word following
;No word following, just delete to end of line
	INC	DH  ; Include terminator in delete
@SCNDRV@_WDELT6:	MOV	CX,DX
	POP	DX
	CMP	CL,byte [@LSTLIN]  ; **
	JB	@SCNDRV@_WDELT8  ; **BRIF not beyond LSTPOS line
	JA	@SCNDRV@_WDELT7  ; **BRIF beyond LSTPOS line, use LSTPOS
	CMP	CH,byte [@LSTCOL]  ; **At LSTPOS line, check if column is OK
	JB	@SCNDRV@_WDELT8  ; **BRIF before LSTPOS, column is OK
@SCNDRV@_WDELT7:	MOV	CX,word [@LSTLIN]  ; **Use LSTPOS as end of delete
	INC	CH  ; **INC because delete is up to char before this posn
@SCNDRV@_WDELT8:  ; **
	CMP	DL,CL
	JNZ	@SCNDRV@_WDELTC  ; BRIF multiple line delete
@SCNDRV@_WDELT9:	SUB	CH,DH  ; CH=chars to next word minus one
	JBE	@SCNDRV@_WDELTX  ; BRIF no chars to delete
	CALL	@SCNDRV@_CDELLG  ; Delete CH chars in this line
@SCNDRV@_WDELTX:	POP	DX
@SCNDRV@_WDELTZ:	RET
@SCNDRV@_WDELTC:	INC	DL
@SCNDRV@_WDELTD:	PUSH	DX
	PUSH	CX
; Delete across physical lines, delete to end of this line
	CMP	DL,CL
	MOV	DH,byte [@WDOLFT]
	JZ	@SCNDRV@_WDELTE
	CALL	@SCNDRV@_SCNRTL
	MOV	CH,AH
	CALL	@SCNDRV@_CDELPH  ; Erase intervening line
	POP	CX
	POP	DX
	DEC	CL  ; Each erase of intervening line brings CL closer
	JMP	@SCNDRV@_WDELTD
@SCNDRV@_WDELTE:	CMP	CH,byte [@WDOLFT]
	JBE	@SCNDRV@_WDELTF  ; BRIF at begin of line
	DEC	CH
	CALL	@SCNDRV@_CDELLG  ; Delete up to the next word on this line
@SCNDRV@_WDELTF:	POP	CX
	POP	DX
	DEC	DL  ; Go back to original line
	MOV	CH,byte [@LINLEN]
	INC	CH
	JMP	@SCNDRV@_WDELT9  ; Delete to end of line

;Destructive back space

@SCNDRV@_BAKSPC:
	CALL	@SCNDRV@_LCSREG  ; Back space within logical line
	CALL	@SCNDRV@_SCNRTL
	CMP	DH,AH
	JBE	@SCNDRV@_CDELET  ; BRIF current posn less than TERM_POSN
	CMP	AH,byte [@WDOLFT]
	JAE	@SCNDRV@_BAKSP1  ; BRIF not on null line
	MOV	AH,byte [@WDOLFT]
@SCNDRV@_BAKSP1:	MOV	DH,AH  ; If beyond terminator, set posn to terminator

;Delete character

@SCNDRV@_CDELET:	MOV	CH,((1) and 0FFh)  ; Assume one byte char delete
	CMP	DH,byte [@LINLEN]
	JBE	@SCNDRV@_CDELT1  ; BRIF within physical line
	RET
@SCNDRV@_CDELT1:

;SUBROUTINE CDELLG:             ; Delete CH characters @(DH,DL) within logical
;                       On entry:   CH=count, CL= flag, (DH,DL)=posn
;                                   If CL is non-zero, remove null line from screen

@SCNDRV@_CDELLG:	PUSH	DX
	CALL	@SCNDRV@_SCNRTL  ; Get last valid char posn in AH
	PUSHF
	CALL	@SCNDRV@_CDELPH  ; Delete characters from current physical
;   returns new term posn in AH
	XOR	CL,CL  ; CL is iteration counter
	POPF
	MOV	AL,((@TRMEOL) and 0FFh)
	JB	@SCNDRV@_CDLGEX  ; BRIF was EOL term'd, update terminator, exit
	JNZ	@SCNDRV@_CDLGWP  ; BRIF line was WRAP or NULL_WRAP term'd, get
;       chars from next line
;Line was LF terminated, check for LF delete
	CMP	AH,DH
	MOV	AL,((@TRMLNF) and 0FFh)
	JA	@SCNDRV@_CDLGEX  ; BRIF didn't delete LF, update terminator, exit
	OR	AH,AH
	JZ	@SCNDRV@_CDLGRT  ; **BRIF entire line deleted and removed
	MOV	AH,DH
	JMP	@SCNDRV@_CDLWP1
;Need to get chars from next physical line at (AH,DL) posn to end of physical
@SCNDRV@_CDLGWP:	OR	AH,AH
	JZ	@SCNDRV@_CDLGRT  ; BRIF entire line deleted and removed
	INC	AH
@SCNDRV@_CDLWP1:	CMP	DL,byte [@LSTLIN]  ; **
	JZ	@SCNDRV@_CDLGRT  ; **LSTPOS on this line, all done
	PUSH	word [@LSTLIN]  ; **Save current LSTPOS
	CALL	@SCNDRV@_CDUNWP  ; Unwrap the characters desired returns terminator
;     in (AH,AL) and byte count in CH
	CALL	@SCNDRV@_SCNWTT  ; Update terminator
	OR	CH,CH
	JNZ	@SCNDRV@_CDLWP2  ; BRIF we have characters to unwrap
	POP	AX  ; Restore the stack
	JMP	@SCNDRV@_CDLGRT  ; Return, all done
;Need to delete CH characters unwrapped from next line
@SCNDRV@_CDLWP2:	MOV	DH,byte [@WDOLFT]  ; Unwrapped from start of line
	INC	DL  ; Next line
	DEC	CL  ; Update iteration counter
	CALL	@SCNDRV@_SCNRTL  ; Read next lines terminator
;Need to restore LSTPOS to old value for character delete
	MOV	DI,word [@LSTLIN]  ; **Save current value of LSTPOS in SI
	POP	word [@LSTLIN]  ; **Restore value before CDUNWP so CDELPH works properly
	PUSHF
	PUSH	DI  ; **Save current "true" value of LSTPOS
	XCHG	DI,AX  ; **
	CMP	AL,byte [@LSTLIN]  ; **
	PUSHF  ; **
	XCHG	DI,AX  ; **
	CALL	@SCNDRV@_CDELPH  ; Delete chars to end of line or LSTPOS
	POPF  ; **
	POP	DI  ; **
	JZ	@SCNDRV@_CDLGNC  ; **BRIF CDUNWP did not change LSTPOS
	MOV	word [@LSTLIN],DI  ; **Restore CDUNWP value of LSTPOS
@SCNDRV@_CDLGNC:	OR	AH,AH
	JNZ	@SCNDRV@_CDLGW1  ; BRIF still chars on this line
	POPF
	JNB	@SCNDRV@_CDLGRT  ; BRIF LF or wrap term'd, already removed
@SCNDRV@_CDLGNL:	DEC	DL
	INC	CL
	CALL	@SCNDRV@_SCNRTL
	JB	@SCNDRV@_CDLGN0  ; BRIF previous line EOL term'd, remove null line
	JZ	@SCNDRV@_CDLGRT  ; BRIF previous line LF term'd, leave null line
	MOV	AL,((@TRMEOL) and 0FFh)
	CALL	@SCNDRV@_SCNWTT  ; Previous line was wrapped, terminate it and
;   remove null line
@SCNDRV@_CDLGN0:	INC	DL
	DEC	CL
	CALL	@SCNDRV@_SCRLU0  ; Remove null line by scrolling
	JMP	@SCNDRV@_CDLGRT  ; All done

@SCNDRV@_CDLGW1:	POPF
	JB	@SCNDRV@_CDLGEX  ; BRIF at EOL, all done
	JNZ	@SCNDRV@_CDLGWP  ; BRIF wrapped, unwrap chars from next line
;We have terminator in (AH,AL), posn in (DH,DL)
@SCNDRV@_CDLGEX:	CALL	@SCNDRV@_SCNWTT  ; Update terminator
@SCNDRV@_CDLGRT:	ADD	CL,DL
	POP	DX
	MOV	DL,CL
	RET

@SCNDRV@_CDUWXI:	MOV	CH,((0) and 0FFh)  ; Indicate no characters unwrapped
	JMP	@SCNDRV@_CDUWPX  ; Indirect jump

;SUBROUTINE CDUNWP:             ; "Unwrap" chars from next line
;                       On entry:   (AH,DL)= destination
;                       On exit:    (AH,AL)= new line terminator
;                                   CH=nunber of bytes unwrapped

@SCNDRV@_CDUNWP:	PUSH	BX
	PUSH	CX
	PUSH	DX
	PUSH	word [@TRMCUR]
	MOV	AL,((@TRMWRP) and 0FFh)
	MOV	CH,byte [@LINLEN]
	SUB	CH,AH
	JB	@SCNDRV@_CDUWXI  ; BRIF no space to unwrap characters to, just exit
	CMP	DL,byte [@LSTLIN]  ; **
	JNZ	@SCNDRV@_CDUWP0  ; **BRIF not unwrapping to LSTPOS
	TEST	byte [@LSTCOL],((255) and 0FFh)  ; **
	JNZ	@SCNDRV@_CDUWP0  ; **BRIF have some characters to unwrap
	MOV	AH,byte [@LINLEN]  ; **
	JMP	@SCNDRV@_CDUWXI  ; **If no characters to unwrap, just exit
@SCNDRV@_CDUWP0:	INC	CH
	MOV	BX,AX  ; Put DESTINATION in BX
	MOV	BL,DL
	INC	DL
	CALL	@SCNDRV@_SCNRTL  ; Read terminator for next line
	PUSH	AX
	PUSHF
	CMP	CH,AH
	JBE	@SCNDRV@_CDUWP1  ; BRIF enough characters to satisfy demand
	MOV	CH,AH  ; Else get all characters in next line
@SCNDRV@_CDUWP1:	MOV	CL,((1) and 0FFh)
	MOV	DH,byte [@WDOLFT]
	MOV	AX,DX  ; Put SOURCE in AX
	OR	CH,CH
	JNZ	@SCNDRV@_CDUWPN  ; BRIF not a null line following
	POPF
	PUSHF
	JZ	@SCNDRV@_CDUWP4  ; BRIF LF term'd, don't remove null line
	PUSH	word [@TRMCUR]
	CALL	@SCNDRV@_SCRLU0  ; Get rid of null line following
	POP	word [@TRMCUR]
	JMP	@SCNDRV@_CDUWP4  ; Set up terminator for return
@SCNDRV@_CDUWPN:
	CALL	@SCROLL  ; Scroll chars from old line to new
	CMP	DL,byte [@LSTLIN]
	JNZ	@SCNDRV@_CDUWP4  ; BRIF not on LSTPOS line
;If LSTPOS is between WDOLFT and SOURCE+COUNT, unwrap LSTPOS
	PUSH	AX
	ADD	AH,CH
	SUB	AH,byte [@LSTCOL]
	POP	AX
	JBE	@SCNDRV@_CDUWP3  ; BRIF LSTPOS .GT. SOURCE+COUNT
	SUB	byte [@LSTCOL],AH  ; LSTCOL=DESTINATION+(LSTPOS-SOURCE)
	JNB	@SCNDRV@_CDUWPL
	MOV	byte [@LSTCOL],((0) and 0FFh)  ; LSTCOL was zero, don't let it go negative
@SCNDRV@_CDUWPL:	ADD	byte [@LSTCOL],BH
	DEC	byte [@LSTLIN]  ; LSTLIN is line unwrapped to
; COMMENT	%
; ; Blank from DESTINATION+COUNT-((SOURCE+COUNT)-LSTPOS) to EOL
; 	PUSH    AX
; 	PUSH    DX
; 	PUSH    CX
; 	ADDB    DH,CH
; 	SUBB    DH,AH           ; (DH,DL)=start posn for blanking
; 	MOVB    CH,LINLEN       ; CH=end column
; 	MOVI    AX," "
; CDUWPB: CALL    SCROUT
; 	INCB    DH
; 	CMPB    DH,CH
; 	JBE     CDUWPB          ; Continue blanking to EOL
; 	POP     CX
; 	POP     DX
; 	POP     AX
; %
@SCNDRV@_CDUWP3:
;Return terminator for DL-1
@SCNDRV@_CDUWP4:	ADD	BH,CH  ; Get new terminator posn into BH
	DEC	BH
	POPF
	POP	AX  ; Restore original terminators for this line
	MOV	BL,((@TRMEOL) and 0FFh)  ; Assume line unwrapped is at EOL
	JB	@SCNDRV@_CDUWPE  ; BRIF at EOL
	MOV	BL,((@TRMLNF) and 0FFh)  ; Assume LF was unwrapped on unwrapped line
	JZ	@SCNDRV@_CDUWP6  ; BRIF at LF
;WRAP or NULL_WRAP, if BH .NE. LINLEN, then it must be LINLEN-1 and NULL_WRAP
@SCNDRV@_CDUWP5:	MOV	BL,((@TRMWRP) and 0FFh)  ; Assume line is WRAP
	CMP	BH,byte [@LINLEN]
	JZ	@SCNDRV@_CDUWP7  ; Previous line is full, must be WRAP
	MOV	BL,((@TRMNWP) and 0FFh)
	MOV	BH,byte [@LINLEN]
	JMP	@SCNDRV@_CDUWP7  ; Previous line not full even though we had
;   enough chars to fill it, must be NULL_WRAP
;EOL terminated
@SCNDRV@_CDUWPE:	OR	AH,AH
	JZ	@SCNDRV@_CDUWP7  ; If unwrapped null line, return EOL
;Was EOL or LF terminated, see if entire line was unwrapped
@SCNDRV@_CDUWP6:	CMP	AH,CH
	JNZ	@SCNDRV@_CDUWP5  ; BRIF wasn't unwrapped, previous line is WRAP
;terminator=(BH,BL)
@SCNDRV@_CDUWP7:	PUSH	BX
;       ORB     CH,CH
;       JZ      CDUWP8          ; BRIF no chars to delete from here on
;       MOVBI   CL,^O377        ; Set flag indicating can remove lines deleted
;       CALL    CDELLG          ; Delete CH characters at (DH,DL)
@SCNDRV@_CDUWP8:	POP	AX
@SCNDRV@_CDUWPX:	POP	word [@TRMCUR]
	POP	DX
	MOV	BH,CH
	POP	CX
	MOV	CH,BH
	POP	BX
	RET
;Needed one char and first char on next line is DBLCHR
@SCNDRV@_CDUWPF:	POP	AX
	POPF  ; Clean up stack
	MOV	AH,byte [@LINLEN]
	MOV	AL,((@TRMNWP) and 0FFh)  ; Set terminator to NULL_WRAP
	JMP	@SCNDRV@_CDUWP7

;SUBROUTINE CDELPH              ; Delete chars on physical line
;                       On entry:   (DH,DL)=posn to start delete from
;                                   (AH,AL)=line terminator for line DL
;                                   CH=count
;                       On exit:    AH=term posn
;                                   (DH,DL)=posn

@SCNDRV@_CDELPH:  ;PUSH    SI
	XOR	SI,SI  ; Set SI to zero(flag no char restore necessary)
	PUSH	BX
	PUSH	CX
	PUSH	DX
	PUSH	AX
	CMP	DH,AH
	JA	@SCNDRV@_CDEL9I  ; BRIF delete beyond or at physical end
	MOV	BX,DX  ; (BH,BL)=DESTINATION
	MOV	AX,DX
	ADD	AH,CH  ; (AH,AL)=SOURCE
	POP	CX  ; CH=end of physical line
	PUSH	CX
	CMP	AH,CH
	JBE	@SCNDRV@_CDELP0  ; BRIF not deleting more than we have
	MOV	AH,CH
	INC	AH  ; Delete entire line
@SCNDRV@_CDELP0:	CMP	DL,byte [@LSTLIN]
	JNZ	@SCNDRV@_CDELP1  ; BRIF not on line with LSTPOS
	CMP	CH,byte [@LSTCOL]
	JBE	@SCNDRV@_CDELP1  ; BRIF physical end less than LSTPOS
	MOV	CH,byte [@LSTCOL]  ; Use LSTPOS as end of this line
	CMP	DH,CH
	JA	@SCNDRV@_CDEL9I  ; BRIF delete beyond terminator
@SCNDRV@_CDELP1:
	PUSH	CX  ; Save last posn of SOURCE
	SUB	CH,AH
	PUSHF
	MOV	DH,BH
	ADD	DH,CH  ; (DH,DL)=end of DESTINATION
	POPF
	JB	@SCNDRV@_CDELP4  ; BRIF SOURCE greater than logical end of physical
	MOV	CL,((1) and 0FFh)
	INC	CH
	CALL	@SCROLL  ; Move characters to left
;Blank from end of SOURCE to end of DESTINATION+1
@SCNDRV@_CDELP4:	POP	CX  ; CH=end column of SOURCE
	INC	DH  ; DH=end column of DESTINATION plus one
	PUSH	DX
	MOV	AX," "
@SCNDRV@_CDELP5:	CMP	DH,CH
	JA	@SCNDRV@_CDELP6
	CALL	@SCROUT  ; Blank this posn
	INC	DH
	JMP	@SCNDRV@_CDELP5
@SCNDRV@_CDEL9I:	JMP	@SCNDRV@_CDELP9  ; Indirect to CDELP9
@SCNDRV@_CDELP6:	POP	DX  ; Restore end column of DESTINATION plus one
	POP	AX  ; Restore terminator passed to routine
;CH=last valid column, DH=first blanking column, AH=term column, AL=term type
	CMP	DL,byte [@LSTLIN]
	JNZ	@SCNDRV@_CDELP7  ; BRIF was not delete before LSTPOS
	CMP	CH,byte [@LSTCOL]
	JB	@SCNDRV@_CDELP7  ; BRIF delete up to terminator
;Delete included LSTPOS, subtract total deleted from LSTCOL
	POP	DX
	POP	CX
	SUB	byte [@LSTCOL],CH
	JAE	@SCNDRV@_CDEL8A  ; **BRIF LSTCOL valid
	MOV	byte [@LSTCOL],((0) and 0FFh)  ; **Set LSTCOL to 0
	JMP	@SCNDRV@_CDEL8A  ; Delete up to LSTPOS, adjust LSTPOS
;Deleted all data up to terminator, adjust terminator
@SCNDRV@_CDELP7:	MOV	AH,DH
	DEC	AH  ; Set terminator to last column of DESTINATION
@SCNDRV@_CDELP8:	POP	DX  ; (DH,DL)=original posn(start of DESTINATION)
	POP	CX  ; CL=flag
@SCNDRV@_CDEL8A:	CMP	DH,AH
	JBE	@SCNDRV@_CDELPX  ; BRIF still data remaining to right
	CMP	DH,((1) and 0FFh)
	JNZ	@SCNDRV@_CDELPX  ; BRIF still data remaining to left
	CMP	AL,((@TRMEOL) and 0FFh)
	JZ	@SCNDRV@_CDELPX  ; BRIF don't remove null line
;We have null line, remove it from the screen
	PUSH	word [@TRMCUR]
	CMP	DL,byte [@LSTLIN]  ; **If LSTPOS is wiped out, put it at
; ** end of previous line
	JNZ	@SCNDRV@_CDEL8B  ; **BRIF not wiped out
	DEC	byte [@LSTLIN]  ; **
	MOV	BH,byte [@WDOLFT]  ; **
	MOV	byte [@LSTCOL],BH  ; **
@SCNDRV@_CDEL8B:  ; **
	CALL	@SCNDRV@_SCRLU0  ; Scroll up from bottom of screen to DL
	POP	word [@TRMCUR]
	JMP	@SCNDRV@_CDELPX  ; All done
;We are deleting to right of line terminator
@SCNDRV@_CDELP9:	POP	AX  ; Restore terminator passed
	CMP	AL,((@TRMLNF) and 0FFh)
	MOV	DH,AH  ; DH=end of valid data plus one
	JZ	@SCNDRV@_CDELP7  ; BRIF LF term'd, delete it
	POP	DX  ; Delete beyond valid data, ignore it
	POP	CX
@SCNDRV@_CDELPX:	POP	BX
	CMP	DL,byte [@LSTLIN]
	JZ	@SCNDRV@_CDELPF  ; BRIF not on LSTPOS line, no update
	CMP	AH,byte [@LSTCOL]
	JAE	@SCNDRV@_CDELPF  ; BRIF LSTPOS is within line, no update
;POP     SI
@SCNDRV@_CDELPF:	RET
; SUBTTL  CONTROL CHARACTER ROUTINES - Line append, carriage return and linefeed

;Append to end of logical line

@SCNDRV@_LAPPND:
@SCNDRV@_LAPPN0:	CALL	@SCNRDT
	JB	@SCNDRV@_LAPPN1  ; BRIF we are at last line in logical
	INC	DL
	JMP	@SCNDRV@_LAPPN0  ; See if next line is last line in logical
@SCNDRV@_LAPPN1:	MOV	DH,AH  ; Set current posn to EOL
	CMP	AH,byte [@LINLEN]
	JNB	@SCNDRV@_LAPPN2  ; If end of window, advance cursor posn here
	JMP	@SCNDRV@_WCSADV  ; Use logical cursor advance(advances LSTPOS)
;This will set the cursor posn one beyond end(wrap next char typed)
@SCNDRV@_LAPPN2:	INC	DH
	RET

;Carriage return

@SCNDRV@_LCARET:
	CALL	@SCNRDT
	JB	@SCNDRV@_LCRET1  ; BRIF this line already EOL terminated
	JZ	@SCNDRV@_LCRET0  ; BRIF LF terminated
	CMP	AL,((@TRMNWP) and 0FFh)
	JNZ	@SCNDRV@_LCRET1  ; BRIF not NULL_WRAP terminated
@SCNDRV@_LCRET0:	DEC	AH  ; Do not include LF or NULL_WRAP in line
@SCNDRV@_LCRET1:	MOV	AL,((@TRMEOL) and 0FFh)
	CALL	@SCNDRV@_SCNWTT  ; Make this line EOL terminated
	MOV	DH,byte [@WDOLFT]  ; And move posn to left margin
	RET

;Line feed

@SCNDRV@_LFEED:	MOV	SI,0
	TEST	byte [@F_CRET],((255) and 0FFh)
	JZ	@SCNDRV@_LFD90I  ; BRIF LF following CR
	TEST	byte [@F_INST],((255) and 0FFh)
	JZ	@SCNDRV@_LFED30  ; BRIF not insert mode
	CALL	@SCNDRV@_SCNRTL
	CMP	AH,DH
	JB	@SCNDRV@_LFED30  ; Inserting beyond end of physical(just append)
;Insert mode, move characters from cursor to EOL onto the next line
	CMP	DL,byte [@LSTLIN]
	JZ	@SCNDRV@_CBEPI2  ; BRIF on LSTPOS line, can't do insert LF
; IMPROVEMENT: Find last physical in this logical and see if it can be moved
;   down one line. If not, abort before any inserts
@SCNDRV@_LFED10:
	CLC  ; Indicate call is from Screen Editor
	CALL	@SCRINP
	MOV	SI,AX  ; Save first char in SI
	MOV	AX," "
	CALL	@SCROUT
	PUSH	DX
@SCNDRV@_LFED12:	MOV	CH,((1) and 0FFh)
	CALL	@SCNDRV@_MKRMCH  ; Move everything over one
	INC	DH
	CMP	DH,byte [@LINLEN]
	JBE	@SCNDRV@_LFED12  ; Keep going until the end of the line
	MOV	AH,DL
	POP	DX  ; Restore posn
	MOV	DL,AH
	CALL	@SCNDRV@_PLINIT  ; Terminate line at current posn
	CMP	DL,byte [@WDOBOT]
	JNZ	@SCNDRV@_LFED43  ; Change terminator to LF and goto next line
	JMP	@SCNDRV@_LFEEDX
;No room!!
@SCNDRV@_CBEEPI:	POPF  ; Clean stack
@SCNDRV@_CBEPI2:	JMP	@SCNDRV@_CBEEP
@SCNDRV@_LFD90I:	JMP	@SCNDRV@_LFED90  ; Indirect jump to LFED90
;Insert beyond end of physical=append
; Append LF to end of physical line
@SCNDRV@_LFED30:	CALL	@SCNDRV@_SCNRTL
	PUSHF
	JB	@SCNDRV@_LFED31  ; BRIF need one more space to output LF
	JZ	@SCNDRV@_LFED32  ; BRIF already LF terminated, don't need space
@SCNDRV@_LFED31:	INC	AH  ; Need one more space at terminator posn
@SCNDRV@_LFED32:	CMP	AH,byte [@LINLEN]
	JBE	@SCNDRV@_LFED40  ; BRIF have room on this line
	CALL	@SCNDRV@_LFWRAP  ; Wrap linefeed to next line
	JB	@SCNDRV@_LFED69  ; BRIF no room
;The possibilities at this point are WRAP or EOL terminated
	POPF
	JNB	@SCNDRV@_LFED34  ; BRIF not EOL term'd(no change to terminator)
	CALL	@SCNRDT
	MOV	AH,byte [@LINLEN]  ; EOL terminated, change to WRAP at LINLEN
	MOV	AL,((@TRMWRP) and 0FFh)
	CALL	@SCNDRV@_SCNWTT
@SCNDRV@_LFED34:	MOV	DH,byte [@WDOLFT]
	CMP	DL,byte [@LSTLIN]
	JNZ	@SCNDRV@_LFED35  ; BRIF not extending LSTPOS
	INC	byte [@LSTLIN]  ; Move LSTPOS with LF
	MOV	byte [@LSTCOL],DH
@SCNDRV@_LFED35:	INC	DL  ; Move to new line(created by MKRMNL above)
	MOV	AH,DH
	JMP	@SCNDRV@_LFED43
@SCNDRV@_LFED40:	POPF
	JNB	@SCNDRV@_LFED42  ; BRIF not EOL, just change terminator to LF
@SCNDRV@_LFED41:	CALL	@SCNDRV@_MKRMNL  ; Open up next line
	JB	@SCNDRV@_LFEEDX  ; No room for LF
;SUCCESS: terminate current line with LF
@SCNDRV@_LFED42:	MOV	DH,AH
	MOV	AX," "
	CALL	@SCROUT  ; Put a blank at terminator posn
@SCNDRV@_LFED43:	CALL	@SCNRDT  ; Reread terminator in case of MKRMNL scroll up
	MOV	AH,DH
	MOV	AL,((@TRMLNF) and 0FFh)
	CALL	@SCNDRV@_SCNWTT  ; And terminate line with LF
	CMP	DL,byte [@LSTLIN]
	JNZ	@SCNDRV@_LFED95  ; BRIF no LSTPOS update
	MOV	byte [@LSTCOL],((0) and 0FFh)  ; LSTPOS moves to line beyond linefeed
	INC	byte [@LSTLIN]
	JMP	@SCNDRV@_LFED95
@SCNDRV@_LFED90:	PUSH	SI
	CALL	@SCNDRV@_MKRMNL  ; Open up next line
	POP	SI
	JB	@SCNDRV@_LFEEDX  ; No room
@SCNDRV@_LFED95:	CALL	@SCNDRV@_CSRDWN  ; Move to next line
	MOV	DH,byte [@WDOLFT]
	OR	SI,SI
	JZ	@SCNDRV@_LFEEDX
	MOV	AX,SI
	CALL	@SCROUT  ; Restore first char of insert linefeed
@SCNDRV@_LFEEDX:	CMP	DL,byte [@WDOBOT]
	JBE	@SCNDRV@_LFEEDZ
	MOV	DL,byte [@WDOBOT]
@SCNDRV@_LFEEDZ:	RET
;No room for linefeed, terminate this line and exit
@SCNDRV@_LFED69:	POP	AX
	JMP	@SCNDRV@_LFEEDX
; SUBTTL  CONTROL CHARACTER ROUTINES - Insert and MKRMCH

@SCNDRV@_LINSRT:	XOR	byte [@F_INST],((255) and 0FFh)  ;Toggle insert flag
	RET

;SUBROUTINE MKRMCH              ; This routine opens up space in logical lines
;**                     On entry:   (DH,DL)=posn to open space
;**                                 CH=number of spaces to open(1 or 2)
;**                     On exit:    (DH,DL)=same posn(DL value can change)
;**
end if
; EXTRN	BUF:WORD
if @GW_PASS = 1
@SCNDRV@_MKRMCH:	PUSH	SI
	PUSH	AX
	PUSH	CX
	PUSH	DX
	MOV	SI,@BUF
	MOV	DI,@BUF+128  ; SI and DI are overflow character buffers
	CALL	@SCNRDT
	PUSHF
	PUSH	AX
	CALL	@SCNDRV@_MVCHLN  ; Move characters over put overflow at [DI]
	XOR	CL,CL  ; CL=Iteration depth(and count of physical lines)
@SCNDRV@_MKRMC0:	OR	CH,CH
	JNZ	@SCNDRV@_MKRMC1  ; BRIF line overflowed
	POP	AX
	POPF
@SCNDRV@_MKRMCX:	ADD	CL,DL  ; CL=original line number
	POP	DX  ; DH=orginal column
	MOV	DL,CL  ; DL=original line number
@SCNDRV@_MKRMX2:	POP	CX
	POP	AX
	POP	SI
	RET
;Line overflow we must wrap char to next line
@SCNDRV@_MKRMC1:	POP	AX
	POPF  ; Get back old terminator
	JB	@SCNDRV@_MKRMC3  ; BRIF was EOL term'd
	JNZ	@SCNDRV@_MKRMC4  ; BRIF was WRAP or NULL_WRAP term'd
;Linefeed, make room for linefeed on next line
	PUSH	AX
	CALL	@SCNDRV@_LFWRAP
	POP	AX
	JB	@SCNDRV@_MKRMCQ  ;  No room, throw away overflow
	DEC	CH
	JZ	@SCNDRV@_MKRMCX  ; Only wrapped the linefeed, done
	JMP	@SCNDRV@_MKRMC4  ; Pass overflow to next line
;EOL terminatedd
@SCNDRV@_MKRMC3:	PUSH	AX
	CALL	@SCNDRV@_MKRMNL  ; Open up next line for overflow
	POP	AX
	JNB	@SCNDRV@_MKRMC4  ; BRIF room, wrap overflow
;No room for wrap, terminate this line with EOL and exit
@SCNDRV@_MKRMCQ:	CALL	@SCNRDT
	MOV	AL,((@TRMEOL) and 0FFh)
	CALL	@SCNDRV@_SCNWTT  ; No room for overflow, just terminate line
	JMP	@SCNDRV@_MKRMCX
;Insert overflow on next line
@SCNDRV@_MKRMC4:	CMP	DL,byte [@LSTLIN]
	JNZ	@SCNDRV@_MKRMC6  ; BRIF not on LSTPOS line
;AH=Old terminator posn, CH=Overflow count
	SUB	AH,CH
	CMP	AL,((@TRMNWP) and 0FFh)
	JNZ	@SCNDRV@_MKRMC5  ; BRIF wasn't NULL_WRAP, don't adjust posn
	DEC	AH
;AH=First position wrapped - 1
@SCNDRV@_MKRMC5:	CMP	AH,byte [@LSTCOL]
	JAE	@SCNDRV@_MKRMC6  ; BRIF did not wrap LSTCOL
;Wrapped LSTPOS
	MOV	byte [@LSTCOL],((0) and 0FFh)  ; Set LSTPOS to start of next line
	INC	byte [@LSTLIN]
@SCNDRV@_MKRMC6:	INC	DL  ; (DH,DL)=start of next line
	MOV	DH,byte [@WDOLFT]
	DEC	CL  ; Decrement interation counter
	XCHG	SI,DI  ; Use other overflow buffer for this line
	CALL	@SCNRDT
	PUSHF
	PUSH	AX
	PUSH	CX  ; Save char count
	CALL	@SCNDRV@_MVCHLN  ; Make room on this line for previous overflow
	MOV	BX,CX  ; Save count of overflow
	POP	CX  ; Get back overflow count in CH
	PUSH	SI  ; Save pointer to characters for insertion
;Loop to output characters which overflowed onto this line from previous line
@SCNDRV@_MKRMC7:	CLD  ; Scan forwards
	LODSW  ; Get a character
	CALL	@SCROUT  ; Output it
	INC	DH
	SUB	CH,((1) and 0FFh)
	JA	@SCNDRV@_MKRMC7  ; Output the next char
	POP	SI
	MOV	CH,BH  ; Restore overflow count for this line
	JMP	@SCNDRV@_MKRMC0  ; Wrap new overflow

;Wrap a linefeed to next line
@SCNDRV@_LFWRAP:	INC	DL
	CALL	@SCNDRV@_MKRMNL
	JB	@SCNDRV@_LFWPEX  ;  room, throw away overflow
	PUSH	DX
	CALL	@SCNDRV@_SCRDLN  ; Scroll this line down to next
	POP	DX
	CALL	@SCNDRV@_LFTERM  ; Make this line LF term'd
	CLC
@SCNDRV@_LFWPEX:	DEC	DL  ; Restore original line number
	RET

;SUBROUTINE MVCHLN              ; Open up space in physical line
;**                     On entry:   (DH,DL)=posn to open space at
;**                                 SI=address of buffer to put overflow chars
;**                     On exit:    (DH,DL)=same posn(DL might change if scroll)
;**                                 CH=No. of bytes overflowed
;**                                 BX destroyed
;**
@SCNDRV@_MVC30I:	JMP	@SCNDRV@_MVCH30
;MVC80I: JMP     MVCH80
@SCNDRV@_MVCHLN:	PUSH	DI
	PUSH	CX
	CMP	DL,byte [@LSTLIN]
	MOV	CL,byte [@LINLEN]
	JNZ	@SCNDRV@_MVCH00  ; BRIF within logical EOL(unless beyond TERM_POS)
	MOV	CL,byte [@LSTCOL]
@SCNDRV@_MVCH00:	CALL	@SCNDRV@_SCNRTL  ; AX=current physical terminator
	CMP	AH,DH
	JB	@SCNDRV@_MVC30I  ; BRIF inserting beyond end of physical
	CMP	DL,byte [@LSTLIN]
	JNZ	@SCNDRV@_MVCH03
	CMP	CL,AH
	JNB	@SCNDRV@_MVCH03  ; BRIF LSTPOS .GTE. TERM_POSN
	MOV	AH,CL  ; Else use LSTPOS as TERM_POSN
;We are inserting before end of physical line and LSTPOS .GTE. TERM_POSN
@SCNDRV@_MVCH03:	PUSH	DX
	PUSH	AX
	ADD	CH,AH  ; CH=last column for space needed
	SUB	CH,byte [@LINLEN]
	JA	@SCNDRV@_MVCH10  ; BRIF overflow
	XOR	BH,BH  ; Indicate no overflow
	JMP	@SCNDRV@_MVCH20
;We have overflow bytes to save
@SCNDRV@_MVCH10:	MOV	DH,AH
	SUB	DH,CH
	INC	DH  ; DH=column of first overflow to save
	CLC  ; Indicate call is from Screen Editor
	CALL	@SCRINP  ; Read an overflow char
	MOV	BX,CX  ; Save overflow count in BH
;Loop to move overflow character to save buffer
@SCNDRV@_MVCH14:	CLD
	STOSW  ; Save overflow char
	DEC	CH
	JZ	@SCNDRV@_MVCH20  ; All done with overflow save
	INC	DH
	CLC  ; Indicate call is from Screen Editor
	CALL	@SCRINP  ; Read an overflow char
	JMP	@SCNDRV@_MVCH14  ; And save it
;Move characters in line over
@SCNDRV@_MVCH20:	MOV	CX,BX  ; Restore # bytes overflowed to CH
	POP	AX  ; AH=term posn
	SUB	AH,CH  ; Adjust term posn so move doesn't overflow
	POP	DX  ; DH=start column of insert
	POP	BX  ; BH=number of bytes to move over
	MOV	CL,BL
	PUSH	CX  ; Save overflow count and CL for restore on exit
	MOV	CH,AH  ; CH=last column to move
	SUB	CH,DH
	INC	CH  ; CH=count of chars from CURPOS to TERMPOS
	PUSHF
	MOV	CL,((1) and 0FFh)  ; Move on one line
	MOV	AX,DX  ; FROM=CURPOS
	MOV	BL,DL
	ADD	BH,DH  ; TO=CURPOS+COUNT
	POPF
	JNZ	@SCNDRV@_MVCH21  ; BRIF count not zero, do move
	MOV	BH,DH  ; All characters to move overflowed
	JMP	@SCNDRV@_MVCH22  ; Just update terminator to current posn
@SCNDRV@_MVCH21:	CALL	@SCNDRV@_SCROL2  ; Move over characters
	ADD	BH,CH  ; New TERMPOS=TO+number of characters moved
	DEC	BH
@SCNDRV@_MVCH22:	POP	CX  ; CH=-(No. of bytes wrapped)
;CH=overflow count, CL=insert count, BH=terminator posn
@SCNDRV@_MVCH23:	CALL	@SCNRDT
	JB	@SCNDRV@_MVCH25
	JZ	@SCNDRV@_MVCH25
;We have wrapped chars, terminate either WRAP or NULL_WRAP
@SCNDRV@_MVCH24:	CMP	BH,byte [@LINLEN]
	MOV	AL,((@TRMWRP) and 0FFh)
	JZ	@SCNDRV@_MVCH26
	OR	CH,CH
	JZ	@SCNDRV@_MVCH26
	MOV	AL,((@TRMNWP) and 0FFh)  ; Null wrap that does not overflow changes to wrap
	MOV	BH,byte [@LINLEN]
	PUSH	AX
	PUSH	DX
	MOV	DH,BH
	MOV	AX," "  ; Blank DBLCHR destroyed by scroll
	CALL	@SCROUT
	POP	DX
	POP	AX
	JMP	@SCNDRV@_MVCH26
;Was EOL or LF terminated
@SCNDRV@_MVCH25:	OR	CH,CH
	JNZ	@SCNDRV@_MVCH24  ; Overflow means WRAP or NULL_WRAP
@SCNDRV@_MVCH26:	CMP	AH,BH
	JA	@SCNDRV@_MVCH27  ; Terminator beyond scroll end
	MOV	AH,BH
;AH=New terminator, CL=insert count
	CALL	@SCNDRV@_SCNWTT  ; Update terminator
@SCNDRV@_MVCH27:	CMP	DL,byte [@LSTLIN]
	JNZ	@SCNDRV@_MVCHEX  ; BRIF move is not on LSTPOS line
	CMP	BH,byte [@LSTCOL]
	JBE	@SCNDRV@_MVCHEX  ; BRIF end of move is before LSTPOS
	MOV	byte [@LSTCOL],BH  ; Else add number moved over to LSTPOS
@SCNDRV@_MVCHEX:	POP	DI
	RET
;Inserting beyond end of logical
@SCNDRV@_MVCH30:	MOV	CL,CH  ; Save insert count in CL
	ADD	CH,DH  ; CH=end of insert
	CMP	AL,((@TRMLNF) and 0FFh)
	JZ	@SCNDRV@_MVCH31  ; BRIF LF term'd cannot push null off end
	DEC	CH  ; Ignore one null push off end of physical
@SCNDRV@_MVCH31:	CMP	CH,byte [@LINLEN]
	JBE	@SCNDRV@_MVCH33  ; BRIF have room
;No room, return blanks overflow, update terminator
	SUB	CH,byte [@LINLEN]  ; CH=No. of overflow bytes
	MOV	AX," "
	PUSH	CX
@SCNDRV@_MVCH32:	CLD  ; Store overflow bytes(All blanks)
	STOSW
	DEC	CH
	JNZ	@SCNDRV@_MVCH32
	POP	CX  ; Restore CH=number of overflow bytes
	POP	BX
	MOV	BH,CH
	PUSH	BX  ; Put overflow count with original CL on stack
	MOV	BH,byte [@LINLEN]  ; BH=term posn, CH=overflow count, CL=insert count
	JMP	@SCNDRV@_MVCH23  ; Update terminator and LSTPOS, exit
;Have room, just update terminator
@SCNDRV@_MVCH33:	POP	BX
	MOV	BH,((0) and 0FFh)  ; Put overflow count(=0) on stack for return
	XCHG	BH,CH  ; BH=term posn, CH=overflow count, CL=insert count
	JMP	@SCNDRV@_MVCH23  ; New term posn still .LTE. LINLEN
; COMMENT	%
; ;On LSTLIN, possibly insert to LSTPOS or LSTPOS+COUNT
; ;N.B. We are guaranteed to be at a posn to left of TERM_POS
; ;Two cases: insert up to LSTPOS or insert up to LSTPOS+COUNT
; MVCH80: PUSH    DX
; 	PUSH    CX
; 	PUSH    AX
; 	MOVB    CL,AH           ; Save TERM_POS in CL for compare
; 	MOVB    DH,LSTCOL
; ;Scan from LSTPOS+1 to lesser of (LSTPOS+COUNT,TERM_POS) or non-blank character
; MVCH81: INCB    DH              ; Next column
; IFN     IBMLIK,<
; 	CLC                     ; Indicate call is from Screen Editor
; >                               ; IFN IBMLIK
; 	CALL    SCRINP          ; AX=character at this posn
; IFN     DBLCHR,<
; 	JNB     MVCH82          ; BRIF not reading second of double byte char
; 	INCB    DH              ; Restore DH(SCRINP decremented it)
; >                               ; IFN DBLCHR
; MVCH82: CMPI    AX," "
; 	JNZ     MVCH86          ; Found non-blank
; 	CMPB    DH,CL
; 	JAE     MVCH84          ; At TERM_POS
; MVCH83: DECB    CH
; 	JNZ     MVCH81          ; Not at LSTPOS+COUNT, continue scan
; ;Insert to LSTPOS+COUNT [;or TERM_POS+COUNT, whichever is smaller]
; MVCH84: POP     AX
; 	POP     CX
; 	POP     DX
; 	MOVB    AH,LSTCOL       ; Change end of FROM insert window to LSTPOS
; MVCH85: JMP     MVCH03          ; Insert to LSTPOS
; ;Insert to last blank after LSTPOS
; MVCH86: POP     AX              ; AX=current terminators
; 	POP     BX              ; BH=Count desired
; 	MOVB    CH,DH           ; CH=end of TO insert window
; 	DECB    CH
; 	POP     DX              ; (DH,DL)=current posn
; 	ADDB    BH,DH           ; BH=start of TO insert window
; 	SUBB    CH,BH           ; CH=character count to move
; 	JB      MVCH89          ; BRIF at end, just overwrite last char
; 	INCB    CH
; 	MOVBI   CL,1            ; Move on one line
; 	MOVB    BL,DL           ; (BH,BL)=start of TO window
; 	MOV     AX,DX           ; (AH,AL)=start of FROM window
; IFN     DBLCHR,<
; 	PUSH    DX
; 	PUSH    AX
; 	MOV     DX,AX
; 	ADDB    DH,CH
; IFN     IBMLIK,<
; 	CLC                     ; Indicate call is from Screen Editor
; >                               ; IFN IBMLIK
; 	CALL    SCRINP          ; Are we going to scroll half of a double byte char?
; 	MOVI    AX," "
; 	JNB     MVCH88
; 	INCB    DH
; MVCH88: CALL    SCROUT          ; Obliterate double byte char scrolled on top of
; 	POP     AX
; 	POP     DX
; >                               ; IFN DBLCHR
; 	CALL    SCROL2          ; Move characters over
; MVCH89: POP     CX
; 	XORB    CH,CH           ; No characters wrapped
; 	JMP     MVCHEX          ; All done
; %
;SUBROUTINE SCROL2              ; Used by insert code to move over chars in line
;                           On entry:   AH,BH,CH=scroll parameters

	@SCNDRV@_SCROL2 = @SCROLL  ; No DBLCHR save/restore
;SUBROUTINE SCNRTL              ; Read logical terminator for physical line
;**                     On entry:   DL=line number
;**                     On exit:    AX=terminators
;**                                 CF set indicates EOL terminator
;**                                 CF clear, ZF set indicates LF terminator
;**                                 If NULL_WRAP terminator AH=TERM_POS-1
@SCNDRV@_SCNRTL:	CALL	@SCNRDT  ; Get terminators
	JB	@SCNDRV@_SCNRT2  ; BRIF not NULL_WRAP
	JZ	@SCNDRV@_SCNRT2  ; BRIF not NULL_WRAP
	PUSHF
	CMP	AL,((@TRMNWP) and 0FFh)
	JNZ	@SCNDRV@_SCNRT1  ; BRIF not NULL_WRAP
	DEC	AH  ; Is NULL_WRAP, decrement posn
@SCNDRV@_SCNRT1:	POPF
@SCNDRV@_SCNRT2:	RET

;Wrap a linefeed(already a successful MKRMNL)
@SCNDRV@_LFTERM:	PUSH	word [@TRMCUR]
	PUSH	AX
	CALL	@SCNRDT  ; Read next line terminator
	MOV	AL,((@TRMLNF) and 0FFh)
	MOV	AH,byte [@WDOLFT]
	CALL	@SCNDRV@_SCNWTT  ; Write out LF terminator at left margin plus one
	POP	AX
	POP	word [@TRMCUR]
	RET
; SUBTTL CURSOR MOVEMENT within window

;       These routines return CF=1 when they do not change the posn.

;Cursor right within window(or within physical line if outside window)
@SCNDRV@_CSRADV:	INC	DH  ; Next column
	CMP	byte [@LINLEN],DH
	JAE	@SCNDRV@_CSRRET  ; BRIF Good value
	DEC	DH
	CALL	@SCNDRV@_CSRDWN
	JB	@SCNDRV@_CSRRET  ; BRIF can't change physical lines
	MOV	DH,byte [@WDOLFT]  ; First column
@SCNDRV@_CSRRET:	RET

;Cursor left within window(or within physical line if outside window)
@SCNDRV@_CSRREG:	DEC	DH  ; Previous column
	CMP	DH,byte [@WDOLFT]
	JNB	@SCNDRV@_CSRRET  ; BRIF good value
	INC	DH  ; Restore column
	CALL	@SCNDRV@_CSRUP
	JB	@SCNDRV@_CSRRET  ; BRIF can't change physical lines
	MOV	DH,byte [@LINLEN]  ; Last column
	RET

;Cursor up within window(or NOP if outside window)
@SCNDRV@_CSRUP:	CMP	byte [@WDOBOT],DL
	JB	@SCNDRV@_CSRRET  ; BRIF outside of window
	CMP	DL,byte [@WDOTOP]
	JB	@SCNDRV@_CSRRET
	STC
	JZ	@SCNDRV@_CSRRET  ; BRIF at top or outside of window
	CLC
	DEC	DL
	RET

;Cursor down within window(or NOP if outside window)
@SCNDRV@_CSRDWN:	CMP	DL,byte [@WDOTOP]
	JB	@SCNDRV@_CSRRET  ; BRIF outside window
	CMP	byte [@WDOBOT],DL
	JB	@SCNDRV@_CSRRET  ; BRIF at bottom or outside of window
	STC
	JZ	@SCNDRV@_CSRRET
	CLC
	INC	DL  ; Next line
	RET
; SUBTTL CURSOR MOVEMENT within logical line

;Cursor advance within logical line
;                   on entry:   DH=current column, DL=current line
;                   on exit:    If CF clear, DH=new column, DL=new line
;                                   Else DH=EOL column, DL=EOL line
;                                   ZF=1 if stop at LSTPOS
;                               AH=terminator column, AL=terminator value

@SCNDRV@_LCSADV:	CMP	DL,byte [@LSTLIN]
	JNZ	@SCNDRV@_LCSAD0  ; BRIF not at LSTPOS
	CMP	DH,byte [@LSTCOL]
	JB	@SCNDRV@_LCSAD0  ; BRIF not at LSTPOS
	CALL	@SCNRDT
	CMP	AH,AH  ; Set ZF=1 if stop at LSTPOS
	STC
@SCNDRV@_LCSADX:	RET
@SCNDRV@_LCSAD0:	CALL	@SCNRDT
	JB	@SCNDRV@_LCSAD2  ; BRIF at last line
@SCNDRV@_LCSAD1:	CALL	@SCNDRV@_CSRADV
	JB	@SCNDRV@_LCSADA  ; BRIF at end of window
	CMP	AH,DH
	JNB	@SCNDRV@_LCSADX  ; BRIF within logical line
	INC	DL
	MOV	DH,byte [@WDOLFT]  ; Else wrap to next physical of logical
	CLC
	RET
@SCNDRV@_LCSAD2:	CMP	AH,DH
	JA	@SCNDRV@_LCSAD1  ; BRIF not at EOL or beyond
@SCNDRV@_LCSADA:	OR	DH,DH  ; ZF=1(not stop at LSTPOS)
	STC
	RET
;Cursor regress within logical line
;                   on entry:   DH=current column, DL=current line
;                   on exit:    If CF clear, DH=new column, DL=new line
;                                   Else DH=EOL column, DL=EOL line
;                                   If stop at FSTPOS, ZF is set

@SCNDRV@_LCSREG:	CMP	DL,byte [@FSTLIN]
	JNZ	@SCNDRV@_LCSRG0  ; BRIF not at FSTPOS
	CMP	DH,byte [@FSTCOL]
	JA	@SCNDRV@_LCSRG0  ; BRIF not at FSTPOS
	STC
	RET  ; ZF=1, CF=1, stop at FSTPOS
@SCNDRV@_LCSRG0:	PUSH	BX
	MOV	BX,DX
	CALL	@SCNDRV@_CSRREG
	JB	@SCNDRV@_LCSRGA  ; BRIF at top of window
	CMP	BL,DL
	JZ	@SCNDRV@_LCSRGX  ; BRIF on same line, must be good posn
	CALL	@SCNRDT
	JNB	@SCNDRV@_LCSRGX  ; BRIF still on same logical line
	MOV	DL,BL  ; Move back to line we were on
	MOV	DH,byte [@WDOLFT]  ; And posn at start of that line
@SCNDRV@_LCSRGA:	OR	DH,DH  ; ZF=0(not stop at FSTPOS)
	STC
@SCNDRV@_LCSRGX:	POP	BX
	RET  ; Return CF set(at EOL)

@SCNDRV@_LSTART:
@SCNDRV@_LSTRT0:	CMP	DL,byte [@FSTLIN]
	JZ	@SCNDRV@_LSTRT1
	CALL	@SCNDRV@_CSRUP
	JB	@SCNDRV@_LSTRT1  ; Top of window must be start of line
	CALL	@SCNRDT
	JNB	@SCNDRV@_LSTRT0  ; BRIF this line is part of logical
	INC	DL
@SCNDRV@_LSTRT1:	MOV	DH,byte [@WDOLFT]
	JB	@SCNDRV@_LSTRTX  ; BRIF not using FSTPOS, use left margin
	MOV	DH,byte [@FSTCOL]
@SCNDRV@_LSTRTX:	RET
; SUBTTL  MISCELLANEOUS ROUTINES

;*********************************************************
;CHECK FOR WORD OR NON-WORD CHAR(ALPHA NUMERIC)

@SCNDRV@_ANCHK:	PUSH	DX
	CLC  ; Indicate call is from Screen Editor
	CALL	@SCRINP  ; Read character at current posn in DX
	JNB	@SCNDRV@_ANCH0  ; BRIF DH was not decremented
	INC	DH
@SCNDRV@_ANCH0:	OR	AH,AH
	JNZ	@SCNDRV@_ANCNO  ; BRIF is two-byte character - reject
	CMP	AL,((48) and 0FFh)
	JB	@SCNDRV@_ANCNO  ; BRIF is not alpha-numeric
	CMP	AL,((58) and 0FFh)
	JB	@SCNDRV@_ANYES  ; BRIF is numeric
	CMP	AL,((65) and 0FFh)
	JB	@SCNDRV@_ANCNO  ; BRIF is not alpha-numeric
	CMP	AL,((91) and 0FFh)
	JB	@SCNDRV@_ANYES  ; BRIF is alpha
	CMP	AL,((97) and 0FFh)
	JB	@SCNDRV@_ANCNO  ; BRIF is not alpha-numeric
	CMP	AL,((123) and 0FFh)
	JB	@SCNDRV@_ANYES  ; BRIF is small alpha
@SCNDRV@_ANCNO:	STC
	POP	DX
	RET

@SCNDRV@_ANYES:	CLC
	POP	DX
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
