; [ This translation created 10-Feb-83 by Version 4.3 ]

if @GW_PASS = 1

include 'OEM.H'

; TITLE   GIOCOM - Communications Machine Independent Device Driver Code

; COMMENT	*

; --------- --- ---- -- --------- -----------
; COPYRIGHT (C) 1982 BY MICROSOFT CORPORATION
; --------- --- ---- -- --------- -----------

;         by Tom Corbett  Microsoft Corp.
;         *

include 'GIO86U'

@CPM86=0
@GIOCOM@_COMPAQ=0  ;Include IBM 1.0/1.1 Bugs for compatibility

include 'MSDOSU'

; PUBLIC	COMDSP,COMINI,COMTRM
; EXTRN	DERBFM:NEAR,INIFDB:NEAR,UPDPOS:NEAR,$_COM1:NEAR,BCHRSI:NEAR
; EXTRN	MAKINT:NEAR
; EXTRN	DEVBIN:NEAR,DEVBOT:NEAR

;Communications Dispatch Table

@COMDSP:
	DW	(@GIOCOM@_COMEOF)  ;test EOF for file opened to this device
	DW	(@GIOCOM@_COMLOC)  ;LOC
	DW	(@GIOCOM@_COMLOF)  ;LOF
	DW	(@GIOCOM@_COMCLS)  ;perform special CLOSE functions for this device
	DW	(@GIOCOM@_COMSWD)  ;set device width
	DW	(@GIOCOM@_COMRND)  ;GET/PUT random record from/to this device
	DW	(@GIOCOM@_COMOPN)  ;perform special OPEN functions for this device
	DW	(@GIOCOM@_COMSIN)  ;input 1 byte from file opened on this device
	DW	(@GIOCOM@_COMSOT)  ;output 1 byte to file opened on this device
	DW	(@GIOCOM@_COMGPS)  ;POS
	DW	(@GIOCOM@_COMGWD)  ;get device width
	DW	(@GIOCOM@_COMSCW)  ;set device comma width
	DW	(@GIOCOM@_COMGCW)  ;get device comma Width
	DW	(@DEVBIN)  ;block input from file opened on this device
	DW	(@DEVBOT)  ;block output to file opened on this device
; SUBTTL Communications Generalized I/O Routines

; RS232 Device Control Block Definition:

;   mneumonic offset    use
;   --------- ------    ---------------------------------------
	@GIOCOM@__DEVID=0  ;RS232 Channel ID (0..n)
	@GIOCOM@__BAUDR=1  ;baud rate (least significant byte 1st)
;(0=disable device, 9600=9600 baud etc.)
	@GIOCOM@__BYTSZ=3  ;bits per byte (4..8)
	@GIOCOM@__PARIT=4  ;parity (0..4)=...(NONE, ODD, EVEN, MARK, SPACE)
	@GIOCOM@__STOPB=5  ;(0..2)= (1, 1.5, 2) stop bits
	@GIOCOM@__RLSTO=6  ;RLSD (rec. line signal detect) timeout
	@GIOCOM@__CTSTO=8  ;CTS (clear to send) timeout
	@GIOCOM@__DSRTO=10  ;DSR (data set ready) timeout
;All timeout values are in milliseconds.
;0=infinite, LSB is always 1st.
;Support of Timeout Flags by BIOS is
;optional.
	@GIOCOM@__CMFLG=12  ;Boolean attributes mask for this device
	@GIOCOM@__CMBIN=1  ;(0/1)=ASCII/BINARY (ASC option not in filename)
	@GIOCOM@__CMRTS=2  ;non-zero=Suppress Request-To-Send (RS option)
	@GIOCOM@__CMCOD=16  ;non-zero=user specified ASC or BIN in filename
	@GIOCOM@__CMCTS=32  ;non-zero=CTS parm not defaulted
	@GIOCOM@__CMCLF=64  ;non-zero=Send line feed after CR
	@GIOCOM@__CMCRF=128  ;non-zero=last char sent was Carriage Return

;If COM filename contains "ASC", .CMBIN=0, .CMCOD=1
;If COM filename contains "BIN", .CMBIN=1, .CMCOD=1
;If COM filename contains neither "ASC" nor "BIN", .CMBIN=1, .CMCOD=0
;If COM filename contains both "ASC" and "BIN", Illegal Filename occurs

;COM DCB Entries which are only of interest to BASIC (Not OEM routines)

;*********************************************
;*** .CMPOS must immediately follow .CMWID ***
;*********************************************
	@GIOCOM@__CMWID=13  ;device width (columns per line)
	@GIOCOM@__CMPOS=14  ;current column device is in **must follow .CMWID**
	@GIOCOM@__CMFDB=15  ;points to FDB for file (0=not opened)

	@GIOCOM@_CDCBSZ=24  ;bytes per COM Device Control Block (room for growth)

; EXTRN	INICOM:NEAR,RECCOM:NEAR,SNDCOM:NEAR,STACOM:NEAR,TRMCOM:NEAR
; EXTRN	POLKEY:NEAR,DERIFN:NEAR
end if
; EXTRN	CM1DCB:WORD
if @GW_PASS = 1

;COMINI - called during BASIC initialization
; Entry - DI = -2*device id

; PUBLIC	COMINI,COMTRM
@COMINI:	PUSH	DI
	CALL	@GIOCOM@_GCMDCB  ;DI points to device control block
	MOV	byte [@GIOCOM@__CMWID+DI],((255) and 0FFh)  ;default is infinite width
	MOV	word [@GIOCOM@__CMFDB+DI],0  ;mark this device as available for open
	POP	DI
@COMTRM:  ;Com Termination Routine (End-of-BASIC)
	RET  ; No action required

;POLCOM is called by CHKINT at beginning of every BASIC statement (NEWSTT).
; For each COM device which is opened to a device, it calls COMTRP if that
; device has input data waiting.
; Exit - AX, BX, CX, DX can be used (restored by CHKINT).
;        All other registers are preserved.

