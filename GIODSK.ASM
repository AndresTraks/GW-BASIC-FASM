; [ This translation created 10-Feb-83 by Version 4.3 ]

if @GW_PASS = 1

include 'OEM.H'

; SUBTTL  GLOBAL TEMPS and DEFS
; TITLE   GIODSK - BASIC-86 Generalized I/O Disk Driver

; COMMENT	*

; --------- --- ---- -- ---------
; COPYRIGHT (C) 1982 BY MICROSOFT
; --------- --- ---- -- ---------

;         T. Corbett      Microsoft   for BASIC-86 Generalized I/O
;                         Based on code written for BASCOM-86
;         *
include 'GIO86U'

@CPM86=0

include 'MSDOSU'

; EXTRN	CHRGTR:NEAR,SYNCHR:NEAR,OUTDO:NEAR
; EXTRN	DERNMF:NEAR,DERBFM:NEAR,DERBRN:NEAR,DERFAO:NEAR,FCERR:NEAR
; EXTRN	DERTMF:NEAR
; EXTRN	DERFAE:NEAR,DERFNF:NEAR,DERIOE:NEAR,DERDFL:NEAR,DERFOV:NEAR
; EXTRN	CONIA:NEAR,MAKINT:NEAR,MOVE1:NEAR,$NORMD:NEAR
; EXTRN	DEVBOT:NEAR
end if
; EXTRN	DFACLO:WORD,FAC:WORD,VALTYP:WORD
; EXTRN	RECRD:WORD,LBUFF:WORD,PBUFF:WORD
; EXTRN	FILNAM:WORD,FILNA2:WORD
if @GW_PASS = 1

	@ASCCR=13  ;Ascii carriage return
	@ASCCTZ=26  ;END OF FILE CHARACTER

;Disk Dispatch Table

; PUBLIC	DSKDSP
@DSKDSP:
	DW	(@GIODSK@_DSKEOF)  ;test EOF for file opened to this device
	DW	(@GIODSK@_DSKLOC)  ;LOC - sequential records / last random record
	DW	(@GIODSK@_DSKLOF)  ;LOF - file size
	DW	(@GIODSK@_DSKCLS)  ;perform special CLOSE functions for this device
	DW	(@FCERR)  ;set device width
	DW	(@GIODSK@_DSKRND)  ;GET/PUT random record from/to this device
	DW	(@GIODSK@_DSKOPN)  ;perform special OPEN functions for this device
	DW	(@GIODSK@_DSKSIN)  ;input 1 byte from file opened on this device
	DW	(@GIODSK@_DSKSOT)  ;output 1 byte to file opened on this device
	DW	(@GIODSK@_DSKGPS)  ;POS
	DW	(@GIODSK@_DSKGWD)  ;get device width
	DW	(@GIODSK@_DSKSCW)  ;set device comma width
	DW	(@GIODSK@_DSKGCW)  ;get device comma width
	DW	(@DFSTLD)  ;block input from file opened on this device
	DW	(@DEVBOT)  ;block output to file opened on this device

; SUBTTL  Misc. Disk Routines

;DSKEOF - test for End-Of-File on device.
; Entry - SI points to File-Data-Block.
; Exit  - [BX] = -1 if EOF, 0 if not EOF

@GIODSK@_DSKEOF:
	CMP	byte [@F_MODE+SI],((@MD_SQO) and 0FFh)  ;EOF( ) is Illegal
	JE	@GIODSK@_ER_BFM  ; for Sequential Output
@GIODSK@_ORNCHK:
	XOR	AL,AL
	CMP	byte [@F_ORCT+SI],AL  ;zero if End of File
	JE	@GIODSK@_WASEOF  ;Brif EOF
	CMP	byte [@F_MODE+SI],((@MD_RND) and 0FFh)  ;If mode is Random
	JZ	@GIODSK@_NOTEOF  ; then don't return true EOF
	CMP	byte [@F_BREM+SI],AL  ;Any bytes left in buffer?
	JNZ	@GIODSK@_CHKCTZ  ;Yes, look for Control-Z
	CALL	@GIODSK@_@SREADS  ;Fill the Buffer
	JMP	@GIODSK@_ORNCHK  ; and try again...
@GIODSK@_CHKCTZ:
	MOV	BX,@DATPSC
	SUB	BL,byte [@F_BREM+SI]  ;[BX] = char offset
	CMP	byte [@DATOFS+BX+SI],((@ASCCTZ) and 0FFh)  ;check for EOF
	JNZ	@GIODSK@_NOTEOF  ;Brif next char not EOF
@GIODSK@_WASEOF:
	MOV	BX,-1  ; -1 if EOF
	RET
@GIODSK@_NOTEOF:
	XOR	BX,BX  ;0 = not EOF
	RET

@GIODSK@_ER_BFM:	JMP	@DERBFM  ;"Bad File mode"

;DSKLOC - Number of Bytes in input buffer.
; Entry - SI points to File-Data-Block.
; Exit  - [BX] = result.

@GIODSK@_DSKLOC:
	CMP	byte [@F_MODE+SI],((@MD_RND) and 0FFh)
	MOV	BX,word [@F_CLOC+SI]  ;Use current for Sequential
	JNE	@GIODSK@_LOC1
	MOV	BX,word [@FD_LOG+SI]  ;Use logical for Random
@GIODSK@_LOC1:	RET

;DSKLOF - return file size in bytes.
; Entry - SI points to File-Data-Block.
; Exit  - [Floating-Point-Accumulator] = result.

@GIODSK@_DSKLOF:
	LEA	DX,dword [@FCB_FS+SI]  ;[DX] points to file size
	MOV	BX,@DFACLO-1  ;[BX] Target
	MOV	byte [BX+0],((0) and 0FFh)  ;zero overflow byte
	INC	BX
	MOV	CH,((4) and 0FFh)
	CALL	@MOVE1  ;Move file length to FAC
	MOV	byte [@FAC+1],CH  ;zero sign
	MOV	word [BX+0],CX  ;zero high bytes of FAC
	MOV	word [BX+2],((128+56)*256)  ;Initialize Exponent
	MOV	byte [@VALTYP],((8) and 0FFh)  ;Dbl prec value
	JMP	@@SNORMD  ;Normalize value
;DSKGPS - return current file position.
; Entry - SI points to File-Data-Block.
; Exit  - [AH] = current file column. (0-relative)
;         All other registers preserved

@GIODSK@_DSKGPS:	MOV	AH,byte [@F_POS+SI]  ;[AH]=current column
	RET

;DSKGWD - get device width
; Exit  - [AH] = device width as set by xxxSWD
;         All other registers preserved

@GIODSK@_DSKGWD:	MOV	AH,((255) and 0FFh)  ;disk files always have infinite width
	RET

;DSKSCW - set device comma width
; Entry - [BX] = new device comma width
; Exit  - SI, DI can be changed.
;         All other registers preserved

@GIODSK@_DSKSCW:

;DSKGCW - get device comma width
; Exit  - [BX] = device comma width as set by xxxSCW
;         All other registers preserved

@GIODSK@_DSKGCW:	RET

; SUBTTL  OPEN hook for Disk and all Directory handling

; EXTRN	INIFDB:NEAR
end if
; EXTRN	FILMOD:WORD,FREFDB:WORD
if @GW_PASS = 1

