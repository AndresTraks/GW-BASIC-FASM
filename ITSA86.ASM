; [ This translation created 10-Feb-83 by Version 4.3 ]

if @GW_PASS = 1

include 'OEM.H'

; TITLE   ITSA86 - Resident Initialization for I8086

; COMMENT	*

; --------- --- ---- -- --------- -----------
; COPYRIGHT (C) 1982 BY MICROSOFT CORPORATION
; --------- --- ---- -- --------- -----------

;         by Len Oorthuys Microsoft Corp.
;         *

;************************************************************************
;*                                                                      *
;*  NOTE: Any code linked after this module is discarded after          *
;*        Initialization of BASIC.                                      *
;*                                                                      *
;************************************************************************

include 'GIO86U'

@CPM86=0
@ITSA86@_TETRA=0  ;Save DS in DATSEG(defined in CS and
;   used by interrupt routine).

include 'MSDOSU'

end if
; EXTRN	TEMP8:WORD,TXTTAB:WORD
if @GW_PASS = 1

; EXTRN	NODSKS:NEAR,LRUN:NEAR,READY:NEAR

; PUBLIC	WORDS
@WORDS:	DB	" Bytes free"  ;WORDS
	DB	0

; SUBTTL  INITSA
; PUBLIC	INITSA
@INITSA:
	CALL	@NODSKS
	CALL	@MAPINI  ;Init the new memory map
	MOV	BX,word [@TXTTAB]
	DEC	BX
	MOV	word [BX+0],0
	MOV	BX,word [@TEMP8]  ;POINT TO START OF COMMAND LINE
	MOV	AL,byte [BX+0]  ;GET BYTE POINTED TO
	OR	AL,AL  ;IF ZERO, NO FILE SEEN
	JZ	@ITSA86@_GREADY
	JMP	@LRUN  ;TRY TO RUN FILE
@ITSA86@_GREADY:	JMP	@READY
;BASVAR - Retrieve or Modify BASIC Internal Data Locations
;This routine provides a method to retrieve or modify certain BASIC internal
;data locations.  This routine is provided as support for PEEK and
;POKE filsters.  These data items have been documented to IBM GW BASIC users
;in the IBM Technical Reference Manual.

;Entry - AX = Value to set (if PSW.C set)
;        BX = 0 for current program line number
;             1 for last program line containing an error
;             2 for address of user program text
;             3 for address of user variable table
;        PSW.C set indicates to write the variable
;        PSW.C reset indicates to read the variable
;Exit  - AX = value of appropriate variable
;        BX modified

end if
; EXTRN	CURLIN:WORD,ERRLIN:WORD,TXTTAB:WORD,VARTAB:WORD
if @GW_PASS = 1
; PUBLIC	BASVAR
@ITSA86@_BVTAB:	DW	@CURLIN
	DW	@ERRLIN
	DW	@TXTTAB
	DW	@VARTAB

@BASVAR:
	PUSHF
	SHL	BX,1  ;make word offset
	POPF  ;preserve PSW.C (input parameter)
	MOV	BX,word [cs:@ITSA86@_BVTAB+BX]  ;Get address of appropriate variable
	JNB	@ITSA86@_BASVRD  ;Performing read function
	MOV	word [BX+0],AX  ;Perform write function
@ITSA86@_BASVRD:	MOV	AX,word [BX+0]  ;Perform read function
	RET
; SUBTTL  Initialization Support Routines
end if
; EXTRN	CSWFLG:WORD,CSWSIZ:WORD,MSWFLG:WORD,MSWSIZ:WORD,NEWDS:WORD
; EXTRN	STKLOW:WORD,MEMSIZ:WORD,TOPMEM:WORD,SAVSEG:WORD,MAXMEM:WORD
; EXTRN	FILTAB:WORD
; EXTRN	FREFLG:WORD
if @GW_PASS = 1

; EXTRN	CLEARC:NEAR,OMERR:NEAR
; EXTRN	SETCBF:NEAR
; EXTRN	LINPRT:NEAR,STROUT:NEAR,CRDO:NEAR
; EXTRN	CPMMEM:NEAR

