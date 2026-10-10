; [ This translation created 10-Feb-83 by Version 4.3 ]

if @GW_PASS = 1

include 'OEM.H'

; TITLE   GIOLPT - Line Printer Machine Independent Device Driver Code

; COMMENT	*

; --------- --- ---- -- ---------
; COPYRIGHT (C) 1982 BY MICROSOFT
; --------- --- ---- -- ---------

; 	*
include 'GIO86U'

@GIOLPT@_MELCO=0
@GIOLPT@_TETRA=0
@GIOLPT@_ZENITH=0
@CPM86=0
include 'MSDOSU'

;OEM Switches

; PUBLIC	LPTDSP,LPTINI,LPTTRM
; EXTRN	DERBFM:NEAR,INIFDB:NEAR,UPDPOS:NEAR,$_LPT1:NEAR
; EXTRN	DEVBOT:NEAR,DEVBIN:NEAR

;Line Printer Dispatch Table

@LPTDSP:
	DW	(@DERBFM)  ;test EOF for file opened to this device
	DW	(@DERBFM)  ;LOC
	DW	(@DERBFM)  ;LOF
	DW	(@GIOLPT@_LPTCLS)  ;perform special CLOSE functions for this device
	DW	(@GIOLPT@_LPTSWD)  ;set device width
	DW	(@DERBFM)  ;GET/PUT random record from/to this device
	DW	(@GIOLPT@_LPTOPN)  ;perform special OPEN functions for this device
	DW	(@DERBFM)  ;input 1 byte from file opened on this device
	DW	(@GIOLPT@_LPTSOT)  ;output 1 byte to file opened on this device
	DW	(@GIOLPT@_LPTGPS)  ;POS
	DW	(@GIOLPT@_LPTGWD)  ;get device width
	DW	(@GIOLPT@_LPTSCW)  ;set device comma width
	DW	(@GIOLPT@_LPTGCW)  ;get device comma width
	DW	(@DEVBIN)  ;block input from file opened on this device
	DW	(@DEVBOT)  ;block output to file opened on this device

@LPTTRM:	RET
; SUBTTL Line Printer Primitive I/O Routines

end if
; EXTRN	LP1DCB:WORD
if @GW_PASS = 1

;LPT Device Control Block field definitions:

	@GIOLPT@__LPWID=0  ;device width (columns per line)
	@GIOLPT@__LPPOS=1  ;current column device is in
	@GIOLPT@__LPFLG=2  ;Boolean attributes mask for this device
	@GIOLPT@__LPCRF=1  ;non-zero=last char sent was Carriage Return

;LPTINI - called during BASIC initialization
; Entry - DI = -2*device id

@LPTINI:	PUSH	DI
	CALL	@GIOLPT@_GLPDCB  ;DI points to device control block
	MOV	byte [@GIOLPT@__LPWID+DI],((80) and 0FFh)  ;default width = 80 chars / line
	MOV	byte [@GIOLPT@__LPPOS+DI],((0) and 0FFh)  ;initial position = 0
	MOV	byte [@GIOLPT@__LPFLG+DI],((0) and 0FFh)  ;reset device Flags
	POP	DI
	RET

;LPTCLS - perform any device dependent close functions.
; Entry - SI points to File-Data-Block.
;         DI = -2*device id
; Exit  - All registers preserved.
;         This routine is called before BASIC releases the
;         file-data-block associated with this file.

@GIOLPT@_LPTCLS:	RET

;LPTSWD - set device width
; Entry - [DX] = new device width
;         DI = -2*device id

@GIOLPT@_LPTSWD:
	CALL	@GIOLPT@_GLPDCB  ;DI points to device control block
	MOV	byte [@GIOLPT@__LPWID+DI],DL
	RET

; EXTRN	DERIFN:NEAR,SCDBIN:NEAR
end if
; EXTRN	FILOPT:WORD
if @GW_PASS = 1