;DSKOPN - perform any device dependent open functions.
; Entry - [AL] = FILDEV = device id
;                0 if default device,
;                1..n for Disk A:, B:, ...
;                -1..-n for non-disk devices
;         [BX] = file number (0..n)
;         [CX] = random record size if [FILMOD] = random
;                (if [CX] = 0, use default record size)
;         [DI] = device offset (2=DSKD, 4=SCRN, etc.)
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

@GIODSK@_DSKOPN:  ;note: save [AL]=device ID till INIFDB
	CMP	byte [@FILMOD],((@MD_RND) and 0FFh)
	JNZ	@GIODSK@_DSKOP2  ;branch if not OPEN RANDOM
	OR	CX,CX
	JNZ	@GIODSK@_DSKOP2  ;branch if user requested Record-Size
	MOV	CX,@DATPSC  ;default to Bytes per Sector
@GIODSK@_DSKOP2:	PUSH	CX  ;save user requested Random-Record-Size
	ADD	CX,@FD_DAT-@FDBSIZ  ;add standard Disk FDB requirements
	MOV	AH,((255) and 0FFh)  ;all file-modes are legal for Disk
	MOV	DX,255  ;[DH]=initial file column position
;[DL]=initial file width
	CALL	@INIFDB  ;SI points to new file's FDB
	MOV	word [@FREFDB],SI  ;save pointer to FDB so FINPRT will
;release it if error occurs before file
;gets completely opened.
	PUSH	SI  ;save FDB pointer
	LEA	DI,dword [@FCB_DV+SI]  ;DI points to filename field within FDB
	MOV	SI,@FILNAM
	MOV	CX,@FNAML+1  ;Moving drive,name,ext
	CLD  ;Set Post-Increment mode
 REP	MOVSB  ; to FDB's FCB
	MOV	byte [DI+0],CL  ;Make sure ext field is zero
	ADD	DI,@FCB_NR-@FCB_EX  ;Advance to NR field
	MOV	AX,CX  ;[AX]=0
	CLD  ;Set Post-Increment mode
	STOSW
	STOSW
	STOSB  ;zero random record fields
	POP	SI  ;SI points to new FDB
	POP	AX  ;[AX]=random record size
	MOV	word [@FD_SIZ+SI],AX  ;save in FDB
	CALL	@GIODSK@_SETBUF  ;Set Buffer addr
	MOV	AL,byte [@FILMOD]  ;[AL]=file mode
	CMP	AL,((@MD_APP) and 0FFh)
	JNZ	@GIODSK@_NTOAPP  ;Brif not open append
	CALL	@GIODSK@_CHKFOP  ;check for file already open
@GIODSK@_NTOAPP:
	LEA	DX,dword [@F_FCB+SI]  ;[DX] = FCB for DOS calls
	CMP	AL,((@MD_SQO) and 0FFh)
	JNZ	@GIODSK@_OPNFIL  ;Brif not sequential output
	CALL	@GIODSK@_CHKFOP  ;must be unique
	@CALLOS	@C_DELE  ;Delete file if exists
@GIODSK@_MAKFIL:
	@CALLOS	@C_MAKE  ;Create file
	INC	AL  ;Too many files?
	JNZ	@GIODSK@_OPNSET  ;No, continue
	JMP	@DERTMF  ;"Too many files"
@GIODSK@_OPNFIL:
	@CALLOS	@C_OPEN  ;Try OPEN
	INC	AL
	JNZ	@GIODSK@_OPNSET  ;Brif found
	MOV	AL,byte [@FILMOD]  ;Mode
	CMP	AL,((@MD_APP) and 0FFh)
	JNZ	@GIODSK@_NTAPNF  ;Brif not append
	MOV	AL,((@MD_SQO) and 0FFh)  ; else change to seq output
	JMP	@GIODSK@_MAKFIL
@GIODSK@_NTAPNF:
	CMP	AL,((@MD_RND) and 0FFh)  ;If not Random
	JNZ	@GIODSK@_ER_FNF  ; then File not found error
	JMP	@GIODSK@_MAKFIL  ;and create new
@GIODSK@_ER_FNF:
	JMP	@DERFNF  ;"File not found"
@GIODSK@_OPNSET:
	MOV	word [@FCB_RC+SI],128  ;Record len = 128
	XOR	CX,CX
	MOV	word [@F_CLOC+SI],CX  ;Clear curloc
	MOV	word [@F_CLOC+2+SI],CX  ;Clear numloc
	MOV	AL,byte [@FILMOD]
	CMP	AL,((@MD_RND) and 0FFh)
	JZ	@GIODSK@_RNDFIN  ;Brif finish random open
	CMP	AL,((@MD_APP) and 0FFh)
	JZ	@GIODSK@_APPFIN  ;Brif finish append open
	CMP	AL,((@MD_SQI) and 0FFh)
	JNZ	@GIODSK@_OPNFIN  ;If not input get text pointer/exit
	CALL	@GIODSK@_@SREADS  ;Read 1st data block into buffer
@GIODSK@_OPNFIN:	MOV	word [@FREFDB],0  ;file is completely open.
;FINPRT won't release FDB.
	RET
@GIODSK@_RNDFIN:
	LEA	DI,dword [@FD_PHY+SI]  ;zero FD.PHY, FD.LOG, FD.OPS, sector buffer
	MOV	CX,(@FD_DAT-@FD_PHY)  ;number of bytes to be cleared
	XOR	AX,AX  ;zeros
	CLD  ;Set Post-Increment mode
 REP	STOSB  ;zero data buffer and variable cells
	JMP	@GIODSK@_OPNFIN

; Append - Seek to eof, read a sector, find byte eof,
;          correct no. of bytes remaining, finish up
;          by changing file mode to sequential output.
@GIODSK@_APPFIN:
	CMP	word [@FCB_FS+SI],CX  ;Test for empty file
	JNZ	@GIODSK@_NTZRF1  ;Brif file not empty
	CMP	word [@FCB_FS+2+SI],CX
	JNZ	@GIODSK@_NTZRF1
	MOV	byte [@F_MODE+SI],((@MD_SQO) and 0FFh)  ;Change mode to Seq output
	JMP	@GIODSK@_OPNFIN  ; and exit
@GIODSK@_NTZRF1:
	LEA	DI,dword [@FCB_RN+SI]  ;DI points to random record# field
	PUSH	SI  ;Save FDB pointer
	ADD	SI,@FCB_FS  ;Move to File Size
	TEST	byte [SI+0],((127) and 0FFh)  ;See if multiple of 128
	CLD  ;Set Post-Inc mode for next 10 lines
	PUSHF  ;and remember
	LODSB  ;Get low order of size
	ADD	AL,AL  ;Rotate hi bit into carry
	LODSW  ;Get middle word
	ADC	AX,AX  ;carry in, hi bit out
	STOSW  ;Save low word of rec no.
	LODSB  ;Get high byte
	MOV	AH,((0) and 0FFh)  ;Clear hi byte of rec no.
	ADC	AX,AX  ;consider carry
	STOSW  ;Store hi word of rec no.
	POPF  ;get record flag
	POP	SI
	JNZ	@GIODSK@_NOMTRC  ;Brif record not empty
	CALL	@GIODSK@_BAKURN  ; else backup so can align
@GIODSK@_NOMTRC:
	CALL	@GIODSK@_@SREADS  ;read a sector
	CALL	@GIODSK@_BAKURN  ;back up 1 record
	XOR	DX,DX  ;clear count of chars in buff