; PUBLIC	POLCOM
; EXTRN	COMTRP:NEAR

@POLCOM:	PUSH	DI
	PUSH	SI
	MOV	DI,@CM1DCB  ;DI points to device control block 1
	MOV	DX,@NMCOMT  ;[DH]=COM unit#, [DL]=number of COM units
@GIOCOM@_POLCML:	CALL	@GIOCOM@_POLCM1  ;test unit 1 for trap
	ADD	DI,@GIOCOM@_CDCBSZ  ;DI points to next device control block
	INC	DH  ;Bump unit id
	DEC	DL  ;Decrement unit counter
	JNZ	@GIOCOM@_POLCML  ;branch if any more to test
	POP	SI
	POP	DI
	RET

;POLCM1 checks 1 COM device to see if input is waiting, if so, it calls COMTRP

@GIOCOM@_POLCM1:	MOV	SI,word [@GIOCOM@__CMFDB+DI]  ;SI points to FDB (if device is opened)
	OR	SI,SI
	JZ	@GIOCOM@_PLCM1X  ;return if device not opened
	TEST	byte [@F_FLGS+SI],((@FL_BKC) and 0FFh)
	JNE	@GIOCOM@_POLTRP  ;branch if backup-char present
	MOV	AH,DH  ;[AH]=Unit#
	PUSH	DX  ;save Unit#
	CALL	@GIOCOM@_GCOMSZ  ;[DX]=number of bytes queued
	OR	DX,DX  ;test it
	POP	DX  ;restore Unit#
@GIOCOM@_POLTRP:	MOV	AL,DH  ;[AL]=trap id (0..n)
	JE	@GIOCOM@_PLCM1X  ;branch if no com data queued
	CALL	@COMTRP  ;so ON-COM service routine will be called
@GIOCOM@_PLCM1X:	RET

;Get COM bytes in queue
;       On entry: AH = unit number
;       On return: DX=bytes in queue
;                  CX=free bytes in queue
;                   Does error processing if gets error from COM channel
@GIOCOM@_GCOMSZ:	PUSH	AX
	CALL	@STACOM
	OR	AH,AH  ;Check status here even though
;CKCMER does for speed.
	JNZ	@GIOCOM@_CKCMER  ;branch if got error from COM
	POP	AX
@GIOCOM@_RET14:	RET

; Check for COM I/O error and output COM Error Message if error occured.
; Entry - [AH] = non-zero if error occured

; EXTRN	STROUT:NEAR,OUTDO:NEAR,ERROR:NEAR
; EXTRN	ERRCBO:NEAR,ERRDPE:NEAR,ERRDTO:NEAR,ERRDIO:NEAR
@GIOCOM@_CKCMER:
	OR	AH,AH
	JE	@GIOCOM@_RET14  ;branch if no COM I/O error detected
	MOV	AL,AH
	XOR	AH,AH  ;[AX]=error code 1..n
	DEC	AX  ;[AX]=error code 0..n
	MOV	DI,@GIOCOM@_CMERRT
	ADD	DI,AX  ;[DI] points to BASIC Error code
	MOV	DL,byte [cs:DI+0]
	CMP	AL,((5) and 0FFh)
	JB	@GIOCOM@_ERROR1  ;branch if legal error code
	MOV	DL,((@ERRDIO) and 0FFh)  ;map all other error codes to I/O error
@GIOCOM@_ERROR1:	JMP	@ERROR

@GIOCOM@_CMERRT:	DB	@ERRCBO  ;buffer overflow error
	DB	@ERRDPE  ;parity error
	DB	@ERRDTO  ;device timeout
	DB	@ERRDTO  ;device timeout
	DB	@ERRDTO  ;device timeout
; SUBTTL  COM OPEN