;LPTOPN - perform any device dependent open functions.
; Entry - [AL]=  device id
;                0 if default device,
;                1..n for Disk A:, B:, ...
;                -1..-n for non-disk devices
;         [BX] = file number (0..n)
;         [CX] = random record size if [FILMOD] = random
;                (if [CX] = 0, use default record size)
;         [DI] = device offset (2=LPTD, 4=SCRN, etc.)
;         [FILMOD] = file mode (one of the following)
;                    MD.SQI     ;sequential input
;                    MD.SQO     ;sequential output
;                    MD.RND     ;random
;                    MD.APP     ;append
;         [FILNAM] = filename
;         [FILEXT] = 1..3 byte filename extension
; Exit  - [SI] points to new FDB
;         FDB is linked into FDB chain with all standard
;         fields initialized.
;         All other registers are preserved.

@GIOLPT@_LPTOPN:	PUSH	AX  ;save device id for INIFDB
	CALL	@GIOLPT@_GLPDCB  ;DI points to device control block
	MOV	SI,@FILOPT  ;SI points to options string
	MOV	AH,((223) and 0FFh)  ;0DFH - Mask for mapping lower to upper case
	CLD  ;use Post-Increment addressing
	LODSB  ;[AL]=1st byte of option string
	AND	AL,AH  ;Map Lower to Upper Case (turn off b6)
	PUSHF  ;remember if BIN option was selected
	JE	@GIOLPT@_NOOPT  ;branch if no option specified
	CMP	AL,(("B") and 0FFh)
	JNE	@GIOLPT@_IFNERR  ;Bad File Name error if option not BIN
	LODSB  ;[AL]=next byte of option string
	AND	AL,AH  ;Map Lower Case to Upper Case
	CMP	AL,(("I") and 0FFh)
	JNE	@GIOLPT@_IFNERR  ;Bad File Name error if option not BIN
	LODSB  ;[AL]=next byte of option string
	AND	AL,AH  ;Map Lower Case to Upper Case
	CMP	AL,(("N") and 0FFh)
	JNE	@GIOLPT@_IFNERR  ;Bad File Name error if option not BIN
	LODSB  ;[AL]=next byte of option string
	OR	AL,AL
	JNE	@GIOLPT@_IFNERR  ;Error if not end of options
@GIOLPT@_NOOPT:
	MOV	DH,byte [@GIOLPT@__LPPOS+DI]  ;initial file column position
	MOV	DL,byte [@GIOLPT@__LPWID+DI]  ;initial file width
	POPF
	POP	AX  ;[AL]=device id
	PUSHF  ;remember if BIN option was selected
	MOV	AH,((@MD_SQO OR @MD_RND) and 0FFh)  ;allow open for output/random
	CALL	@INIFDB
	POPF
	JE	@GIOLPT@_NOBIN  ;branch if BIN option was not selected
	CALL	@SCDBIN  ;set BINARY file mode
@GIOLPT@_NOBIN:
	RET

@GIOLPT@_IFNERR:	JMP	@DERIFN  ;"illegal filename" error

;LPTSOT - Sequential Output.
; Entry - SI points to File-Data-Block.  0 if Pseudo FDB (for LLIST/LPRINT)
;         DI = -2*device id
;         [AL] = byte to be output.
; Exit  - SI, DI can be changed.
;         All other registers preserved
;         This routine keeps track of column position,
;         expands tabs, and forces a carriage return when line width
;         is exceeded.

@GIOLPT@_LPTSOT:	PUSH	BX  ;save caller's BX
	PUSH	AX  ;save char to be output
	CALL	@GIOLPT@_GLPDCB  ;DI points to line printer DCB
	MOV	BL,AL  ;[BL] = device id
	POP	AX  ;[AL] = byte to be output
	MOV	AH,BL  ;[AH] = device id
	POP	BX  ;restore caller's BX
	OR	SI,SI
	JZ	@GIOLPT@_NOTBIN  ;branch if not binary mode
	CMP	byte [@F_CODE+SI],((@FC_BIN) and 0FFh)
	JE	@GIOLPT@_LPROUT  ;if binary, branch to Raw-Output routine