@GIODSK@_REDEOF:
	CALL	@GIODSK@_DSKINP  ;read until EOF
	JB	@GIODSK@_SETSQM  ;Brif physical EOF
	CMP	AL,((@ASCCTZ) and 0FFh)  ;check for logical eof (ctl Z)
	JZ	@GIODSK@_SETSQO  ;Brif found eof
	INC	DX
	JMP	@GIODSK@_REDEOF
@GIODSK@_SETSQM:
	XOR	DX,DX  ;zero count since next sector
	CALL	@GIODSK@_BAKURN  ;backup since read to far
@GIODSK@_SETSQO:
	MOV	byte [@F_MODE+SI],((@MD_SQO) and 0FFh)  ;now we're Seq output
	LEA	DI,dword [@F_CLOC+SI]
	XOR	AX,AX
	CLD  ;Set Post-Increment mode
	STOSW  ;zero curloc since empty
	MOV	byte [DI+0],DL  ;store no. of bytes left
	MOV	byte [@F_POS+SI],AL  ;zero print position
	JMP	@GIODSK@_OPNFIN
@GIODSK@_BAKURN:
	SUB	word [@FCB_RN+SI],1  ;Random rec no. -1
	JAE	@GIODSK@_BAKRET  ;Brif no underflow
	DEC	word [@FCB_RN+2+SI]  ;hi word -1
@GIODSK@_BAKRET:	RET

; SUBTTL  CLOSE (CLSFIL) hook for Disk files

;DSKCLS - perform any device dependent close functions.
; Entry - SI points to File-Data-Block.
; Exit  - All registers used.
;         This routine is called before BASIC releases the
;         file-data-block associated with this file.

@GIODSK@_DSKCLS:
	CMP	byte [@F_MODE+SI],((@MD_SQO) and 0FFh)
	JNE	@GIODSK@_NOFORC  ;Don't dump buffer unless Seq Output
	MOV	AL,((@ASCCTZ) and 0FFh)
	CALL	@GIODSK@_FILOU4  ;Write EOF char
	CMP	byte [@F_ORCT+SI],((0) and 0FFh)
	JE	@GIODSK@_NOFORC  ;Brif buffer flushed
	CALL	@GIODSK@_@SWRITS  ;Flush the buffer
@GIODSK@_NOFORC:
	CALL	@GIODSK@_SETBUF  ;Set DMA addr
	LEA	DX,dword [@F_FCB+SI]  ;[DX] = FCB
	@CALLOS	@C_CLOS  ;Close the file
	RET

; SUBTTL Disk Sequential Input

;DSKSIN - Sequential Input.
; Entry - SI points to File-Data-Block.
; Exit  - [AL] = next byte from file,
;         carry set if EOF.
;         All other registers preserved

@GIODSK@_DSKSIN:	CALL	@GIODSK@_DSKINP  ;get next byte from file
	JB	@GIODSK@_DSYEOF  ;branch if End-Of-File
	CMP	AL,((@ASCCTZ) and 0FFh)  ;check for CTL-Z
	JNE	@GIODSK@_DSNEOF  ;branch if not
	CMP	byte [@F_CODE+SI],((@FC_BIN) and 0FFh)
	JE	@GIODSK@_DSNEOF  ;CTL-Z is not EOF for Binary files
@GIODSK@_DSYEOF:	STC  ;set carry indicating EOF
	RET
@GIODSK@_DSNEOF:	OR	AL,AL  ;clear carry (no eof)
	RET

;DSKINP - get next byte from file [SI]
; Exit  - Carry set if EOF, else [AL]=next byte from file
;         All other registers preserved

@GIODSK@_DSKINP:
	CMP	byte [@F_MODE+SI],((@MD_RND) and 0FFh)
	JNE	@GIODSK@_SINP1  ;Brif not Random
	JMP	@GIODSK@_SINP50  ;Do Serial input from random
@GIODSK@_SINP1:
	CMP	byte [@F_MODE+SI],((@MD_SQO) and 0FFh)  ;If trying input on output file
	JE	@GIODSK@_FILLS1  ; then give "Input past end"
	CMP	byte [@F_BREM+SI],((0) and 0FFh)
	JE	@GIODSK@_FILLSQ  ;If buffer empty, get another
	PUSH	BX
	XOR	BX,BX
	MOV	BL,byte [@F_ORCT+SI]
	SUB	BL,byte [@F_BREM+SI]
	DEC	byte [@F_BREM+SI]  ;number left -1
	MOV	AL,byte [@DATOFS+BX+SI]  ;Get the character
	POP	BX
	OR	AL,AL  ;Clear carry
	RET
@GIODSK@_FILLSQ:
	CMP	byte [@F_ORCT+SI],((0) and 0FFh)
	JE	@GIODSK@_FILLS1  ;Brif EOF
	CALL	@GIODSK@_@SREADS  ;read next sector
	JNE	@GIODSK@_SINP1  ;If not EOF try again
@GIODSK@_FILLS1:
	STC  ;Return with carry
	MOV	AL,((@ASCCTZ) and 0FFh)  ; and EOF character
	RET

@GIODSK@_SINP50:  ;Serial Input from Random File
	PUSH	BX
	CALL	@GIODSK@_FOVCHK  ;Field overflow check
	MOV	AL,byte [@FD_DAT-1+BX+SI]  ;Get character
	CLC
	POP	BX
	RET
@GIODSK@_FOVCHK:
	MOV	BX,word [@FD_OPS+SI]  ;Get current posn
	CMP	BX,word [@FD_SIZ+SI]  ;check for end of field
	JE	@GIODSK@_ER_FOV  ;Brif field overflow
	INC	BX  ;posn +1
	MOV	word [@FD_OPS+SI],BX  ;store new posn
	RET
@GIODSK@_ER_FOV:
	JMP	@DERFOV  ;"Field Overflow"

; SUBTTL Disk Sequential Output

;DSKSOT - Sequential Output.
; Entry - SI points to File-Data-Block.
;         [AL] = byte to be output.
; Exit  - All registers preserved.

@GIODSK@_DSKSOT:
	CMP	byte [@F_MODE+SI],((@MD_SQI) and 0FFh)  ;If input then must be echoing
	JZ	@GIODSK@_FILOUX  ; or "Extra ignored", so toss it
	CMP	byte [@F_MODE+SI],((@MD_RND) and 0FFh)
	JNZ	@GIODSK@_FILOU4  ;branch if sequential access
	PUSH	BX  ;Do Serial output to random
	CALL	@GIODSK@_FOVCHK  ;check for FIELD overflow
	MOV	byte [@FD_DAT-1+BX+SI],AL  ;store character
	POP	BX
	JMP	@GIODSK@_SOUTPS  ;Update posn and exit
@GIODSK@_FILOU4:
	CMP	byte [@F_ORCT+SI],((@DATPSC) and 0FFh)
	JNE	@GIODSK@_SOUT2  ;Brif not at end of sector
	CALL	@GIODSK@_@SWRITS  ;Write previous sector
@GIODSK@_SOUT2:
	PUSH	BX
	XOR	BX,BX
	MOV	BL,byte [@F_ORCT+SI]  ;[BX] = Buffer offset
	MOV	byte [@DATOFS+BX+SI],AL  ;store char
	POP	BX
	INC	byte [@F_ORCT+SI]