;    Syntax:   OPEN "COMn: [speed] [,parity] [,data] [,stop]
;              [,RS]  [,CS[n]]  [,DS[n]]  [,CD[n]] [,LF] [,BIN] [,ASC]" AS
;              [#]filenum

;                   SPEED     baud rate in bits per second
;                   PARITY    N, E, O (none, even, odd)
;                   DATA      5,6,7,8 bits per byte
;                   STOP      1, 1.5, 2 stop bits.
;                             Default for baud greater than 110 is 1.
;                             Default for 110 baud or lower & 5 data bits is 1.5
;                             Default for 110 baud or lower & 6-8 data bits is 2
;                   RS        Suppress RTS (Request To Send).
;                   CS[n]     Controls CTS (Clear To Send).
;                   DS[n]     Controls DSR (Data Set Ready).
;                   CD[n]     Controls CD (Carrier Detect).
;                             This is also referred to as RLSD
;                             (Received Line Signal Detect).
;                   LF        Send a Line-Feed character (X'0A')
;                             following a Carriage Return (X'0D').
;                   BIN       Open COM file in BINARY mode
;                   ASC       Open COM file in ASCII mode

;              The RTS (Request To Send)  line  is turned on
;              when you execute  an  OPEN  "COM... statement
;              unless you include the RS option.

;              If CD is omitted, it defaults to CS0.
;              If DS is omitted, it defaults to DS1000.
;              If CS is omitted, it defaults to CS1000.
;              If RS is specified and CS is omitted, then
;              CS defaults to 0.

;              Normally I/O  statements  to  a communication
;              file will fail if the CTS (Clear To Send)  or
;              DSR (Data Set Ready) lines  are  not  cabled.
;              The CS and DS options allow you to avoid this
;              problem by ignoring these  lines.  If the [n]
;              argument is included, it specifies the number
;              of milliseconds to wait for the signal before
;              returning a "Device Timeout"  error.

;              If the argument [n] in the CS, DS, and CD options
;              is omitted, or equal to 0, then that line's status
;              is not checked at all.

;              Note:   The  speed,  parity,  data, and  stop
;              parameters  are  positional, but RS, CS,  DS,
;              and CD may appear in any order after STOP.

;              The LF parameter is intended for  those using
;              communication files as a means of printing to
;              a serial line  printer.  When included in the
;              parameter list, LF will  cause  a  Line  Feed
;              character to be sent after a  Carriage return
;              character.

;COMOPN - perform any device dependent open functions.
; Entry - [AL]=  device id
;                0 if default device,
;                1..n for Disk A:, B:, ...
;                -1..-n for non-disk devices
;         [BX] = file number (0..n)
;         [CX] = random record size if [FILMOD] = random
;                (if [CX] = 0, use default record size)
;         [DI] = device offset (2=COMD, 4=SCRN, etc.)
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
;         All registers are used.

; EXTRN	DERFAO:NEAR

@GIOCOM@_COMOPN:	MOV	AH,BL  ;[AH]=file number
	PUSH	AX  ;save file number, device id
	PUSH	CX  ;save variable record len (if random)
	CALL	@GIOCOM@_GCMDCB  ;AX = 0, 1, ... for COM1, COM2, ...
;DI points to Device Control Block
	CMP	word [@GIOCOM@__CMFDB+DI],0  ;see if device is opened to another file
	JE	@GIOCOM@_STUNIT  ;not opened to another file
@GIOCOM@_ERFAO1:	JMP	@DERFAO  ;File Already Opened
@GIOCOM@_STUNIT:	MOV	byte [@GIOCOM@__DEVID+DI],AL  ;set unit field of Device Control Block
	CALL	@GIOCOM@_PCOMOP  ;parse options (fill in DCB fields)
	TEST	byte [@GIOCOM@__CMFLG+DI],((@GIOCOM@__CMRTS) and 0FFh)
	JE	@GIOCOM@_NORTSO  ;branch if RS option not specified
	TEST	byte [@GIOCOM@__CMFLG+DI],((@GIOCOM@__CMCTS) and 0FFh)
	JNE	@GIOCOM@_NORTSO  ;branch if CTS parm specified
	MOV	word [@GIOCOM@__CTSTO+DI],0  ;else default CTS to 0 seconds
@GIOCOM@_NORTSO:
	CMP	byte [@GIOCOM@__STOPB+DI],((255) and 0FFh)
	JNE	@GIOCOM@_STPNDF  ;brif stop not defaulted
	INC	byte [@GIOCOM@__STOPB+DI]  ;.STOPB=0 (1 stop bit)
	CMP	word [@GIOCOM@__BAUDR+DI],110
	JA	@GIOCOM@_STPNDF  ;brif baud rate exceeds 110 (1 stop)
	INC	byte [@GIOCOM@__STOPB+DI]  ;.STOPB=1 (1.5 stop bit)
	CMP	byte [@GIOCOM@__BYTSZ+DI],((5) and 0FFh)
	JBE	@GIOCOM@_STPNDF  ;brif 4 or 5 bits per byte (1.5 stop)
	INC	byte [@GIOCOM@__STOPB+DI]  ;110 baud & 6,7,8 data bits=2 stop bits
@GIOCOM@_STPNDF:	MOV	byte [@GIOCOM@__CMPOS+DI],((0) and 0FFh)  ;reset column to 0
	MOV	BX,DI  ;BX points to DCB
	CALL	@INICOM  ;call machine dependent OPEN routine
;destroys FLAGS, AX..DX
	INC	AH
	JE	@GIOCOM@_ERIFN1  ;branch if Illegal Filename
	DEC	AH
	CALL	@GIOCOM@_CKCMER  ;see if INICOM didn't like options
	POP	CX  ;[CX]=record length
	CMP	byte [@FILMOD],((@MD_RND) and 0FFh)
	JNZ	@GIOCOM@_NOTRND  ;branch if not OPEN RANDOM
	OR	CX,CX
	JNZ	@GIOCOM@_NOTDEF  ;branch if user requested Record-Size
	MOV	CX,@DATPSC  ;default to 128 (same as disk)
@GIOCOM@_NOTDEF:	ADD	CX,@FD_DAT-@FDBSIZ  ;add standard Disk FDB requirements
@GIOCOM@_NOTRND:	POP	AX  ;[AL]=device id
	MOV	DX,word [@GIOCOM@__CMWID+DI]  ;[DL]=width, [DH]=init position
;from Device Control Block
	MOV	BL,AH
	MOV	BH,((0) and 0FFh)  ;[BX]=file number
	MOV	AH,((255) and 0FFh)  ;allow all file modes
	PUSH	CX  ;save Random Record Size
	CALL	@INIFDB  ;Initialize FDB
	POP	CX
	OR	CX,CX
	JZ	@GIOCOM@_NTRND  ;branch if mode is not random
	SUB	CX,@FD_DAT-@FDBSIZ  ;CX=record size requested by user
	MOV	word [@FD_SIZ+SI],CX  ;save in FDB
@GIOCOM@_NTRND:	MOV	word [@GIOCOM@__CMFDB+DI],SI  ;save FDB pointer in DCB
	TEST	byte [@GIOCOM@__CMFLG+DI],((@GIOCOM@__CMBIN) and 0FFh)
	JZ	@GIOCOM@_CMOPNX  ;branch if user wants ASCII mode
; EXTRN	SCDBIN:NEAR
	CALL	@SCDBIN  ;set CODE atr for file PTRFIL to BINARY
@GIOCOM@_CMOPNX:
@GIOCOM@_RET21:	RET

@GIOCOM@_ERIFN1:	JMP	@DERIFN  ;Illegal File Name

;Parse COM Open Options "baud, data, parity, stop"

end if
; EXTRN	FILOPT:WORD
if @GW_PASS = 1
@GIOCOM@_PCOMOP:	MOV	word [@GIOCOM@__BAUDR+DI],300  ;default baud rate = 300
	MOV	byte [@GIOCOM@__STOPB+DI],((255) and 0FFh)  ;mark STOP bits as Default
	MOV	byte [@GIOCOM@__BYTSZ+DI],((7) and 0FFh)  ;default physical byte size = 7
	MOV	byte [@GIOCOM@__PARIT+DI],((2) and 0FFh)  ;default parity = Even
	MOV	byte [@GIOCOM@__CMFLG+DI],((@GIOCOM@__CMBIN) and 0FFh)  ;default BINARY, CRLF = off
	MOV	word [@GIOCOM@__RLSTO+DI],0  ;default Carrier Detect timeout=0
	MOV	word [@GIOCOM@__CTSTO+DI],1000  ;default Clear-To-Send timeout=1 sec
	MOV	word [@GIOCOM@__DSRTO+DI],1000  ;default Data Set Ready timeout=1 sec
	MOV	SI,@FILOPT  ;SI points to options string
	CALL	@GIOCOM@_GETPR0  ;Get 1st char in Filename
	JZ	@GIOCOM@_RET21  ;Brif EOS
	JB	@GIOCOM@_COMOP3  ;Brif default Baud (Saw ",")
	DEC	SI  ;Adjust for GETPRM
	CALL	@GIOCOM@_VALGET  ;Get Rate in [DX]
	MOV	word [@GIOCOM@__BAUDR+DI],DX  ;save baud rate code
	CALL	@GIOCOM@_GETPRM
	JZ	@GIOCOM@_RET21  ;branch if EOS
@GIOCOM@_COMOP3:
	CALL	@GIOCOM@_SYNPRM  ;"," must follow or Illegal File Name
	MOV	CH,((2) and 0FFh)  ;Default parity=Even(2)
	JB	@GIOCOM@_DFTPTY  ;Brif Default (saw ",")
	XOR	CH,CH  ;Map parity parameter to internal code
	CMP	AL,(("N") and 0FFh)
	JZ	@GIOCOM@_GOTPTY  ;Map NONE to 0
	INC	CH
	CMP	AL,(("O") and 0FFh)
	JZ	@GIOCOM@_GOTPTY  ;Map ODD to 1
	INC	CH
	CMP	AL,(("E") and 0FFh)
	JZ	@GIOCOM@_GOTPTY  ;Map EVEN to 2
	INC	CH
	CMP	AL,(("M") and 0FFh)
	JZ	@GIOCOM@_GOTPTY  ;Map MARK to 3
	INC	CH
	CMP	AL,(("S") and 0FFh)
	JZ	@GIOCOM@_GOTPTY  ;Map SPACE to 4
@GIOCOM@_ERIFN2:
	JMP	@DERIFN  ;Complain ("Illegal File Name")
@GIOCOM@_DFTPTY:
	DEC	SI  ;Adjust for GETPRM
@GIOCOM@_GOTPTY:
	MOV	byte [@GIOCOM@__PARIT+DI],CH  ;save parity in DCB
	CALL	@GIOCOM@_GETPRM  ;Scan off end of Parity field
	JZ	@GIOCOM@_COMOP5  ;Brif EOS, Default Data/Stop bits
	CALL	@GIOCOM@_SYNPRM  ; else Data bits must follow
	JB	@GIOCOM@_COMOP4  ;Brif saw "," try for Stop bits
	SUB	AL,(("0") and 0FFh)  ;map ("4".."8") to (4..8)
	CMP	AL,((4) and 0FFh)
	JB	@GIOCOM@_ERIFN2  ; Error if less than "4"
	CMP	AL,((9) and 0FFh)
	JNB	@GIOCOM@_ERIFN2  ; or greater than "8"
	MOV	byte [@GIOCOM@__BYTSZ+DI],AL  ;save Data bits
	CALL	@GIOCOM@_GETPRM  ; Look for no. of stop bits or EOS
	JZ	@GIOCOM@_COMOP5  ;Brif EOS
@GIOCOM@_COMOP4:
	CALL	@GIOCOM@_SYNPRM  ;Stop bits must follow
	JB	@GIOCOM@_COMOP5  ;Brif saw "," Default Stop bits
	SUB	AL,(("1") and 0FFh)  ;Strip ASCII bias ("1", "2")=(0,1)
	CMP	AL,((2) and 0FFh)  ;Must be "1" or "2"
	JNB	@GIOCOM@_ERIFN2  ; else error
	ADD	AL,AL  ;map ("1","2") to (0,2)
	MOV	byte [@GIOCOM@__STOPB+DI],AL  ;set STOP bits field in DCB
	JNZ	@GIOCOM@_LPARM  ;branch if "2"
	CALL	@GIOCOM@_GETPRM  ;[AL]=EOS, "," or "."
	JZ	@GIOCOM@_RET24  ;return if End-Of-String
	CMP	AL,((".") and 0FFh)
	JNZ	@GIOCOM@_LPARM2  ;it had better be a comma
	CALL	@GIOCOM@_GETPRM
	CMP	AL,(("5") and 0FFh)
	JNZ	@GIOCOM@_ERIFN2  ;illegal filename error if not 1.5
	INC	byte [@GIOCOM@__STOPB+DI]  ;map ("1", "1.5", "2") to (0,1,2)
	INC	SI
@GIOCOM@_COMOP5:
	DEC	SI  ;adjust for GETPRM

;This routine parses the position independent parameters RTS, DSR, ...

@GIOCOM@_LPARM:
	CALL	@GIOCOM@_GETPRM  ;Get parm, EOS, or ","
	JZ	@GIOCOM@_RET24  ;Brif no more parms
@GIOCOM@_LPARM2:
	CALL	@GIOCOM@_SYNPRM  ;Check "," then get parm
	CMP	AL,(("R") and 0FFh)  ;RS?
	JNZ	@GIOCOM@_LPARDS  ;no, try DS/CS/CD/LF/BIN
	CALL	@GIOCOM@_LPTRYS  ; S?
	JNZ	@GIOCOM@_PARIFN  ;no, error
	OR	byte [@GIOCOM@__CMFLG+DI],((@GIOCOM@__CMRTS) and 0FFh)  ;set RTS bit
	JMP	@GIOCOM@_LPARM  ;get next parm
@GIOCOM@_LPARDS:
	CMP	AL,(("D") and 0FFh)  ;DS?
	JNZ	@GIOCOM@_LPARCD  ;No, try CS/CD/LF/BIN
	CALL	@GIOCOM@_LPTRYS  ; S?
	JNZ	@GIOCOM@_PARIFN  ;no, error
	CALL	@GIOCOM@_VALGET  ;[DX] = Timeout
	MOV	word [@GIOCOM@__DSRTO+DI],DX  ;set DSR timeout
	JMP	@GIOCOM@_LPARM  ;get next parm

@GIOCOM@_LPARCD:
	CMP	AL,(("C") and 0FFh)  ;CS/CD?
	JNZ	@GIOCOM@_LPARLF  ;no, try LF/BIN
	CALL	@GIOCOM@_LPTRYS  ; S?
	JZ	@GIOCOM@_LPARCS  ;Brif CS
	CMP	AL,(("D") and 0FFh)  ; D?
	JNZ	@GIOCOM@_PARIFN  ;no, error
	CALL	@GIOCOM@_VALGET  ;[DX] = Timeout
	MOV	word [@GIOCOM@__RLSTO+DI],DX  ;set RLSD timeout
	JMP	@GIOCOM@_LPARM  ;get next parm
@GIOCOM@_LPARLF:
	CMP	AL,(("L") and 0FFh)  ;LF?
	JNZ	@GIOCOM@_LPRBIN  ;no, try BINary
	CALL	@GIOCOM@_LPTRYS
	CMP	AL,(("F") and 0FFh)  ;"F" must follow
	JNZ	@GIOCOM@_PARIFN  ;no, error
	OR	byte [@GIOCOM@__CMFLG+DI],((@GIOCOM@__CMCLF) and 0FFh)  ;set send LF after CR flag
	JMP	@GIOCOM@_LPARM  ;get next parm
@GIOCOM@_LPARCS:
	CALL	@GIOCOM@_VALGET  ;[DX] = Timeout
	MOV	word [@GIOCOM@__CTSTO+DI],DX  ;set CTS timeout
	OR	byte [@GIOCOM@__CMFLG+DI],((@GIOCOM@__CMCTS) and 0FFh)  ;indicates CTS not defaulted
	JMP	@GIOCOM@_LPARM  ;get next parm
@GIOCOM@_PARIFN:
	JMP	@DERIFN  ;Illegal File Name error

@GIOCOM@_LPTRYS:
	CALL	@GIOCOM@_GETPRM
	CMP	AL,(("S") and 0FFh)  ;set cond codes for S (Frequent letter)
@GIOCOM@_RET24:	RET

@GIOCOM@_LPRBIN:	CMP	AL,(("B") and 0FFh)  ;BIN?
	JNZ	@GIOCOM@_LPRASC  ;Branch if not
	CALL	@GIOCOM@_LPTRYS
	CMP	AL,(("I") and 0FFh)  ; I?
	JNZ	@GIOCOM@_PARIFN  ;no, error
	CALL	@GIOCOM@_LPTRYS
	CMP	AL,(("N") and 0FFh)  ; N?
	JNZ	@GIOCOM@_PARIFN  ;no, error
;;; Binary mode is the default mode, next line for Documentation Purposes
;;;     ORBI    .CMFLG(.DI),.CMBIN      ;set binary mode
	JMP	@GIOCOM@_TSTCOD  ;get next parameter

@GIOCOM@_LPRASC:	CMP	AL,(("A") and 0FFh)  ;ASC?
	JNZ	@GIOCOM@_PARIFN  ;Illegal filename if not
	CALL	@GIOCOM@_LPTRYS
	CMP	AL,(("S") and 0FFh)  ; S?
	JNZ	@GIOCOM@_PARIFN  ;no, error
	CALL	@GIOCOM@_LPTRYS
	CMP	AL,(("C") and 0FFh)  ; C?
	JNZ	@GIOCOM@_PARIFN  ;no, error
	AND	byte [@GIOCOM@__CMFLG+DI],((255-@GIOCOM@__CMBIN) and 0FFh)  ;reset binary mode
@GIOCOM@_TSTCOD:	TEST	byte [@GIOCOM@__CMFLG+DI],((@GIOCOM@__CMCOD) and 0FFh)
	JNE	@GIOCOM@_PARIFN  ;bad filename if ASC and BIN specified
	OR	byte [@GIOCOM@__CMFLG+DI],((@GIOCOM@__CMCOD) and 0FFh)
	JMP	@GIOCOM@_LPARM  ;get next parameter

@GIOCOM@_SYNPRM:
	CMP	byte [SI+0],((",") and 0FFh)
	JZ	@GIOCOM@_GETPRM  ;Brif found ","
	JMP	@GIOCOM@_PARIFN  ; else "Bad File Name" if no comma
@GIOCOM@_CHKPRM:
	DEC	SI

@GIOCOM@_GETPRM:
	CMP	byte [SI+0],((0) and 0FFh)
	JZ	@GIOCOM@_GETPRX  ;Brif EOS

;Get Next Option Char skipping blanks and forcing upper case
; Exit - Carry = comma, Z = end-of-statement, else [AL]=byte

@GIOCOM@_GETPRI:
	INC	SI
@GIOCOM@_GETPR0:
	MOV	AL,byte [SI+0]  ;Get next char
	CMP	AL,((" ") and 0FFh)
	JZ	@GIOCOM@_GETPRM  ;Ignore Blanks
	CMP	AL,((",") and 0FFh)
	JNZ	@GIOCOM@_GETPR1  ;Brif not ","
	OR	AL,AL  ;set NZ (not end-of-statement)
	STC  ;set carry
	RET  ;Comma returns: NZ and TC
@GIOCOM@_GETPR1:
	CMP	AL,(("a") and 0FFh)  ;Case convert?
	JB	@GIOCOM@_GETPR2  ;Brif not
	XOR	AL,((32) and 0FFh)  ;Convert to Uppercase
@GIOCOM@_GETPR2:
	OR	AL,AL  ;Chars return NZ and NC
@GIOCOM@_GETPRX:
	RET  ;EOS returns TZ and NC

;Parse decimal number returning result in [DX]

@GIOCOM@_VALGET:
	PUSH	BX
	XOR	DX,DX  ;INITIAL VALUE OF ZERO
	MOV	AH,((6) and 0FFh)  ;MAXIMUM 5 DIGITS.
@GIOCOM@_VALLOP:
	CALL	@GIOCOM@_GETPRI  ;Get next char in [AL]
	CMP	AL,(("9"+1) and 0FFh)  ;NOW SEE IF ITS A DIGIT
	JNB	@GIOCOM@_VALXIT  ;IF NOT, RETURN
	CMP	AL,(("0") and 0FFh)
	JB	@GIOCOM@_VALXIT
	MOV	BX,DX  ;ARG=ARG*10+DIGIT
	ADD	BX,BX  ;*5
	ADD	BX,BX
	ADD	BX,DX
	ADD	BX,BX  ;*2
	SUB	AL,(("0") and 0FFh)  ;ADD IN THE DIGIT
	MOV	DL,AL
	XOR	DH,DH  ;[DX]=new digit
	ADD	BX,DX
	XCHG	DX,BX  ;VALUE SHOULD BE IN [DX]
	DEC	AH  ;Max digits -1
	JNZ	@GIOCOM@_VALLOP  ;WILL FALL THRU IF MORE THAN 5 DIGITS
	JMP	@DERIFN  ;TOO MANY DIGITS. Illegal File Name
@GIOCOM@_VALXIT:
	DEC	SI  ;Adjust for GETPRM
	POP	BX
	RET

;COMEOF - test for End-Of-File on device.
; Entry - SI points to File-Data-Block.
;         [DI] = device offset (2=COMD, 4=SCRN, etc.)
; Exit  - [BX] = -1 if EOF, 0 if not EOF

; EXTRN	INCHSI:NEAR
@GIOCOM@_COMEOF:
	CMP	byte [@F_CODE+SI],((@FC_BIN) and 0FFh)
	JE	@GIOCOM@_BINEOF  ;Branch if not ASCII file mode

;The following code is removed so we won't say EOF is false and then
; give user Input-Past-End error when CTL-Z finally comes through.
; This also means EOF function will hang waiting for input, but
; presumably, user wants device to look like sequential file, not
; a dynamic COM-I/O device if he is using EOF function.

	XOR	BX,BX  ;assume no EOF
	CALL	@INCHSI  ;[AL]=next byte from COM device
	JB	@GIOCOM@_YCMEOF  ;branch if next char = EOF
	CALL	@BCHRSI  ;put this back in queue
@GIOCOM@_CMEOFX:	RET  ;BX=0,  end-of-file is false

;   In BINARY mode, GW-BASIC EOF is compatible with IBM-PC Basic
;   That is, EOF is true when no data is in input queue.

@GIOCOM@_BINEOF:
	CALL	@GIOCOM@_COMLOC  ;[BX]=number of bytes in input queue
	OR	BX,BX
	JE	@GIOCOM@_YCMEOF  ;branch if input queue is empty
	MOV	BX,1  ;return with [BX]=0 (false)
@GIOCOM@_YCMEOF:	DEC	BX  ;BX=-1 if end-of-file is true
	RET

;COMLOC - Number of Bytes in input buffer for device.
; Entry - SI points to File-Data-Block.
;         DI = device offset
; Exit  - [BX] = result.

@GIOCOM@_COMLOC:	CALL	@GIOCOM@_GCMUID  ;AL=Unit ID
	MOV	AH,AL
	CALL	@GIOCOM@_GCOMSZ  ;[DX]=number of bytes in input buffer
	MOV	BX,DX  ;return result in BX
	TEST	byte [@F_FLGS+SI],((@FL_BKC) and 0FFh)
	JZ	@GIOCOM@_CMLOCX  ;branch if char not backed up
	INC	BX
@GIOCOM@_CMLOCX:	RET

;COMLOF - number of bytes free in input buffer.
; Entry - SI points to File-Data-Block.
;         [DI] = device offset (2=COMD, 4=SCRN, etc.)
; Exit  - [Floating-Point-Accumulator] = result.

@GIOCOM@_COMLOF:	CALL	@GIOCOM@_COMLOC
	MOV	BX,CX  ;Prep to move free bytes to FAC
	JMP	@MAKINT  ;return result in FAC

;COMCLS - perform any device dependent close functions.
; Entry - SI points to File-Data-Block.
;         [DI] = device offset (2=COMD, 4=SCRN, etc.)
; Exit  - All registers preserved.
;         This routine is called before BASIC releases the
;         file-data-block associated with this file.

@GIOCOM@_COMCLS:	CALL	@GIOCOM@_GCMDCB  ;DI points to device control block
	MOV	word [@GIOCOM@__CMFDB+DI],0  ;mark device as not-in-use
	CMP	byte [@F_CODE+SI],((@FC_BIN) and 0FFh)
	JE	@GIOCOM@_COMCLX  ;Branch if BINARY file mode
	CMP	byte [@F_MODE+SI],((@MD_SQI) and 0FFh)
	JE	@GIOCOM@_COMCLX  ;don't send EOF if input mode
	MOV	AL,((@ASCCTZ) and 0FFh)  ;else send CTL-Z indicating EOF
	MOV	AH,byte [@GIOCOM@__DEVID+DI]  ;[AH]=device ID
	CALL	@SNDCOM  ;output CTL-Z to COM channel
;ignoring error conditions
@GIOCOM@_COMCLX:	MOV	AH,byte [@GIOCOM@__DEVID+DI]  ;[AH]=device ID
	CALL	@TRMCOM  ;terminate COM channel
	JMP	@GIOCOM@_CKCMER  ;Check for COM I/O Error

;COMSWD - set device width
; Entry - SI points to File-Data-Block.
;         [DX] = new device width
;         [DI] = device offset (2=COMD, 4=SCRN, etc.)
; Exit  - All registers preserved

@GIOCOM@_COMSWD:	CALL	@GIOCOM@_GCMDCB  ;DI points to device control block
	MOV	byte [@GIOCOM@__CMWID+DI],DL  ;set device width
@GIOCOM@_RET12:	RET

;COMRND - perform random I/O.
; Entry - [AL] = function to be performed:
;                0: get next record
;                1: put next record
;                2: get record [DX] (1-relative)
;                3: put record [DX] (1-relative)
;         [SI] points to File-Data-Block
;         [DI] = device offset (2=COMD, 4=SCRN, etc.)
; Exit  - All registers are used.

end if
; EXTRN	FILMOD:WORD
if @GW_PASS = 1
@GIOCOM@_COMRND:	CMP	AL,((2) and 0FFh)
	JAE	@GIOCOM@_CMRND1  ;branch if user specified byte count
	MOV	DX,word [@FD_SIZ+SI]  ;default to record-size
@GIOCOM@_CMRND1:	LEA	BX,dword [@FD_DAT+SI]  ;BX points to random record buffer
	MOV	CX,DX  ;CX=byte count
	TEST	AL,((1) and 0FFh)
	JNZ	@GIOCOM@_PUTRND  ;branch if PUT requested
@GIOCOM@_GETLOP:	PUSH	DI  ;[AL]=next byte from com port
	CALL	@GIOCOM@_COMSIN  ;[AL]=next byte from com port
	POP	DI
	MOV	byte [BX+0],AL  ;save byte in buffer
	INC	BX  ;bump buffer pointer
	LOOP	@GIOCOM@_GETLOP
	RET
@GIOCOM@_PUTRND:	CALL	@GIOCOM@_GCMDCB  ;DI points to COMx DCB
@GIOCOM@_PUTLOP:	MOV	AL,byte [BX+0]  ;[AL]=next byte from buffer
	CALL	@GIOCOM@_CMROUT  ;output to com port
	INC	BX  ;bump buffer pointer
	LOOP	@GIOCOM@_PUTLOP
	RET

;COMSIN - Sequential Input.
; Entry - SI points to File-Data-Block.
;         [DI] = device offset (2=COMD, 4=SCRN, etc.)
; Exit  - [AL] = next byte from file,
;         carry set if EOF.
;         All other registers preserved

@GIOCOM@_COMSIN:
@GIOCOM@_CSWAIT:	CALL	@GIOCOM@_GCMUID  ;[AL]=Com Unit ID(DI)
	MOV	AH,AL  ;[AH]=Com Unit ID(DI)
	CALL	@RECCOM  ;[AL]=input byte (if data is ready)
	PUSHF
	CALL	@GIOCOM@_CKCMER  ;Check for COM I/O Error
	POPF
	JNZ	@GIOCOM@_CSGOT1  ;wait if none ready to be read
	CALL	@POLKEY  ;allow CTL-Z to break in
	JMP	@GIOCOM@_CSWAIT
@GIOCOM@_CSGOT1:
	CMP	AL,((@ASCCTZ) and 0FFh)  ;check for CTL-Z
	JNE	@GIOCOM@_CMNEOF  ;branch if not
	CMP	byte [@F_CODE+SI],((@FC_BIN) and 0FFh)
	JE	@GIOCOM@_CMNEOF  ;CTL-Z is not EOF for Binary files
	STC  ;CTL-z is EOF for ASCII files
	JMP	@GIOCOM@_CMSINX  ;restore registers and exit
@GIOCOM@_CMNEOF:	OR	AL,AL  ;clear carry (no eof)
@GIOCOM@_CMSINX:	RET

;COMSOT - Sequential Output.
; Expand tab to spaces, force carriage return before outputting char
; if char is printable (greater than 20h) and column exceeds width.
; Since CRONLY is false in GW versions, COMSOT always gets CR-LF for
; end-of-line.  To be as close to IBM Basic as possible, the following
; algorithm is used:
;   Eat LF if last-char-was-CR
;   clear last-char-was-CR flag
;   if char is CR
;       set last-char-was-CR flag
;       if LF-option was set in filename,
;           output a LF
;   The only known case where this is different from IBM is if the file
;   is opened without the LF option and the user executes
;   PRINT CHR$(13);CHR$(10);.  On IBM, 13-10 would be output.
;   On GW, 13 would be output.  The ultimate solution would be for GW
;   to be compiled with CRONLY=1 and change disk code to insert LF after
;   CR.
; Entry - SI points to File-Data-Block.
;         [DI] = device offset (2=COMD, 4=SCRN, etc.)
;         [AL] = byte to be output.
; Exit  - SI, DI can be changed.
;         All other registers preserved
;         This routine keeps track of column position,
;         expands tabs, and forces a carriage return when line width
;         is exceeded.

@GIOCOM@_COMSOT:	PUSH	AX
	CALL	@GIOCOM@_GCMDCB  ;DI points to COMx DCB
	POP	AX  ;restore [AL]=byte to output
	TEST	byte [@GIOCOM@__CMFLG+DI],((@GIOCOM@__CMCOD) and 0FFh)
	JE	@GIOCOM@_NOTBIN  ;brif user didn't explicitly specify BIN
	CMP	byte [@F_CODE+SI],((@FC_BIN) and 0FFh)
	JE	@GIOCOM@_CMROUT  ;if BIN, branch to Raw-Output routine
@GIOCOM@_NOTBIN:	PUSH	BX
	PUSH	DX
	MOV	BX,@GIOCOM@_CMOUT1  ;BX points to Raw Output Routine
	MOV	DL,byte [@F_WID+SI]  ;[DL]=device width (from FDB)
	MOV	DH,byte [@GIOCOM@__CMPOS+DI]  ;[DH]=current column (from DCB)
; EXTRN	CRIFEL:NEAR
	CALL	@CRIFEL  ;force CR if End-Of-Line, output char

	MOV	byte [@GIOCOM@__CMPOS+DI],DH  ;save new column position
	POP	DX
	POP	BX
@GIOCOM@_RET11:	RET

;Low-Level RS232 Output (updates column position)
; If LF option was not set in COMOPN (OPEN "COM1:,,,,LF), eat all LineFeeds
;    which follow CarriageReturns with following algorithm:
; if (Char <> LF) or (LastWasCR = 0) then output (Char)
; if (Char = CR) then LastWasCR = 1 else LastWasCR = 0
; if (LastWasCR) and COMOPN.LF then output(LF)

; The best way this could have been done was by setting CRONLY=1 in the
; switch files and letting the device drivers append Line-Feeds if necessary.
; It was considered too late to make a change this drastic

@GIOCOM@_CMOUT1:	CALL	@UPDPOS  ;[DH]=new column position(AL, DH)
	PUSH	AX  ;save character to be output
	CMP	AL,((@ASCLF) and 0FFh)
	JNE	@GIOCOM@_CMOUT2  ;branch if not attempting to output LF
	TEST	byte [@GIOCOM@__CMFLG+DI],((@GIOCOM@__CMCRF) and 0FFh)
	JNE	@GIOCOM@_CMOUT3  ;brif last byte out was CR
@GIOCOM@_CMOUT2:
	CALL	@GIOCOM@_CMROUT  ;output the character
@GIOCOM@_CMOUT3:
	POP	AX  ;restore [AL]=char which was output
	AND	byte [@GIOCOM@__CMFLG+DI],((255-@GIOCOM@__CMCRF) and 0FFh)  ;reset last byte out was CR flag
	CMP	AL,((@ASCCR) and 0FFh)
	JNE	@GIOCOM@_CMOUTX  ;return if wasn't carriage return
	OR	byte [@GIOCOM@__CMFLG+DI],((@GIOCOM@__CMCRF) and 0FFh)  ;set last byte out was CR flag
	TEST	byte [@GIOCOM@__CMFLG+DI],((@GIOCOM@__CMCLF) and 0FFh)
	JE	@GIOCOM@_CMOUTX  ;brif CR is not to be mapped to CR-LF
	PUSH	AX
	MOV	AL,((@ASCLF) and 0FFh)
	CALL	@GIOCOM@_CMROUT
	POP	AX
@GIOCOM@_CMOUTX:
	RET

;Output byte [AL] to device with COM DCB pointed to by [DI].
;If error occurs, jump to ERROR

@GIOCOM@_CMROUT:	MOV	AH,byte [@GIOCOM@__DEVID+DI]  ;[AH]=device ID
	PUSH	AX
	CALL	@SNDCOM  ;output [AL] to COM and return
	CALL	@GIOCOM@_CKCMER  ;Check for I/O errors and return
	POP	AX
	RET

;COMGPS - return current file position.
; Entry - SI points to File-Data-Block.
;         [DI] = device offset (2=COMD, 4=SCRN, etc.)
; Exit  - [AH] = current file column. (0-relative)
;         All other registers preserved

@GIOCOM@_COMGPS:	CALL	@GIOCOM@_GCMDCB  ;DI points to Device Control Block
	MOV	AH,byte [@GIOCOM@__CMPOS+DI]
	RET

;COMGWD - get device width
; Entry - SI points to File-Data-Block.
;         [DI] = device offset (2=COMD, 4=SCRN, etc.)
; Exit  - [AH] = device width as set by xxxSWD
;         All other registers preserved

@GIOCOM@_COMGWD:	CALL	@GIOCOM@_GCMDCB  ;DI points to Device Control Block
	MOV	AH,byte [@GIOCOM@__CMWID+DI]  ;get width
	RET

;COMSCW - set device comma width
; Entry - [BX] = new device comma width
;         SI points to File-Data-Block.
;         [DI] = device offset (2=COMD, 4=SCRN, etc.)
; Exit  - SI, DI can be changed.
;         All other registers preserved

@GIOCOM@_COMSCW:	RET

;COMGCW - get device comma width
; Entry - SI points to File-Data-Block.
;         [DI] = device offset (2=COMD, 4=SCRN, etc.)
; Exit  - [BX] = device comma width as set by xxxSCW
;         All other registers preserved

@GIOCOM@_COMGCW:	RET

;GCMDCB - get pointer to COM Device Control Block
; Entry - [DI] = -2*device id (2,4,..n)
; Exit  - DI points to the device control block for device DI.
;         [AX] = 0..n for COM1, COM2, ...

@GIOCOM@_GCMDCB:	CALL	@GIOCOM@_GCMUID  ;[AX]=unit id (0..n)
	PUSH	AX  ;save unit id
	MOV	AH,((@GIOCOM@_CDCBSZ) and 0FFh)  ;AX = bytes per COM DCB
	MUL	AH  ;AX = unit ID * CDCBSZ
	ADD	AX,@CM1DCB
	MOV	DI,AX  ;DI points to COMx device ctl block
	POP	AX  ;[AX]=unit id
	RET

;GCMUID - get COM Unit Id
; Entry - [DI] = -2*device id (2,4,..n)
; Exit  - [AX] = 0..n for COM1, COM2, ...

@GIOCOM@_GCMUID:	MOV	AX,DI
;       ADDI    AX,$CODE+2*<$.COM1-^O400>   ;[DI]=0, 2, ... for COM1, COM2, ...
	SHR	AX,1
	ADD	AX,(@@S_COM1-256)  ;[AX]=0, 1, ... for COM1, COM2, ...
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