@GIOLPT@_NOTBIN:	PUSH	BX
	PUSH	DX
	MOV	DX,word [@GIOLPT@__LPWID+DI]  ;[DL]=device width, [DH]=current column
	MOV	BX,@GIOLPT@_LPOUT1  ;BX points to Raw Output Routine
	JZ	@GIOLPT@_PSDFDB  ;branch if Pseudo FDB (LLIST/LPRINT)
;*** CAREFUL *** FLAGS must be preserved
; from OR SI,SI Above.
	MOV	DL,byte [@F_WID+SI]  ;Get width from FDB
@GIOLPT@_PSDFDB:
; EXTRN	CRIFEL:NEAR
	CALL	@CRIFEL  ;force CR if End-Of-Line
	MOV	byte [@GIOLPT@__LPPOS+DI],DH  ;save new column position
	POP	DX
	POP	BX
	RET

;Low-Level Line Printer Output (updates column position)
;For IBM Compatibility, the following filter performs the following translations
;    x x x CR x x x    === x x x CR LF x x x
;    x x x CR LF x x x === x x x CR LF x x x
;If LPT was opened for RANDOM mode, and WIDTH=255, then suppress LF which
;   follow carriage returns for IBM compatibility.

; Eat all LineFeeds which follow CarriageReturns with following algorithm:
; if (Char <> LF) or (LastWasCR = 0) then output (Char)
; if (Char = CR) then
;    Begin
;    LastWasCR = 1
;    if FDB.MODE<>RANDOM or FDB.WIDTH<>255 then
;       output(LF)
;    End
; else
;    LastWasCR = 0

; The only case where this is not compatible with IBM is when the user executes:
; PRINT CHR$(13);CHR$(10);...

; The best way this could have been done was by setting CRONLY=1 in the
; switch files and letting the device drivers append Line-Feeds if necessary.
; It was considered too late to make a change this drastic

@GIOLPT@_LPOUT1:	CALL	@UPDPOS  ;[DH]=new column position(AL, DH)
	PUSH	AX  ;save character to be output
	CMP	AL,((@ASCLF) and 0FFh)
	JNE	@GIOLPT@_LPOUT2  ;branch if not attempting to output LF
	TEST	byte [@GIOLPT@__LPFLG+DI],((@GIOLPT@__LPCRF) and 0FFh)
	JNE	@GIOLPT@_LPOUT3  ;brif last byte out was CR (eat LF)
@GIOLPT@_LPOUT2:
	CALL	@GIOLPT@_LPROUT  ;output the character
@GIOLPT@_LPOUT3:
	POP	AX  ;restore [AL]=char which was output
	AND	byte [@GIOLPT@__LPFLG+DI],((255-@GIOLPT@__LPCRF) and 0FFh)  ;reset last byte out was CR flag
	CMP	AL,((@ASCCR) and 0FFh)
	JNE	@GIOLPT@_LPOUTX  ;return if wasn't carriage return
	OR	byte [@GIOLPT@__LPFLG+DI],((@GIOLPT@__LPCRF) and 0FFh)  ;set last byte out was CR flag
	OR	SI,SI
	JZ	@GIOLPT@_OUTLF  ;branch if Pseudo FDB (LLIST/LPRINT)
	CMP	byte [@F_WID+SI],((255) and 0FFh)
	JNE	@GIOLPT@_OUTLF  ;output LF if width is not 255
	CMP	byte [@F_MODE+SI],((@MD_RND) and 0FFh)
	JE	@GIOLPT@_LPOUTX  ;suppress LF following CRs
@GIOLPT@_OUTLF:
	PUSH	AX
	MOV	AL,((@ASCLF) and 0FFh)
	CALL	@GIOLPT@_LPROUT
	POP	AX
@GIOLPT@_LPOUTX:
	RET

;Raw Line Printer Output routine
; Entry - [AL]=byte to be sent to current line printer
;         [AH]=device id (0..n)
; Exit  - Flags used, All other registers preserved.

; EXTRN	SNDLPT:NEAR,ERROR:NEAR,ERRDNA:NEAR,ERRDTO:NEAR,ERROTP:NEAR
; EXTRN	ERRDIO:NEAR
@GIOLPT@_LPROUT:
	PUSH	AX
	CALL	@SNDLPT  ;Call OEM routine to output to printer
	OR	AH,AH
	JNE	@GIOLPT@_LPERR  ;branch if OEM routine detected error
	POP	AX
	RET