@GIODSK@_SOUTPS:
	CMP	AL,((@ASCCR) and 0FFh)
	JNE	@GIODSK@_SOUT3
	MOV	byte [@F_POS+SI],((0) and 0FFh)  ;reset posn on CR
@GIODSK@_FILOUX:
	RET

@GIODSK@_SOUT3:
	CMP	AL,((" ") and 0FFh)
	CMC
	ADC	byte [@F_POS+SI],((0) and 0FFh)  ;posn +1  if printable char
	RET

; SUBTTL GET and PUT for Disk Files

	@GIODSK@_PGFLAG=1  ;On = PUT, Off = GET
	@GIODSK@_RELFLG=2  ;On = Relative, Off = Sequential
	@GIODSK@_DIRFLG=4  ;On = Write, Off = Read

@GIODSK@_ER_BRN:	JMP	@DERBRN  ;bad record number error
@GIODSK@_ER_FC:	JMP	@FCERR  ;function call error

;DSKRND - perform random I/O.
; Entry  - [AL] = function to be performed:
;                 0: get next record
;                 1: put next record
;                 2: get record [DX] (1-relative)
;                 3: put record [DX] (1-relative)
;          [SI] points to File-Data-Block
; Exit   - All registers are used.

@GIODSK@_DSKRND:
	TEST	AL,((@GIODSK@_RELFLG) and 0FFh)
	JNZ	@GIODSK@_RAND1  ;Brif not relative I/O
	MOV	DX,word [@FD_LOG+SI]  ;[DX] = current logical record
	INC	DX  ;Logical +1
	JMP	@GIODSK@_RAND2
@GIODSK@_RAND1:
	OR	DX,DX  ;See if ok
	JLE	@GIODSK@_ER_BRN  ;Error if record number .LEQ. 0
@GIODSK@_RAND2:
	MOV	word [@FD_LOG+SI],DX  ;Store next logical
	DEC	DX  ;[DX] = current logical
	MOV	word [@FD_OPS+SI],0  ;Clear output posn
	MOV	BX,word [@FD_SIZ+SI]  ;[BX] = logical record length
	PUSH	BX
	CMP	BX,@DATPSC  ;Logical = Physical?
	JE	@GIODSK@_RAND3  ;Brif so
	XCHG	AX,BX  ;Save flags
	MUL	DX  ;Logical * physical (byte off)
	XCHG	AX,BX  ;[DX,BX] = result
	ADD	BX,BX  ;Offset *2 (for /128)
	ADC	DX,DX  ;consider overflow
	OR	DH,DH
	JNZ	@GIODSK@_ER_FC  ;Brif too big
	MOV	DH,DL
	MOV	DL,BH  ;[DX] = physical record no.
	SHR	BL,1
	XOR	BH,BH  ;[BX] = offset into physical rec
	JMP	@GIODSK@_RAND4
@GIODSK@_RAND3:
	XOR	BX,BX  ;[BX] (offset = 0)

; [DX] = physical record number
; [BX] = offset into physical record
@GIODSK@_RAND4:
	MOV	word [@RECRD],DX  ;Save record no.
	LEA	CX,dword [@FD_DAT+SI]  ;[CX] = Field buffer addr
	MOV	word [@LBUFF],CX  ;Save Logical buffer addr
	POP	DX  ;Get record length

; [DX] = bytes left to transfer (initially record length)
; [BX] = offset into current record
@GIODSK@_NXTOPD:
	LEA	CX,dword [@DATOFS+SI]  ;[CX] = Physical buffer addr
	ADD	CX,BX  ;       + offset
	MOV	word [@PBUFF],CX  ;Save physical offset
	MOV	CX,@DATPSC
	SUB	CX,BX  ;[CX] = bytes left in buffer
	CMP	CX,DX  ;want smaller of bufl, recl
	JB	@GIODSK@_DATMOF  ;[CX] = left in buffer
	MOV	CX,DX  ;[CX] = left in record
@GIODSK@_DATMOF:
	TEST	AL,((@GIODSK@_PGFLAG) and 0FFh)
	JZ	@GIODSK@_FIVDRD  ;Brif read (GET)
	CMP	CX,@DATPSC
	JAE	@GIODSK@_NOFVRD  ;Brif writing entire sector
	CALL	@GIODSK@_GETSUB  ; else read current sector
@GIODSK@_NOFVRD:
	PUSH	SI
	PUSH	CX
	MOV	SI,word [@LBUFF]
	MOV	DI,word [@PBUFF]
	SHR	CX,1
	CLD  ;Set Post-Increment mode
 REP	MOVSW
	JNB	@GIODSK@_EVENLP
	MOVSB
@GIODSK@_EVENLP:
	POP	CX
	POP	SI
	CALL	@GIODSK@_PUTSUB  ;Write thru to current sector
	JMP	@GIODSK@_NXFVBF

@GIODSK@_FIVDRD:
	CALL	@GIODSK@_GETSUB  ;Read current record
	PUSH	SI
	PUSH	CX
	MOV	SI,word [@PBUFF]
	MOV	DI,word [@LBUFF]
	SHR	CX,1
	CLD  ;Set Post-Increment mode
 REP	MOVSW
	JNB	@GIODSK@_EVENPL
	MOVSB
@GIODSK@_EVENPL:
	POP	CX
	POP	SI
@GIODSK@_NXFVBF:
	INC	word [@RECRD]  ;current record +1
	ADD	word [@LBUFF],CX  ;logical offset +length
	SUB	DX,CX  ;offset - bytes transfered
	XOR	BX,BX  ;zero buffer offset
	OR	DX,DX  ;More to transfer?
	JNZ	@GIODSK@_NXTOPD  ; then continue
	RET

; Sector I/O routines for Random

@GIODSK@_PUTSUB:
	OR	AL,((@GIODSK@_DIRFLG) and 0FFh)  ;Set write flag
	JMP	@GIODSK@_PGSUB1
@GIODSK@_GETSUB:
	AND	AL,((255-@GIODSK@_DIRFLG) and 0FFh)  ;Clear write flag (read)
@GIODSK@_PGSUB1:
	PUSH	AX
	PUSH	BX
	PUSH	CX
	PUSH	DX
	MOV	BX,word [@RECRD]  ;Get record no.
	INC	BX
	CMP	BX,word [@FD_PHY+SI]  ;current record in buffer?
	JNE	@GIODSK@_NTREDS  ;Brif not
	TEST	AL,((@GIODSK@_DIRFLG) and 0FFh)  ;Was it read?
	JZ	@GIODSK@_PGRET  ; then got it
@GIODSK@_NTREDS:
	DEC	BX
	MOV	word [@F_CLOC+SI],BX  ;Set CURLOC to physical rec.
	MOV	byte [@F_ORCT+SI],((@DATPSC) and 0FFh)
	MOV	byte [@F_BREM+SI],((@DATPSC) and 0FFh)
	MOV	word [@FCB_RN+SI],BX  ;Set record number
	MOV	word [@FCB_RN+2+SI],0
	TEST	AL,((@GIODSK@_DIRFLG) and 0FFh)
	JZ	@GIODSK@_GET1  ;Brif read
	CALL	@GIODSK@_@SWRITS  ; else Write it
	JMP	@GIODSK@_PGRET