; PUBLIC	MAPCLC,MAPINI

;MAPINI - Set up the final memory map.
;Entry  - NEWDS  = final DS:
;         MSWSIZ = final MAXMEM
;Exit   - DS: and stack moved.

@MAPINI:
;Move the stack to the end of the new memory map
	POP	BX  ;Return address
	CLI  ;disable external interrupts
; while changing memory map
	MOV	AX,word [@NEWDS]
	MOV	SS,AX
	MOV	SP,word [@MSWSIZ]
	PUSH	BX  ;Return address

;Move the data segment
	MOV	ES,AX  ;NEWDS
	XOR	SI,SI
	MOV	CX,word [@TXTTAB]  ;Amount of memory to move
	SHR	CX,1  ;In words
	CLD
	MOV	BX,DS
	CMP	AX,BX  ;Test for direction of copy
	JB	@ITSA86@_BLKCPY  ;brif destination is below source
	STD  ;Copy up
	MOV	SI,word [@TXTTAB]  ;starting from top
@ITSA86@_BLKCPY:
	MOV	DI,SI
 REP	MOVSW

;Set new data segment
	MOV	DS,AX  ;NEWDS
; EXTRN	SEGINI:NEAR
	CALL	@SEGINI
	MOV	AX,DS
	MOV	word [@SAVSEG],AX  ;For PEEK/POKE
	STI  ;enable external interrupts

;Insure zeros at TXTTAB
	MOV	BX,word [@TXTTAB]
	MOV	word [BX+0],0
	MOV	byte [BX+2],((0) and 0FFh)  ;Three zeros necessary

;Call CLEARC to set up stack and finalize the memory map
	MOV	AX,word [@MSWSIZ]
;Make sure that [TXTTAB]+<stack size>+32 does not overflow memory
	MOV	BX,word [@TOPMEM]
	SUB	BX,word [@STKLOW]  ;BX=stack size
	JBE	@ITSA86@_GOMERR  ;BRIF illegal stack(0 or less bytes)
	NEG	BX
	ADD	BX,AX  ;BX=new stack bottom
	JNB	@ITSA86@_GOMERR  ;BRIF MSWSIZ is less than stack size
	SUB	BX,32  ;Leave a little room for a program
	JB	@ITSA86@_GOMERR  ;BRIF no room left
	CMP	BX,word [@TXTTAB]  ;Is new MAXMEM big enough?
	JBE	@ITSA86@_GOMERR  ;BRIF new MAXMEM smaller than data area
@ITSA86@_MAXRQ1:	MOV	BX,AX
	SUB	BX,word [@MAXMEM]  ;Calc. seg. size difference
	MOV	word [@MAXMEM],AX  ;Memory request
	ADD	word [@TOPMEM],BX
	ADD	word [@STKLOW],BX
	ADD	word [@FILTAB],BX
	ADD	word [@MEMSIZ],BX
	POP	BX  ;Return address (BX saved by CLEARC)
	CALL	@CLEARC
	PUSH	BX  ;Return address (BX saved by CLEARC)

;Set up program segment prefix
	MOV	DX,DS
	MOV	AH,((38) and 0FFh)  ;Function ^H26
	INT	33  ;MSDOS function request

;Print free bytes message
	TEST	byte [@FREFLG],((255) and 0FFh)  ;BYTES FREE message flag
	JNZ	@ITSA86@_MAPINX  ;Exit - message not to be printed
	MOV	BX,word [@MEMSIZ]
	SUB	BX,word [@TXTTAB]
	DEC	BX
	DEC	BX
	CALL	@LINPRT  ;PRINT # OF BYTES FREE
	MOV	BX,@WORDS  ;TYPE THE HEADING
	CALL	@STROUT  ;"BYTES FREE"
	CALL	@CRDO  ;PRINT CARRIAGE RETURN
@ITSA86@_MAPINX:	RET

@ITSA86@_GOMERR:	JMP	@OMERR
; SUBTTL  End of the New CS:

;All code loaded after this label is resident only until routine MAPINI
;initializes the new memory map.

@ITSA86@_CSEND:

;MAPCLC - Calculate the final memory map limits.
;Entry  - CSWFLG = Flag nonzero when /C: option exists
;         CSWSIZ = /C: option size
;         MSWFLG = Flag nonzero when /M: option exists
;         MSWSIZ = /C: option size
;Exit   - NEWDS  = Final DS: address
;         MSWSIZ = Highest memory address (future MAXMEM)

@MAPCLC:
;Validate/get COM buffer size
	MOV	DX,@ITSA86@_CSEND  ;Location of COM buffer (New end of CS:)
	ADD	DX,15  ;Round to next higher paragraph
	MOV	CL,((4) and 0FFh)
	SHR	DX,CL
	MOV	CX,CS
	ADD	CX,DX  ;Segment offset of COM buffer
	MOV	DX,word [@CSWSIZ]  ;Segment size request
	TEST	byte [@CSWFLG],((255) and 0FFh)  ;Was there a /C: opt - PSW.Z for SETCBF
	CALL	@SETCBF  ;Report buffer size/loc
	JB	@ITSA86@_GOMERR  ; & validate size
	MOV	word [@CSWSIZ],DX  ;COM buffer size

;Calculate NEWDS (New DS:)
; DX  - COM buffer size
; NEWDS = (D+15/16) + DS:
	ADD	DX,15  ;Round off to paragraph
	SHR	DX,1
	SHR	DX,1
	SHR	DX,1
	SHR	DX,1
	ADD	DX,CX  ;Skip COM buffer
	JO	@ITSA86@_GOMERR
	MOV	word [@NEWDS],DX

;Validate the /M option or calculate the maximum possible MAXMEM
;1. Calcualte maximum MAXMEM based on the NEWDS
;2. If there was no /M option then goto 4
;3. Compare /M to the maximum and declare an error if /M is larger
;4. Save the new memory size as MSWSIZ
	PUSH	BX  ;Save text pointer
	MOV	BX,word [@CPMMEM]
	SUB	BX,DX  ;Avail paragraphs
	JB	@ITSA86@_GOMERR
	MOV	DX,65535/16  ;Max usable paragraphs
	CMP	BX,DX
	JB	@ITSA86@_MAXREQ  ;More than enough
	MOV	BX,DX
@ITSA86@_MAXREQ:	MOV	CL,((4) and 0FFh)
	SHL	BX,CL  ;DX has valid maximum bytes
	TEST	byte [@MSWFLG],((255) and 0FFh)
	JZ	@ITSA86@_NOMOPT  ;No memory option
	MOV	DX,word [@MSWSIZ]  ;Get /M: size
	CMP	BX,DX
	JB	@ITSA86@_GOMERR  ;Not enough for request
	MOV	BX,DX
@ITSA86@_NOMOPT:	MOV	word [@MSWSIZ],BX  ;New MAXMEM
;       ADDI    BX,^D256
;       JB      MAXRQ1                  ;BRIF very large MAXMEM, value OK
;       CMP     BX,TXTTAB               ;Is new MAXMEM big enough?
;       JBE     GOMERR                  ;BRIF new MAXMEM smaller than data area
	POP	BX
	RET

;SEGOFF     Convert end of memory segment to offset from current DS

;   On entry:   BX=last segment in memory
;               DS=current data segment

;   On exit:    BX=offset from current segment to paragraph specified by BX
;               Other registers unchanged, flags modified

; PUBLIC	SEGOFF
; EXTRN	OMERR:NEAR

@SEGOFF:	PUSH	CX
	MOV	CX,DS
	SUB	BX,CX  ;[BX]=number of paragraphs free for DSEG
	JBE	@ITSA86@_SGOFER  ;BRIF last segment is less than current
	MOV	CX,4095  ;[CX]=max num of paragraphs BASIC could use
	CMP	BX,CX
	JBE	@ITSA86@_LESS64  ;Brif less than 64k bytes available
	MOV	BX,CX  ;don't need more than 64k bytes
@ITSA86@_LESS64:
	MOV	CL,((4) and 0FFh)
	SHL	BX,CL  ;convert paragraphs to bytes
	POP	CX  ;restore caller's CX
	RET
@ITSA86@_SGOFER:	JMP	@OMERR

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