@GIOLPT@_LPERR:
	MOV	AL,AH
	XOR	AH,AH  ;[AX]=error code 1..n
	DEC	AX  ;[AX]=error code 0..n
	MOV	DI,@GIOLPT@_LPERRT
	ADD	DI,AX  ;[DI] points to BASIC Error code
	MOV	DL,byte [cs:DI+0]
	CMP	AL,((3) and 0FFh)
	JB	@GIOLPT@_ERROR1  ;branch if legal error code
	MOV	DL,((@ERRDIO) and 0FFh)  ;map all other error codes to I/O error
@GIOLPT@_ERROR1:	JMP	@ERROR

@GIOLPT@_LPERRT:	DB	@ERRDNA
	DB	@ERRDTO
	DB	@ERROTP

;LPOS(X) function

; PUBLIC	LPOS
; EXTRN	SNGFLT:NEAR,CONINT:NEAR
@LPOS:	PUSH	BX
	CALL	@CONINT  ;Force FAC to byte integer in AL
	CBW
	OR	AX,AX  ;Test for LPT number 0 to map to 1
	JZ	@GIOLPT@_LPTN0  ;n = 0, so map to 1
	DEC	AX
	SHR	AX,1  ;Offset to correct DCB
@GIOLPT@_LPTN0:	MOV	BX,@LP1DCB+@GIOLPT@__LPPOS  ;Get address of LPOS in first LPT DCB
	ADD	BX,AX  ;Get address of LPOS in current LPT DCB
	MOV	AL,byte [BX+0]  ;[AL]=current 0 relative position
	INC	AL  ;return 1 relative number
	POP	BX
	JMP	@SNGFLT  ;return result to user

;LPTGPS - return current file position.
; Entry - SI points to File-Data-Block.
; Exit  - [AH] = current file column. (0-relative)
;         All other registers preserved

@GIOLPT@_LPTGPS:	CALL	@GIOLPT@_GLPDCB  ;DI points to device control block
	MOV	AH,byte [@GIOLPT@__LPPOS+DI]
	RET

;LPTGWD - get device width
; Entry - DI = -2*device id
; Exit  - [AH] = device width as set by xxxSWD
;         All other registers preserved

@GIOLPT@_LPTGWD:	CALL	@GIOLPT@_GLPDCB  ;DI points to device control block
	MOV	AH,byte [@GIOLPT@__LPWID+DI]
	RET

;LPTSCW - set device comma width
; Entry - [BX] = new device comma width
;         DI = -2*device id
; Exit  - SI, DI can be changed.
;         All other registers preserved

@GIOLPT@_LPTSCW:	RET

;LPTGCW - get device comma width
; Entry - DI = -2*device id
; Exit  - [BX] = device comma width as set by xxxSCW
;         All other registers preserved

@GIOLPT@_LPTGCW:	RET

;GLPDCB - get pointer to line printer device control block
; Entry - [DI] = -2*device id (2,4,..n)
; Exit  - DI points to the device control block for device DI.
;         [AX] = 0..n for LPT1, LPT2, ...

;************************************************************************
;* Note: IF LPT DCB size changes from 4, this routine should be changed *
;************************************************************************

@GIOLPT@_GLPDCB:
	MOV	AX,(@@S_LPT1-256)  ;[AX]=-device id for LPT1
	SHL	AX,1  ;[AX]=-2*device id for LPT1
	ADD	AX,DI  ;[AX]=0, 2, ... for LPT1, LPT2, ...
	MOV	DI,AX  ;[DI]=0, 2, ... for LPT1, LPT2, ...
	SHL	DI,1  ;[DI]=0, 4, ... for LPT1, LPT2, ...
	SHR	AX,1  ;[AX]=0, 1, ... for LPT1, LPT2, ...
	ADD	DI,@LP1DCB  ;[DI] points to LPTx device ctl block
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