@GIODSK@_GET1:
	CALL	@GIODSK@_@SREADS  ;Read it
@GIODSK@_PGRET:	POP	DX
	POP	CX
	POP	BX
	POP	AX
	RET

; SUBTTL Primitive Disk sector I/O routines

;$READS - Read sector from file
; Entry - SI points to FDB
; Exit  - [AL] = 0 if no error.  FLAGS used.
;         All other registers are preserved

@GIODSK@_@SREADS:
	PUSH	CX
	PUSH	DI
	INC	word [@F_CLOC+SI]  ;Logical record +1
	MOV	CX,@DATPSC/2
	XOR	AX,AX
	LEA	DI,dword [@DATOFS+SI]
	CLD  ;Set Post-Increment mode
 REP	STOSW  ;zero physical buffer
	CALL	@GIODSK@_SETBUF  ;Set DMA
	MOV	AH,((@C_RNDR) and 0FFh)
	CALL	@GIODSK@_ACCFIL  ;Read random
	OR	AL,AL
	MOV	AL,((0) and 0FFh)  ;Len = 0 for EOF
	JNZ	@GIODSK@_READ1
	MOV	AL,((@DATPSC) and 0FFh)  ; else len = sector size
@GIODSK@_READ1:
	MOV	byte [@F_ORCT+SI],AL  ;Clear offset into buffer
	MOV	byte [@F_BREM+SI],AL  ;Set number of bytes left
	OR	AL,AL  ;zero if EOF
	POP	DI
	POP	CX
	RET

;$WRITS - Write sector to file
; Entry - SI points to FDB
; Exit  - All registers preserved

@GIODSK@_@SWRITS:
	PUSH	AX
	MOV	byte [@F_ORCT+SI],((0) and 0FFh)  ;Clear buffer offset
	CALL	@GIODSK@_SETBUF  ;Set DMA
	MOV	AH,((@C_RNDW) and 0FFh)
	CALL	@GIODSK@_ACCFIL  ;Write Random
	CMP	AL,((255) and 0FFh)
	JZ	@GIODSK@_ER_TMF  ;Brif "Too many Files"
	DEC	AL
	JZ	@GIODSK@_ER_IOE  ;Brif error extending file
	DEC	AL
	JNZ	@GIODSK@_WRITE1
	MOV	byte [@F_MODE+SI],((@MD_SQI) and 0FFh)  ;So CLOSE won't give same error
;when it tries to output CTL-Z EOF
	JMP	@DERDFL  ;"Disk Full"
@GIODSK@_WRITE1:
	INC	word [@F_CLOC+SI]  ;Logical record +1
	POP	AX
	RET

@GIODSK@_ER_TMF:	JMP	@DERTMF  ;"Too many Files"
@GIODSK@_ER_IOE:	JMP	@DERIOE  ;"Device I/O error"

;Set OS I/O buffer address to DATOFS(.SI)

@GIODSK@_SETBUF:
	PUSH	DX
	LEA	DX,dword [@DATOFS+SI]  ;[DX] = Data buffer addr
	@CALLOS	@C_BUFF
	POP	DX
	RET

@GIODSK@_ACCFIL:
	PUSH	DX
	LEA	DX,dword [@F_FCB+SI]  ;[DX] = FCB
	@CALLOS  ;Do OS I/O Op
	INC	word [@FCB_RN+SI]  ;Record no. +1
	JNZ	@GIODSK@_ACCFL1
	INC	word [@FCB_RN+2+SI]  ;High order +1
@GIODSK@_ACCFL1:
	CMP	AH,((@C_RNDW) and 0FFh)  ;Was it Random Write?
	JNE	@GIODSK@_ACCFL2  ;Brif not
	OR	AL,AL  ; else map into 1.4 errors
	JZ	@GIODSK@_ACCRET  ;Brif no errors
	CMP	AL,((5) and 0FFh)
	JE	@GIODSK@_ER_TMF  ;5 - Too many files
	CMP	AL,((3) and 0FFh)
	MOV	AL,((1) and 0FFh)  ;Map 5 to 1
	JE	@GIODSK@_ACCRET
	INC	AL  ; else Disk full
	JMP	@GIODSK@_ACCRET
@GIODSK@_ACCFL2:
	CMP	AL,((3) and 0FFh)  ;Partial sector read?
	JNE	@GIODSK@_ACCRET  ;Brif not
	XOR	AL,AL  ;Map 3 to 0 (no error)
@GIODSK@_ACCRET:
	POP	DX
	RET

; SUBTTL CHKFOP - Check for file already OPEN

end if
; EXTRN	FILTAB:WORD,STKLOW:WORD
if @GW_PASS = 1

; Entry: SI points to FDB in question
; Exit:  Control returns to DERFAO if file is open
; Uses:  CX,DI

@GIODSK@_CHKFOP:
	PUSH	AX
	CMP	byte [@FCB_DV+SI],((0) and 0FFh)  ;Default Drive?
	JNE	@GIODSK@_NTCRDV
	@CALLOS	@C_GDRV
	INC	AL  ;Convert A: to 1.. etc.
	MOV	byte [@FCB_DV+SI],AL  ;Store real drive no.
@GIODSK@_NTCRDV:
	MOV	DI,word [@FILTAB]  ;Start with first FDB in chain
@GIODSK@_CHKNFL:
	CMP	DI,word [@STKLOW]
	JE	@GIODSK@_CHKFLX  ;branch if at end of FDB chain
	CMP	SI,DI
	JE	@GIODSK@_IGNTFL  ;branch if same as FDB in question
	PUSH	SI
	PUSH	DI
	ADD	SI,@F_FCB
	ADD	DI,@F_FCB
	MOV	CX,@FNAML+1
;compare filenames, mapping lower case to upper case
@GIODSK@_CMPLOP:
	MOV	AL,byte [SI+0]  ;get char from filename1
	CALL	@GIODSK@_MAKUPC  ;[AL]=uppercase([AL])
	MOV	AH,AL
	MOV	AL,byte [DI+0]  ;get char from filename2
	CALL	@GIODSK@_MAKUPC  ;[AL]=uppercase([AL])
	CMP	AL,AH
	JNE	@GIODSK@_NTSAME  ;branch if not the same filename
	INC	SI  ;bump filename1 pointer
	INC	DI  ;bump filename2 pointer
	LOOP	@GIODSK@_CMPLOP  ;compare all characters in filenames
	JMP	@DERFAO  ;error, file already open
@GIODSK@_NTSAME:	POP	DI
	POP	SI
@GIODSK@_IGNTFL:
	MOV	DI,word [@F_NEXT+DI]  ;get next FDB in chain
	JMP	@GIODSK@_CHKNFL
@GIODSK@_CHKFLX:
	POP	AX
	RET

@GIODSK@_MAKUPC:
	CMP	AL,(("a") and 0FFh)
	JB	@GIODSK@_NOTLC  ;branch if not a..z
	CMP	AL,(("z"+1) and 0FFh)
	JNB	@GIODSK@_NOTLC  ;branch if not a..z
	AND	AL,((223) and 0FFh)  ;map a..z to A..Z
@GIODSK@_NOTLC:
	RET

; SUBTTL  DFSTLD - Fast Binary Program Load (from DISK)

; PUBLIC	DFSTLD
; EXTRN	OUTLOD:NEAR
end if
; EXTRN	FRETOP:WORD,PTRFIL:WORD
if @GW_PASS = 1

;DFSTLD - read block of memory from Disk
; Entry - [BX] = offset of destination
;         [CX] = maximum number of bytes to read
;         [DX] = data segment of destinanation
;         PTRFIL points to FDB of file to be loaded
; Exit  - BX points 1 byte beyond last byte read
;         Carry set reached end-of-file before CX bytes were read

@DFSTLD:
	PUSH	BX  ;save start adr
	PUSH	CX  ;save max byte count
	PUSH	DS  ;save BASIC's Data Segment adr
	PUSH	BX  ;save start adr
	PUSH	DX  ;save block read Data Segment adr
	MOV	SI,word [@PTRFIL]  ;SI points to current FDB
	MOV	AL,byte [@F_ORCT+SI]
	SUB	AL,byte [@F_BREM+SI]  ;[AL]=# bytes read so far
	MOV	byte [@FCB_RN+SI],AL  ;set next rec #
	MOV	word [@FCB_RC+SI],1  ;Set File logical record size = 1 byte
	POP	DS  ;[DS]=segment adr of block read
	POP	DX  ;[DX]=start adr
	@CALLOS	@C_BUFF  ;Set DMA to TXTTAB
	POP	DS  ;restore BASIC's data segment adr
	LEA	DX,dword [@F_FCB+SI]  ;FCB
	POP	CX  ;[CX]=max number of bytes to read
	@CALLOS	@C_RBR  ;Load the Program!
	POP	BX  ;BX points to start of load
	ADD	BX,CX  ;BX points 1 byte beyond last byte read
	CMP	AL,((1) and 0FFh)
	CMC  ;set carry if [AL] exceeds 1 (EOF)
	RET

; SUBTTL  PROSAV - Protected SAVE
; PUBLIC	PROSAV,CMPFBC
; EXTRN	SCCPTR:NEAR,GTMPRT:NEAR,BINPSV:NEAR,$EXPCN:NEAR,$LOGP:NEAR
end if
; EXTRN	TXTTAB:WORD,VARTAB:WORD,CURLIN:WORD,PROFLG:WORD,TEMP:WORD
if @GW_PASS = 1

@PROSAV:	CALL	@CHRGTR  ;skip "P"
	MOV	word [@TEMP],BX  ;Save text pointer
	CALL	@SCCPTR  ;Get rid of GOTO pointers
	CALL	@PENCOD  ;Encode binary
	MOV	AL,((254) and 0FFh)  ;ID byte for Protected files
	CALL	@BINPSV  ;Do the SAVE
	CALL	@GIODSK@_PDECOD  ;Decode binary
	JMP	@GTMPRT  ;return to NEWSTT

@GIODSK@_GETFSZ:	MOV	BX,@FD_SIZ  ;Point to record size
	JMP	@GIODSK@_GETFP1  ;Continue
@GIODSK@_GETFPS:	MOV	BX,@FD_OPS  ;Point to output position
@GIODSK@_GETFP1:	ADD	BX,CX  ;Add offset into buffer
	MOV	DX,word [BX+0]  ;Get value
	RET

@CMPFBC:	MOV	CX,BX  ;Copy file data block into [CX]
@GIODSK@_CMPFPS:	CALL	@GIODSK@_GETFPS  ;Get present posit
	PUSH	DX  ;Save it
	CALL	@GIODSK@_GETFSZ  ;Get file size
	MOV	BX,DX  ;into [BX]
	POP	DX  ;Get back posit
	CMP	BX,DX  ;See if were at end
@GIODSK@_RET12:	RET

	@GIODSK@_N1=11  ;Number of bytes to use from ATNCON
	@GIODSK@_N2=13  ;Number of bytes to use from SINCON

; PUBLIC	PENCOD
@PENCOD:	MOV	CX,@GIODSK@_N1+@GIODSK@_N2*256  ;Initialize both counters
	MOV	BX,word [@TXTTAB]  ;Starting point
	MOV	DX,BX  ;Into [DX]
@GIODSK@_ENCDBL:	MOV	BX,word [@VARTAB]  ;At end?
	CMP	BX,DX  ;Test
	JZ	@GIODSK@_RET12  ;Yes
	MOV	BX,@@SEXPCN
	MOV	AL,CL  ;Use [CL] to index into it
	CBW
	ADD	BX,AX
	MOV	SI,DX
	CLD  ;Set Post-Increment mode
	LODSB  ;[AL]=byte from program
	SUB	AL,CH  ;Subtract counter for no reason
	XOR	AL,byte [cs:BX+0]  ;XOR entry
	PUSH	AX  ;Save result
	MOV	BX,@@SLOGP
	MOV	AL,CH
	CBW
	ADD	BX,AX
	POP	AX  ;Get back current byte
	XOR	AL,byte [cs:BX+0]  ;XOR on this one too
	ADD	AL,CL  ;Add counter for randomness
	MOV	DI,DX
	CLD  ;Set Post-Increment mode
	STOSB  ;store back in program
	INC	DX  ;Incrment pointer
	DEC	CL  ;decrment first table index
	JNZ	@GIODSK@_CNTZER  ;Still non-Zero
	MOV	CL,((@GIODSK@_N1) and 0FFh)  ;Re-initialize counter 1
@GIODSK@_CNTZER:	DEC	CH  ;dedecrement counter-2
	JNZ	@GIODSK@_ENCDBL  ;Still non-zero, go for more
	MOV	CH,((@GIODSK@_N2) and 0FFh)  ;Re-initialize counter 2
	JMP	@GIODSK@_ENCDBL  ;Keep going until done
; PUBLIC	PROLOD
@PROLOD:
@GIODSK@_PDECOD:	MOV	CX,@GIODSK@_N1+@GIODSK@_N2*256  ;Initialize both counters
	MOV	BX,word [@TXTTAB]  ;Starting point
	MOV	DX,BX  ;Into [D,E]
@GIODSK@_DECDBL:	MOV	BX,word [@VARTAB]  ;At end?
	CMP	BX,DX  ;Test
	JZ	@GIODSK@_RET12  ;Yes
	MOV	BX,@@SLOGP
	MOV	AL,CH
	CBW
	ADD	BX,AX
	MOV	SI,DX
	CLD  ;Set Post-Increment mode
	LODSB  ;[AL]=byte from program
	SUB	AL,CL  ;Subtract counter for randomness
	XOR	AL,byte [cs:BX+0]  ;XOR on this one too
	PUSH	AX  ;Save result
	MOV	BX,@@SEXPCN
	MOV	AL,CL  ;Use [CL] to index into it
	CBW
	ADD	BX,AX
	POP	AX  ;Get back current byte
	XOR	AL,byte [cs:BX+0]  ;XOR entry
	ADD	AL,CH  ;Add counter for no reason
	MOV	DI,DX
	CLD  ;Set Post-Increment mode
	STOSB  ;store [AL] back in program
	INC	DX  ;Increment pointer
	DEC	CL  ;decrment first table index
	JNZ	@GIODSK@_CNTZR2  ;Still non-Zero
	MOV	CL,((@GIODSK@_N1) and 0FFh)  ;Re-initialize counter 1
@GIODSK@_CNTZR2:	DEC	CH
	JNZ	@GIODSK@_DECDBL  ;Decrement counter-2, Still non-zero, go for more
	MOV	CH,((@GIODSK@_N2) and 0FFh)  ;Re-initialize counter 2
	JMP	@GIODSK@_DECDBL  ;Keep going until done

; PUBLIC	PROCHK,PRODIR
@PRODIR:	PUSH	BX  ;Save [H,L]
	MOV	BX,word [@CURLIN]  ;Get current line #
	INC	BX  ;Direct? (if BX=0, direct)
	POP	BX  ;Restore [H,L]
	JZ	@PROCHK
	RET

@PROCHK:	PUSHF  ;Save flags
	MOV	AL,byte [@PROFLG]  ;Is this a protected file?
	OR	AL,AL  ;Set CC's
	JNZ	@GIODSK@_FCERRA  ;Yes, give error
	POPF  ;Restore flags
	RET

@GIODSK@_FCERRA:	JMP	@FCERR
; SUBTTL  KILL, FILES, NAME commands

; PUBLIC	FILES,KILL,NAME
; EXTRN	FRMEVL:NEAR,FRESTR:NEAR,CRDO:NEAR,POLKEY:NEAR
end if
; EXTRN	LINLEN:WORD,BUF:WORD
if @GW_PASS = 1

;Assumptions:
; FILNAM and FILNA2 are 33 byte buffers (for temp FCBs)

;FILES [ filename ]
; FILES command [List the Directory]
; If filename is omitted, all files on the logged
; disk are listed.
; If supplied, all files matching filename or wildcards
; are listed.

@FILES:
	JE	@GIODSK@_NOARG  ;Brif no filename argument given
	CALL	@GIODSK@_NAMFIL  ;[SI] points to 1st byte of filename
;[CX] = number of bytes in filename
	CMP	CL,((2) and 0FFh)
	JNE	@GIODSK@_GOTNAM  ;branch if not "<drive>:"
	MOV	AX,word [SI+0]  ;[AX]=filename
	CMP	AH,((":") and 0FFh)
	JNE	@GIODSK@_GOTNAM  ;branch if not "<drive>:"
	MOV	SI,@FILNA2+2  ;[SI] points to buffer for building filename
	MOV	word [@FILNA2],AX  ;Store <drive>: in filename buffer
	JMP	@GIODSK@_ALFILS  ;append "*.*" to name
@GIODSK@_NOARG:
	MOV	SI,@FILNA2  ;[SI] points to buffer for building filename
	XOR	CX,CX
@GIODSK@_ALFILS:
	MOV	word [SI+0],(256*".")+"*"
	MOV	word [SI+2],"*"
	ADD	CX,3  ;[CX] = number of bytes in filename
	MOV	SI,@FILNA2  ;[SI] points to filename
@GIODSK@_GOTNAM:
	CALL	@GIODSK@_FILFCB  ;FILNAM=un-opened FCB for filename
	MOV	DX,@FILNA2  ;tells OS to put FCB for matching directory
	@CALLOS	@C_BUFF  ; entries in FILNA2
	MOV	DX,DI  ;[DX] = search FCB (FILNAM)
	@CALLOS	@C_SEAR  ;Search 1st
	INC	AL
	JNZ	@GIODSK@_FILNXT  ;Brif found
	JMP	@DERFNF  ; else complain
@GIODSK@_FILNXT:
	CALL	@POLKEY  ;Allow CTL-C, CTL-S between every filename
	MOV	SI,@FILNA2+1  ;Point at name
	MOV	CX,@FNAML  ;Characters in name
@GIODSK@_MORNAM:
	CLD  ;Set Post-Increment mode
	LODSB  ;Get character
	CALL	@OUTDO  ;Output it
	CMP	CX,4
	JNE	@GIODSK@_NOTEXT  ;Not at extension break
	MOV	AL,byte [SI+0]  ;Get 1st char of extension
	CMP	AL,((" ") and 0FFh)
	JE	@GIODSK@_PRISPA  ;Blank extension - print space
	MOV	AL,((".") and 0FFh)  ;Print .
@GIODSK@_PRISPA:
	CALL	@OUTDO  ;Print blank or dot
@GIODSK@_NOTEXT:
	LOOP	@GIODSK@_MORNAM  ;Loop until 11 characters
; EXTRN	PTRWID:NEAR
	CALL	@PTRWID  ;[AH]=line width
	MOV	CH,AH  ;[CH]=line width
; EXTRN	PTRGPS:NEAR
	CALL	@PTRGPS  ;[AL]=current column
	ADD	AL,((14) and 0FFh)  ;Position after next file name
	CMP	AL,CH
	JAE	@GIODSK@_NWFILN  ;Force CR/LF
	MOV	AL,((" ") and 0FFh)
	CALL	@OUTDO
	JMP	@GIODSK@_NEXTFL
@GIODSK@_NWFILN:
	CALL	@CRDO  ;Type CR/LF
@GIODSK@_NEXTFL:
	MOV	DX,@FILNAM  ;[DX] points to search template
	XOR	AL,AL
	@CALLOS	@C_SEAR+1  ;Search next
	CMP	AL,((255) and 0FFh)
	JNE	@GIODSK@_FILNXT  ;branch if still more
; EXTRN	CRDONZ:NEAR
	JMP	@CRDONZ  ;carriage return if not in column 0

;KILL filename
; Entry - [BX] = text pointer
; Exit -  [BX] = text pointer

@KILL:
	CALL	@GIODSK@_NAMFIL  ;[SI] points to 1st byte of filename
;[CX] = number of bytes in filename
	CALL	@GIODSK@_FILFCB  ;FILNAM=un-opened FCB for filename
	PUSH	BX  ;save text pointer
	MOV	DX,@FILNAM
	PUSH	DX  ;Save FCB pointer
	@CALLOS	@C_OPEN  ;Open file
	INC	AL
	JNZ	@GIODSK@_KILL2  ;Brif file found
	JMP	@DERFNF  ;File not found
@GIODSK@_KILL2:	POP	DX  ;DX points to FCB
	PUSH	DX
	@CALLOS	@C_CLOS  ;Close file
	MOV	SI,@FILNAM-@F_FCB  ;Pretend we are FDB
	CALL	@GIODSK@_CHKFOP  ;Check for conflict with open files
;jumps to error if file is now opened
	POP	DX  ;DX points to FCB
	@CALLOS	@C_DELE  ;Delete file
	POP	BX  ;text pointer
	RET

;NAME oldname AS newname
; Entry - [BX] = text pointer
; Exit  - [BX] = text pointer

@NAME:
	CALL	@GIODSK@_NAMFIL  ;[SI] points to 1st byte of old filename
;[CX] = number of bytes in filename
	PUSH	BX  ;save text pointer
	CALL	@GIODSK@_FILFCB  ;FILNAM=un-opened FCB for old filename
	MOV	DX,@FILNA2  ;tells OS to put FCB for matching directory
	@CALLOS	@C_BUFF  ; entries in FILNA2
	MOV	DX,DI  ;[DX] = search FCB (FILNAM)
	@CALLOS	@C_SEAR  ;Search 1st
	INC	AL
	JZ	@GIODSK@_NA_FNF  ;File not found
	MOV	SI,@FILNAM-@F_FCB  ;Pretend we are FDB
	CALL	@GIODSK@_CHKFOP  ;Check for conflict with open files
;jumps to error if file is now opened
	MOV	SI,@FILNAM  ;save old filename in FILNA2
	MOV	DI,@FILNA2
	MOV	CX,@FNAML+1  ;+1 for drive
	CLD  ;Set Post-Increment mode
 REP	MOVSB  ;Move drive,name,ext from FILNAM to FILNA2
	POP	BX  ;text pointer
	CALL	@SYNCHR
	DB	"A"  ; must see "AS"
	CALL	@SYNCHR
	DB	"S"
	CALL	@GIODSK@_NAMFIL  ;[SI] points to 1st byte of newfilename
;[CX] = number of bytes in filename
	PUSH	BX  ;text pointer
	CALL	@GIODSK@_FILFCB  ;FILNAM=un-opened FCB for new filename
	MOV	AL,byte [@FILNAM]  ;[AL]=drive for New filename
	OR	AL,AL  ;test drive id of New filename
	JZ	@GIODSK@_SAMDRV  ;branch if default drive
	CMP	AL,byte [@FILNA2]  ;Compare with drive of original name
	JZ	@GIODSK@_SAMDRV  ;branch if both drives are the same
; EXTRN	DERRAD:NEAR
	JMP	@DERRAD  ;Rename Across Disks Error
@GIODSK@_SAMDRV:
	MOV	SI,@FILNAM+1  ;move new filename,ext to FILNA2+17
	MOV	DI,@FILNA2+17  ;[DI] = dest for new file name
	MOV	CX,@FNAML  ;No drive code
	CLD  ;Set Post-Increment mode
 REP	MOVSB  ;Move name
	MOV	DX,@FILNA2  ;Point to FCB which contains both filenames
	@CALLOS	@C_RENA  ;Rename file
	INC	AL  ;error if attempted to create file which
	JE	@GIODSK@_NA_FAE  ; already existed
	POP	BX  ;text pointer
	RET

@GIODSK@_NA_FNF:	JMP	@DERFNF  ;file not found
@GIODSK@_NA_FAE:	JMP	@DERFAE  ;file already exists

;NAMFIL - Scan a file name for NAME, KILL, or FILES command
; Entry - [BX] = text pointer
; Exit  - [BX] = text pointer
;         [SI] points to 1st byte of filename
;         [CX] = number of bytes in filename string
; Uses  - [AX]

@GIODSK@_NAMFIL:
	CALL	@FRMEVL  ;Evaluate string
	PUSH	BX  ;save text pointer
	CALL	@FRESTR  ;Free the temp
	MOV	CL,byte [BX+0]
	XOR	CH,CH  ;[CX] = String len
	JCXZ	@GIODSK@_ER_NMF  ;If null then bad name
	MOV	SI,word [BX+1]  ;[SI] = Filename string
	POP	BX
	RET

@GIODSK@_ER_NMF:	JMP	@DERNMF  ;"Bad file name"

;FILFCB - Given filename "d:name:ext", create an un-opened FCB
; Entry - [SI] = points 1st byte of filename
;         [CX] = number of bytes in filename string
; Exit  - FILNAM is un-opened FCB equivalent for filename
;         [DI] points to 1st byte of FCB FILNAM
;         [AL] = FF if illegal drive or filename,
;                 1 if filename contained any "?" or "*" characters
;                 0 otherwise
; Uses  - BUF

@GIODSK@_FILFCB:
	MOV	DI,@BUF  ;move filename to BUF buffer
	CLD  ;Set Post-Increment mode

@GIODSK@_STRTNM:	XOR	AH,AH  ;Count of chars in name portion:=0.
@GIODSK@_NAMORE:	OR	CX,CX  ;Anything left?
	JE	@GIODSK@_TRMSTR  ;No, go terminate the string in BUF.
	MOV	AL,byte [SI+0]  ;Yes, AL:=get next char of string.
	MOVSB  ;Copy it to BUF.
	DEC	CX  ;Decrement the length.
	CMP	AL,((":") and 0FFh)  ;Colon indicating we were looking at a
;device name?
	JE	@GIODSK@_STRTNM  ;Yes, restart the count since we are now
;looking at the filename.
	CMP	AL,((".") and 0FFh)  ;No, dot indicating start of extension?
	JE	@GIODSK@_FINNAM  ;Yes, end of name.
	CMP	AL,(("*") and 0FFh)  ;The asterisk wild card also terminates the
	JE	@GIODSK@_FINNAM  ;name for our purposes.
	CMP	AH,((8) and 0FFh)  ;Have we already seen 8 name characters?
	JAE	@GIODSK@_LNGNAM  ;Yes, the excess chars become the extension.
	INC	AH  ;No, increment the name character count.
	JMP	@GIODSK@_NAMORE  ;Go look at the next char.

@GIODSK@_LNGNAM:	MOV	byte [DI-1],((".") and 0FFh)  ;Put in the dot so the extra chars look
	MOV	byte [DI+0],AL  ;like an extension.
	INC	DI
@GIODSK@_FINNAM:	OR	CX,CX  ;Anything left?
	JE	@GIODSK@_TRMSTR  ;No, terminate the string.  (Avoid REP with
;a zero count.)
 REP	MOVSB  ;Copy the remainder of the string to BUF.
@GIODSK@_TRMSTR:	MOV	byte [DI+0],((0) and 0FFh)  ;store string terminator
	MOV	SI,@BUF  ;parse 0 terminated filename in BUF
	MOV	DI,@FILNAM  ; filling FDB FILNAM
	XOR	AL,AL  ; don't skip any separators
	@CALLOS	@C_PARS
	OR	AL,AL  ;test for legal filename
	JNE	@GIODSK@_FLFCBX  ;branch if error or non-empty filename
	CMP	byte [@FILNAM+1],((" ") and 0FFh)  ;test 1st byte of filename
	JNE	@GIODSK@_FLFCBX  ;branch if non-empty filename
	DEC	AL  ;[AL] = FF (illegal filename)
@GIODSK@_FLFCBX:
	RET

; SUBTTL  RESET and SYSTEM statements

; Entry/exit:   [BX] = text pointer

; PUBLIC	RESET
; EXTRN	CLSALL:NEAR,TKEYOF:NEAR

@RESET:
	JNZ	@GIODSK@_RESETX  ;if wasn't EOS
	PUSH	BX  ;text pointer
	CALL	@CLSALL  ;Close all files
	@CALLOS	@C_GDRV  ;Get drive number
	PUSH	AX
	@CALLOS	@C_REST  ;Restore
	POP	AX
	MOV	DL,AL
	@CALLOS	@C_SDRV  ;Set drive number
	POP	BX  ;text pointer
@GIODSK@_RESETX:
	RET

; SYSTEM - Exit BASIC

; PUBLIC	SYSTEM,SYSTME

; EXTRN	GWTERM:NEAR

@SYSTEM:
	JNZ	@GIODSK@_RESETX  ;If wasn't EOS
	CALL	@CLSALL  ;Close all files
@SYSTME:
; EXTRN	GIOTRM:NEAR
	CALL	@GIOTRM  ;call device termination routines
	CALL	@GWTERM  ;Do OEM specific termination processing
end if
; EXTRN	CPMEXT:WORD
if @GW_PASS = 1
;translator can't handle JMPI ,adr yet
	PUSH	word [@CPMEXT+2]  ;put segment adr on stack
	PUSH	word [@CPMEXT]  ;put offset on stack
; dumy  PROC    FAR
	RET  ;intra-segment return
; dumy  ENDP

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
