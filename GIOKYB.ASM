; [ This translation created 10-Feb-83 by Version 4.3 ]

if @GW_PASS = 1

include 'OEM.H'

; TITLE   GIOKYB - Machine Independent Keyboard Device Driver Code

; COMMENT	*

; --------- --- ---- -- ---------
; COPYRIGHT (C) 1982 BY MICROSOFT
; --------- --- ---- -- ---------

; 	*
include 'GIO86U'

;Generic Switches

@CPM86=0
@GIOKYB@_IBMCSR=@IBMLIK  ;IBM compatible cursor interface

;OEM Switches

@GIOKYB@_MELCO=0
@GIOKYB@_COMPAQ=0

;Local switches
@GIOKYB@_INTHND=@SCP AND @GW

include 'MSDOSU'

; PUBLIC	KYBDSP,KYBINI,KYBTRM
; EXTRN	SCNSWD:NEAR,SCNGWD:NEAR,SCNSOT:NEAR,SCNGPS:NEAR,SCNGCW:NEAR
; EXTRN	SCNSCW:NEAR
; EXTRN	MAKINT:NEAR,INIFDB:NEAR,DERBFM:NEAR
; EXTRN	INITQ:NEAR,GETQ:NEAR,PUTQ:NEAR
; EXTRN	DEVBIN:NEAR,DEVBOT:NEAR
; EXTRN	SCNBRK:NEAR,EDTBRK:NEAR
	@GIOKYB@_CTLBRK=65283  ;&HFF03 is Ctl-Break
	@GIOKYB@_CTLPAS=65299  ;&HFF13 is Ctl-Pause

; Keyboard Data-Flow/Control-Structure for GIO86:

;    PLAY, LIST, NEWSTT                                            INCHRI
;    --------+---------                                      (fixed length input)
;            !                                   INLIN               !
;            !                              (Screen Editor)     KYBSIN/CHGET
;         CHKINT                                   !        (Device Indep. input)
;     +-------------+                              !                 !
;     !             !                              +-----------------+
;     !             !                                       !
;     !             !                  INKEY$             KEYIN
;     !           POLKEY                 !                  !
;     !             !                    +--------------+---+
;     !        +----+--------+-------+                  !
;     !        !    !        !       !                CHSNS (get 1 KEY {may be 2 bytes}
;     !        !  CNTCCN  KEYTRP  PKEYQ                 !    function key expansion)
;     !        !    !                !      ------+     !
;     !        +----+              PUTQ --> ! ! ! !--> CONIN (get 1 byte from queue)
;     !             !                       ------+
;  POLLEV         KEYINP(OEM supplied)      (queue)
;(OEM supp.)      (maps to MS Univ keyboard)
;(test for trapable event)

;Keyboard Dispatch Table

@KYBDSP:
	DW	(@GIOKYB@_KYBEOF)  ;test EOF for file opened to this device
	DW	(@GIOKYB@_KYBLOC)  ;LOC
	DW	(@GIOKYB@_KYBLOF)  ;LOF
	DW	(@GIOKYB@_KYBCLS)  ;perform special CLOSE functions for this device
	DW	(@SCNSWD)  ;set device width
	DW	(@DERBFM)  ;GET/PUT random record from/to this device
	DW	(@GIOKYB@_KYBOPN)  ;perform special OPEN functions for this device
	DW	(@KYBSIN)  ;input 1 byte from file opened on this device
	DW	(@SCNSOT)  ;output 1 byte to file opened on this device
	DW	(@SCNGPS)  ;POS
	DW	(@SCNGWD)  ;get device width
	DW	(@SCNSCW)  ;set device comma width
	DW	(@SCNGCW)  ;get device comma Width
	DW	(@DEVBIN)  ;block input from file opened on this device
	DW	(@DEVBOT)  ;block output to file opened on this device

; SUBTTL Keyboard Primitive I/O Routines

; EXTRN	BCHRSI:NEAR

;KYBINI puts the keyboard device server in an initial state.
; It is called at initialization time and after CTL-C.
; On exit, all registers are preserved.

; EXTRN	FINPRT:NEAR,PDCBAX:NEAR
end if
; EXTRN	KYBQDS:WORD,KYBQUE:WORD,KYBQSZ:WORD
if @GW_PASS = 1
@KYBINI:
	PUSH	AX
	PUSH	BX
	PUSH	CX
	PUSH	DX
	PUSHF
	PUSH	SI
	XOR	AX,AX
	MOV	word [@CMDOFF],AX  ;[CMDOFF]=0 (no soft key)
	MOV	SI,@KYBQDS  ;SI = keyboard queue descriptor
	MOV	BX,@KYBQUE  ;BX points to 1st byte of queue buff
	MOV	AX,@KYBQSZ  ;AX = size of keyboard queue
	CALL	@INITQ  ;Initialize keyboard queue
	CALL	@FINPRT  ;reset PTRFIL to Keyboard/CRT
	POP	SI
	POPF
	JMP	@PDCBAX  ;POP DX, CX, BX, AX and return

; PUBLIC	KYBCLR
;KYBCLR - Clear the keyboard buffer
;This routine has been documented to OEMs.  The routine is intended to support
;the IBM poke which clears the keyboard buffer.
;Entry - none
;Exit  - none
;        Segment registers and stack preserved.

@KYBCLR:	CALL	@KYBINI  ;Initialize the keyboard buffer
	RET
;KYBEOF - test for End-Of-File on device.
; Entry - SI points to File-Data-Block.
; Exit  - [BX] = -1 if EOF, 0 if not EOF

; EXTRN	INCHSI:NEAR

@GIOKYB@_KYBEOF:	XOR	BX,BX  ;0 means not at eof
	OR	SI,SI
	JZ	@GIOKYB@_KBEOFX  ;branch if not pseudo keyboard FDB
	CALL	@INCHSI  ;[AL]=next byte from keyboard
	JB	@GIOKYB@_YKYEOF  ;branch if next key = CTL-Z
	CALL	@BCHRSI  ;put this back in queue
@GIOKYB@_KBEOFX:	RET
@GIOKYB@_YKYEOF:	DEC	BX  ;BX=-1, end-of-file is true
@KYBTRM:	RET

;KYBLOC - Number of Bytes in input buffer for KEYBOARD device.
; Entry - SI points to File-Data-Block.
; Exit  - [BX] = result.

@GIOKYB@_KYBLOC:	PUSH	SI  ;save FDB pointer
	MOV	SI,@KYBQDS  ;SI points to KYB queue descriptor
; EXTRN	NUMQ:NEAR
	CALL	@NUMQ  ;[AX]=number of bytes queued in KYB Q
	POP	SI
	MOV	BX,AX  ;return result in BX
	TEST	byte [@F_FLGS+SI],((@FL_BKC) and 0FFh)
	JZ	@GIOKYB@_KYLOCX  ;branch if char not backed up
	INC	BX
@GIOKYB@_KYLOCX:	RET

;KYBLOF - number of bytes free in KEYBOARD input buffer.
; Entry - SI points to File-Data-Block.
; Exit  - [Floating-Point-Accumulator] = result.

@GIOKYB@_KYBLOF:	MOV	SI,@KYBQDS  ;SI points to KYB queue descriptor
; EXTRN	LFTQ:NEAR
	CALL	@LFTQ  ;[AX]=number of bytes free in KYB Q
	MOV	BX,AX
	JMP	@MAKINT  ;return result in FAC

;KYBCLS - perform any device dependent close functions.
; Entry - SI points to File-Data-Block.
; Exit  - All registers preserved.
;         This routine is called before BASIC releases the
;         file-data-block associated with this file.

@GIOKYB@_KYBCLS:
@GIOKYB@_RET11:	RET

;KYBOPN - perform any device dependent open functions.
; Entry - [AL]=  device id
;                0 if default device,
;                1..n for Disk A:, B:, ...
;                -1..-n for non-disk devices
;         [BX] = file number (0..n)
;         [CX] = random record size if [FILMOD] = random
;                (if [CX] = 0, use default record size)
;         [DI] = device offset (2=KYBD, 4=SCRN, etc.)
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

@GIOKYB@_KYBOPN:
	MOV	AH,((@MD_SQI) and 0FFh)  ;allow input only
end if
; EXTRN	FILMOD:WORD
if @GW_PASS = 1
	CMP	byte [@FILMOD],((@MD_RND) and 0FFh)
	JNZ	@GIOKYB@_KYBOPX  ;Leave the mode as it is
	MOV	byte [@FILMOD],AH  ;Force the mode to INPUT
@GIOKYB@_KYBOPX:
	JMP	@INIFDB

;KYBSIN - Sequential Input.
; Entry - SI points to File-Data-Block.
; Exit  - [AL] = next byte from Keyboard File
;         carry set if EOF (CTL-Z read) (only if SI points to FDB (non 0))
;         (Note: SI must be preserved for KYBEOF to work)
;         All other registers preserved

; PUBLIC	KYBSIN,INCHRI,CHGET
end if
; EXTRN	SAVKEY:WORD,SAVKYF:WORD
if @GW_PASS = 1
; EXTRN	SCNPOS:NEAR

@INCHRI:
; EXTRN	INFMAP:NEAR
	MOV	AL,byte [@SAVKEY]
	CMP	byte [@SAVKYF],((0) and 0FFh)
	MOV	byte [@SAVKYF],((0) and 0FFh)
	JNZ	@GIOKYB@_KBSINX  ;Send second bytes through unfiltered
@GIOKYB@_KEYGET:
	STC
	CALL	@STCTYP  ;Set new cursor type to user mode (PSW.C set)
	CALL	@GIOKYB@_KEYSIN  ;Read a key from the OS (could be a null fkey)
	CALL	@INFMAP  ;OEM fixed length input map routine
	JZ	@GIOKYB@_KEYGET  ;OEM filtered out the key - get the next
	JMP	@GIOKYB@_KYBSI2  ;Process as other keys
@CHGET:
@KYBSIN:	MOV	AL,byte [@SAVKEY]
	CMP	byte [@SAVKYF],((0) and 0FFh)
	MOV	byte [@SAVKYF],((0) and 0FFh)  ;clear 2nd-byte of 2-byte sequence flag
	JNZ	@GIOKYB@_KBSINX  ;branch if 2nd-key of 2-byte sequence
	CALL	@STCTYP  ;Set to insert or overwrite cursor (PSW.C reset)
	CALL	@KEYIN  ;[AX]=next character from keyboard
@GIOKYB@_KYBSI2:
	JB	@GIOKYB@_KBSIN2  ;branch if got 2-byte sequence (f-key/KANJI)
	PUSHF
	OR	SI,SI
	JZ	@GIOKYB@_KB1X  ;branch if no FDB
	CMP	AL,((@ASCCTZ) and 0FFh)  ;CTL-Z=eof for keyboard
	JNE	@GIOKYB@_KB1X  ;branch if not EOF
	POPF
	STC  ;return EOF indication
	JMP	@GIOKYB@_KBSINX
@GIOKYB@_KB1X:	POPF
	JMP	@GIOKYB@_KBSINX
@GIOKYB@_KBSIN2:
	MOV	byte [@SAVKEY],AL  ;save 2nd byte of 2-byte sequence
	MOV	byte [@SAVKYF],((255) and 0FFh)  ;Set saved key flag
	XCHG	AH,AL  ;return 1st byte to user
	CLC  ;clear carry (not EOF)
@GIOKYB@_KBSINX:	RET

;KEYIN turns cursor on if no key is available.
; It then waits for key from keyboard (if one wasn't already there).
; Exit - if Z is true, no key was ready, else [AX]=key
;        if C is true, returns 16 bit character
;        Soft keys are expanded if not being trapped, and not null.
;        if NZ AND NC AND [AL] = FF then a two byte character is returned
;               in DX.  The character is an OEM specific special character.
;        All other registers are preserved.

; PUBLIC	KEYIN
@KEYIN:
@GIOKYB@_IGNNFK:	CALL	@GIOKYB@_KEYSIN  ;Get a key (possibly a null function key)
	PUSHF
	JAE	@GIOKYB@_NOTNFK  ;branch if not 2-byte key code
	CMP	AH,((128) and 0FFh)
	JNE	@GIOKYB@_NOTNFK  ;branch if definitely not a null Function key
	CMP	AL,((32) and 0FFh)
	JB	@GIOKYB@_NOTNFK  ;branch if definitely not a null Function key
	CMP	AL,((65) and 0FFh)
	JAE	@GIOKYB@_NOTNFK  ;branch if definitely not a null Function key
	POPF
	JMP	@GIOKYB@_IGNNFK  ;ignore null Function key

@GIOKYB@_NOTNFK:	POPF
	RET

;KEYSIN - Get a key.  This routine will return null function keys.
;Entry - none
;Exit  - PSW.C set indicates a two byte key code

@GIOKYB@_KEYSIN:	CALL	@CHSNS  ;try to get next key
	JNE	@GIOKYB@_KEYINX  ;Return with key if there is one.
	PUSH	DX
	CALL	@SCNPOS  ;[DH]=1 relative column (cursor position)
;[DL]=1 relative line
	CALL	@SETCSR  ;Set the cursor
	POP	DX
@GIOKYB@_CHWAIT:	CALL	@CHSNS  ;Has a key been typed?
	JE	@GIOKYB@_CHWAIT  ;No, wait
@GIOKYB@_KEYINX:	PUSHF
	PUSH	AX
	MOV	byte [@CSRTYP],((3) and 0FFh)  ;Indicate user cursor
	CALL	@SETCSR  ;Set the cursor
	POP	AX
	POPF
	RET
; SUBTTL  Keyboard Interrupt/Trap Checking in an Operating System Environment

;POLKEY is called from several places in BASIC to "poll" the keyboard.
; Exit - DI is used.  All other registers are preserved.
;        If CTL C was typed, Control does not return to caller.

; Function:
;       get key from operating system
;       while keyboard data is ready to be read begin
;         get key
;         if key is CTL-C, reset soft-key pointer, key-queue, AUTFLG, SEMFLG
;            call SNDRST to reset background sound,
;            and exit to CNTCCN (resets stack and jumps to STOP)
;         if key is CTL-S, pause until non-CTL-S key is pressed
;         if key is 1st byte of Function Key, continue getting keys
;            until it definitely is or is not a function key.
;         if it was a function key then begin
;            if trapping is enabled then
;               trap it
;            else
;               queue function key code for CHSNS
;            end {it was a function key}
;         else {it was not a function key}
;           queue key for CHSNS
;       end {while keyboard data ready}

; PUBLIC	POLKEY
; EXTRN	KEYTRP:NEAR,KEYINP:NEAR
end if
; EXTRN	AUTFLG:WORD,SEMFLG:WORD,SAVSTK:WORD,SAVTXT:WORD
if @GW_PASS = 1

@POLKEY:	PUSH	DI
	PUSHF
	PUSH	AX
	PUSH	BX
	PUSH	CX
	PUSH	DX
@GIOKYB@_GETKLP:
end if
; EXTRN	MSDCCF:WORD
if @GW_PASS = 1
	TEST	byte [@MSDCCF],((255) and 0FFh)
	JNZ	@GIOKYB@_ITSCTC  ;Branch if Ctl-C interrupt detected
	CALL	@KEYINP  ;[AX]=next key from keyboard if one exists
	JE	@GIOKYB@_POLKXI  ;branch if no key present
	JAE	@GIOKYB@_NOTTWO  ;branch if not 2-byte key sequence
	CMP	AH,((255) and 0FFh)  ;Test for control function range
	JNZ	@GIOKYB@_NTCTLFN  ;Not a control function
	CALL	@GIOKYB@_TRPCHK  ;Check for trapping in this range
	JNZ	@GIOKYB@_GETKLP  ;Trap set - get next key
@GIOKYB@_NTCTLFN:
	CMP	AH,((128) and 0FFh)
	JNE	@GIOKYB@_NOTFUN  ;branch if not function key
	PUSH	AX  ;save key-code
	SUB	AL,((32) and 0FFh)  ;[AL]=0 for 1st function key
	CMP	AL,((@NMKEYT) and 0FFh)  ;see if its a trapable function key
	JAE	@GIOKYB@_NOFUN1  ;branch if not
	CALL	@KEYTRP  ;Trap key if event is ON
	POP	AX  ;restore key code
	JNZ	@GIOKYB@_GETKLP  ;branch if Key was trapped (don't queue)
	JMP	@GIOKYB@_NOTFUN  ;Not trapped function key (queue key)
@GIOKYB@_POLKXI:	JMP	@GIOKYB@_POLKYX

@GIOKYB@_NOFUN1:	POP	AX  ;Restore key code
@GIOKYB@_NOTFUN:
	CMP	AX,@GIOKYB@_CTLBRK  ;check for Ctl-Break
	JE	@GIOKYB@_ITSCTC  ;branch if CTL C
	CMP	AX,@GIOKYB@_CTLPAS
	JE	@GIOKYB@_ITSINT  ;branch if CTL S
@GIOKYB@_NOTRAP:
	PUSH	AX
	CALL	@LFTQ  ;[AX]=number of bytes free in KYB Q
	CMP	AX,3  ;Test for space in keyboard queue
	POP	AX  ;Restore key code
	JB	@GIOKYB@_GETKLP  ;Loop for next key (interrupt?)
	XCHG	AH,AL
	CALL	@GIOKYB@_PKQUE  ;append 1st byte of sequence to key queue
	XCHG	AH,AL
	JMP	@GIOKYB@_QUEKEY  ;append 2nd byte of sequence to key queue
@GIOKYB@_NOTTWO:
	CMP	AL,((254) and 0FFh)  ;Test for three byte char (IBM "scan codes")
	JNZ	@GIOKYB@_QONEBT  ;Queue a one byte character
	PUSH	AX
	CALL	@LFTQ  ;[AX]=number of bytes free in KYB Q
	CMP	AX,4  ;Test for space in keyboard queue
	POP	AX  ;Restore key code
	JB	@GIOKYB@_GETKLP  ;Loop for next key (interrupt?)
	CALL	@GIOKYB@_PKQUE  ;Queue the first byte
	MOV	AX,DX  ;Get second and third bytes
	JMP	@GIOKYB@_NOTRAP  ;Go queue the second and third bytes
@GIOKYB@_QONEBT:
	JMP	@GIOKYB@_QUEKEY  ;else queue the key for CHSNS
@GIOKYB@_ITSCTC:
	CALL	@KYBINI  ;clear keyboard queue, reset PTRFIL
	MOV	byte [@MSDCCF],((0) and 0FFh)  ;Reset Ctl-Break interrupt flag
; EXTRN	SNDRST:NEAR
	CALL	@SNDRST  ;reset background music
	MOV	SP,word [@SAVSTK]  ;[SP]=SP of interrupted statement
	MOV	BX,word [@SAVTXT]  ;[BX]=text pointer of interrupted stmt
	MOV	AX,@GIOKYB@_CTLBRK  ;[AX]=Key Code for BREAK (CTL-C)
@GIOKYB@_ITSINT:	CALL	@GIOKYB@_CNTCCN  ;process CTL C or S
	JMP	@GIOKYB@_GETKLP  ;dont queue CTL-S or CTL-C

@GIOKYB@_QUEKEY:	CALL	@GIOKYB@_PKQUE  ;queue key [AL] for CHSNS
	JMP	@GIOKYB@_GETKLP  ;get next key

;At this point, Keyboard input queue from OS is flushed.

@GIOKYB@_POLKYX:	POP	DX  ;restore caller's registers
	POP	CX
	POP	BX
@GIOKYB@_POLKXX:	POP	AX
	POPF
	POP	DI
@GIOKYB@_RET8:	RET

;TRPCHK - Check for key trapping
;Entry - AX = key code
;Exit  - PSW.Z set indicates key was not trapped

@GIOKYB@_TRPCHK:	PUSH	AX  ;Save key code
	MOV	BX,@GIOKYB@_TRPKTB-1  ;BX points before 1st byte of key trap table
@GIOKYB@_CHKTRP:	INC	BX
	MOV	AH,byte [cs:BX+0]
	INC	BX  ;BX points to Trap Key ID for key [AH]
	OR	AH,AH  ;test for end-of-table
	JE	@GIOKYB@_NTRAP  ;branch if not a trappable key
	CMP	AH,AL
	JNE	@GIOKYB@_CHKTRP  ;branch if they don't match (continue search)
	MOV	AL,byte [cs:BX+0]  ;[AL]=key-trap id
	CALL	@KEYTRP  ;Trap key if event is ON
@GIOKYB@_NTRAP:	POP	AX  ;Restore key code
	RET
; SUBTTL  CHKKYB - OEM Version of POLKEY
;CHKKYB - This is the OEM version of POLKEY.  It is documented to the OEM as
;the way to check for keyboard interrupts.
;Entry - All segment registers must be set
;        to the BASIC configuration
;Exit  - All registers and PSW preserved

; PUBLIC	CHKKYB
@CHKKYB:	PUSH	SI
	PUSH	BP  ;For safety
	CALL	@POLKEY
	POP	BP
	POP	SI
	RET
; SUBTTL  CNTCCN, PKQUE, TRPKTB
;CNTCCN performs special action upon receipt of CTL-S or CTL-C

; EXTRN	CTRLPT:NEAR,STOP:NEAR
@GIOKYB@_CNTCCN:
	CMP	AX,@GIOKYB@_CTLPAS  ;check for PAUSE
	JNZ	@GIOKYB@_NOTCTS  ;branch if not
@GIOKYB@_GOTCTS:	CALL	@KEYINP
	JZ	@GIOKYB@_GOTCTS  ;wait for resume key (anything but CTL S)
	CMP	AX,@GIOKYB@_CTLPAS  ;check for PAUSE
	JE	@GIOKYB@_GOTCTS  ;branch if got another CTL-S
@GIOKYB@_NOTCTS:
	CMP	AX,@GIOKYB@_CTLBRK  ;check for Ctl-Break
	JNE	@GIOKYB@_RET8  ;return if not CTL-C
	CALL	@EDTBRK  ;Clear editor flags and position cursor
	CALL	@SCNBRK  ;Clear flags associated with screen driver
	PUSH	AX
	CALL	@FINPRT  ;Reset I/O
	POP	AX
	MOV	AX,word [@CURLIN]  ;Print "BREAK" message in program mode only
	AND	AL,AH  ;AL=^D255 if direct mode
	XOR	AH,AH  ;Set PSW.Z so STOP won't give Syntax Error
	JMP	@STOP

;PKQUE appends [AL] to the keyboard circular queue

@GIOKYB@_PKQUE:	PUSH	SI
	MOV	SI,@KYBQDS  ;SI = keyboard queue descriptor
	CALL	@PUTQ  ;append [AL] to keyboard queue (read by CHSNS)
	POP	SI
	RET

;Keyboard Trap Table (for KEY TRAPPING of non-soft keys)
; Referenced by POLKEY

@GIOKYB@_TRPKTB:
	DB	30,@NMKEYF+0  ;ON KEY (Cursor Up)
	DB	29,@NMKEYF+1  ;ON KEY (Cursor Left)
	DB	28,@NMKEYF+2  ;ON KEY (Cursor Right)
	DB	31,@NMKEYF+3  ;ON KEY (Cursor Down)
	DB	0  ;end-of-table
; SUBTTL  Machine independent Keyboard input routines CHSNS, INKEY$
; PUBLIC	CHSNS
end if
; EXTRN	CMDOFF:WORD,STRTAB:WORD
if @GW_PASS = 1

;Get key from keyboard if one is ready.
;Exit  - if Z is true, no key was ready, else [AX]=key
;        if C is true, returns 16 bit character
;        Soft keys are expanded if not being trapped, and not null.
;        if NZ AND NC AND [AL] = FF then a two byte character is returned
;               in DX.  The character is an OEM specific special character.
;        All other registers are preserved.

@CHSNS:	PUSH	BX  ;save caller's registers
	PUSH	CX
	PUSH	SI
	PUSH	DI
@GIOKYB@_CHSNSI:	XOR	DL,DL  ;clear high byte of 2-byte sequence
@GIOKYB@_CHSNS0:	CALL	@GIOKYB@_CONIN  ;check for SOFTKEY
	JNZ	@GIOKYB@_CHSNSS  ;BRIF key found
	OR	DL,DL
	JZ	@GIOKYB@_CHSNSX  ;BRIF no key sensed and not 2nd of 2 bytes
	JMP	@GIOKYB@_CHSNS0  ;BRIF need 2nd byte of 2 byte character

@GIOKYB@_CHSNSS:	OR	DL,DL
	JNZ	@GIOKYB@_CHSNS2  ;BRIF 2nd byte of 2 byte character
	CALL	@GIOKYB@_CKDBLK  ;see if this is the 1st byte of 2-byte seq
	JAE	@GIOKYB@_CHSNG1  ;branch not
	MOV	DL,AL  ;Put first byte in [DL]
	JMP	@GIOKYB@_CHSNS0  ;Go get 2nd byte
@GIOKYB@_CHSNS2:	MOV	AH,DL  ;Put 1st byte in [AH]
	CMP	AH,((128) and 0FFh)  ;Check for 8080 code which represents single 80
	JNZ	@GIOKYB@_CHSN2A
	CMP	AH,AL
	JZ	@GIOKYB@_CHSNG1  ;Return 80 for 8080 char code
@GIOKYB@_CHSN2A:	CALL	@GIOKYB@_CHKFKY  ;see if AX is a non-null function key
	JZ	@GIOKYB@_CHSNS3  ;BRIF not a string key that needs expansion
	JB	@GIOKYB@_CHSNG1  ;BRIF is super shift key(return first byte now)
	MOV	byte [@F_SUPR],((0) and 0FFh)
	JMP	@GIOKYB@_CHSNSI  ;Is string key, get first expansion and return
@GIOKYB@_CHSNS3:
	OR	AH,AH  ;else NZ, C Indicates 2 byte character
	STC
	JMP	@GIOKYB@_CHSNSX
@GIOKYB@_CHSNG1:	OR	AL,AL  ;set NZ, no-carry (got 1 byte)
	MOV	AH,((0) and 0FFh)  ;high-byte = 0 for single byte characters
;Check for 3 byte sequence case
	PUSHF
	CMP	AL,((254) and 0FFh)  ;Test for three byte sequence
	JNZ	@GIOKYB@_CHSNG2  ;Not a three byte sequence
	PUSH	AX  ;Save first byte
	CALL	@GIOKYB@_CONIN  ;Get second byte
	MOV	DH,AL
	CALL	@GIOKYB@_CONIN  ;Get third byte
	MOV	DL,AL
	POP	AX  ;Restore third byte
@GIOKYB@_CHSNG2:	POPF
@GIOKYB@_CHSNSX:	POP	DI
	POP	SI
	POP	CX
	POP	BX
	RET

@GIOKYB@_CKDBLK:
;Check for function key (80,nn)
	CMP	AL,((128) and 0FFh)  ;First check for 80,nn key
	STC
	JE	@GIOKYB@_CKDBLX  ;branch if 1st of 2-byte sequence
	CMP	AL,((255) and 0FFh)
	STC
	JE	@GIOKYB@_CKDBLX  ;BRIF 1st byte of two byte control function
	CLC
@GIOKYB@_CKDBLX:	RET

;CONIN gets the next key from the soft-key being expanded (if any).
; If no soft-key is active, it calls POLKEY to get and queue key from OS,
; afterwhich it trys to get a key from the keyboard queue.
; On exit, Flags.Z is set if no key is ready, else [AL]=key

@GIOKYB@_CONIN:	PUSH	BX
	CALL	@GIOKYB@_GETFKY  ;expand soft-key if active
	JNZ	@GIOKYB@_CONINX  ;branch if expanding soft-key
	PUSH	SI
	CALL	@POLKEY  ;try to get and queue key from OS
	MOV	SI,@KYBQDS
	CALL	@GETQ  ;[AL]=next key from keyboard queue
	POP	SI
@GIOKYB@_CONINX:	POP	BX
	RET

;Returns with FLAGS.NZ if AX is Universal key code for non-null Soft-key
;Also sets FLAGS.NC for softkey and FLAGS.C for super shift key
;       (note that for super shift the first character is in AL and must
;           be returned)

@GIOKYB@_CHKFKY:	CMP	AH,((128) and 0FFh)
	JNE	@GIOKYB@_NTFKYX  ;branch if not soft-key
	PUSH	AX
	SUB	AL,((32) and 0FFh)
	JB	@GIOKYB@_NTFKY1  ;branch if not soft-key
	CMP	AL,((@NMKEYF) and 0FFh)
	JAE	@GIOKYB@_NTFKY1  ;branch if not soft-key
	MOV	BL,((16) and 0FFh)  ;else, tell CHSNS to expand soft-key
	MUL	BL  ;[AX]=16 * function-key id
	ADD	AX,@STRTAB  ;Get soft-key address
	MOV	word [@CMDOFF],AX  ;save soft-key pointer for soft-key expansion
	MOV	BX,AX
	POP	AX
	CMP	byte [BX+0],((0) and 0FFh)  ;set FLAGS.Z if null soft-key (and FLAGS.NC
	RET  ; not super shift)
@GIOKYB@_NTFKY1:
	JB	@GIOKYB@_NTFKY9  ;BRIF not super shift key
	POP	AX
	PUSH	AX
	CMP	AL,(("A") and 0FFh)
	JB	@GIOKYB@_NTFKY9  ;BRIF not super shift key
	CMP	AL,(("Z"+1) and 0FFh)
	JB	@GIOKYB@_SUPRKY  ;BRIF is super shift key
@GIOKYB@_NTFKY9:
	POP	AX
@GIOKYB@_NTFKYX:	XOR	BL,BL  ;set FLAGS.Z - not soft-key(and FLAGS.NC not
	RET  ;super shift)

; EXTRN	MAPSUP:NEAR,$FN:NEAR,$USR:NEAR,ALPTAB:NEAR
end if
; EXTRN	F_SUPR:WORD
if @GW_PASS = 1
@GIOKYB@_SUPRKY:
end if
; EXTRN	CURLIN:WORD
if @GW_PASS = 1
	CMP	word [@CURLIN],65535  ;Test for direct mode
	JNZ	@GIOKYB@_NTFKY9  ;Not direct mode - don't expand Supershift key
	PUSH	CX
	CALL	@MAPSUP  ;Map super shift key to letter in AL and count
	XOR	CL,CL  ;Interface doc says CH contains count
	JCXZ	@GIOKYB@_SUPKY9  ;Request to inhibit SKey expansion
	SUB	AL,(("A") and 0FFh)  ; in CH
;Scan for CHth reserved word in table that includes words starting with letter
;in AL
;Set up for CONIN to return the reserved word letters one at a time and return
;AL now.
	MOV	BH,((0) and 0FFh)
	MOV	BL,AL
	ADD	BL,AL
	PUSH	BX  ;Save ALPTAB offset
	ADD	BX,@ALPTAB
@GIOKYB@_SUPKY0:
	MOV	BX,word [cs:BX+0]  ;Get start of reserved words for this letter
@GIOKYB@_SUPKY1:
	TEST	byte [cs:BX+0],((255) and 0FFh)
	JZ	@GIOKYB@_SUPKYZ  ;BRIF did not find super key definition(abort)
	DEC	CH
	JZ	@GIOKYB@_SUPKYX  ;BRIF found the reserved word
	DEC	BX
@GIOKYB@_SUPKY2:	INC	BX
	TEST	byte [cs:BX+0],((255) and 0FFh)
	JNS	@GIOKYB@_SUPKY2  ;BRIF not at the end of this reserved word
	INC	BX  ;Skip end of string
	INC	BX  ;Skip token value
	JMP	@GIOKYB@_SUPKY1  ;Check next reserved word
;Found the reserved word
@GIOKYB@_SUPKYX:	MOV	word [@CMDOFF],BX  ;Set up for string key input
	DEC	CH
	MOV	byte [@F_SUPR],CH  ;Set super shift key flag
	POP	BX
@GIOKYB@_SUPKY9:	POP	CX
	POP	AX
	OR	AX,AX  ;Set FLAGS.NZ
	STC  ;Else return AL=first char, FLAGS.NZ and
	RET  ;FLAGS.C When key not found then single char
; returned as first expansion character.  No
;expansion takes place since expansion table
;not initialized.
;Did not find reserved word in ALPTAB, perhaps its in ALPTAX
; EXTRN	ALPTAX:NEAR
@GIOKYB@_SUPKYZ:	POP	BX
	OR	BH,BH
	JNZ	@GIOKYB@_SUPKY9  ;BRIF already checked ALPTAX, exit
	PUSH	CX  ;Put non-zero high byte on stack(so above
; branch is taken)
	ADD	BX,@ALPTAX
	JMP	@GIOKYB@_SUPKY0  ;Continue scan of reserved words

;GETFKY: Called to retrieve a character from the SOFTKEY buffer.
;Supershift key strings are expanded to end in a space unless the last character
; is a "(" or if the token is $FN or $USR.

; Entry - CMDOFF is the index into the buffer
;         F.SUPR = ^O0   - not a supershift softkey
;                  ^O377 - Supershift (CMDOFF points to character)
;                  Other - Supershift (F.SUPR is the next character)
; Exit  - flags.Z set   - no key available
;                 reset - AL contains character
;         BX is used.

@GIOKYB@_GETFKY:	CMP	word [@CMDOFF],0  ;Softkey available?
	JZ	@GIOKYB@_GETFKX  ;No special key available
	CALL	@GIOKYB@_GTSFKY  ;Get a softkey
	CALL	@GIOKYB@_EOKTST  ;Test for end of softkey
@GIOKYB@_GETFKX:	RET

@GIOKYB@_GTSFKY:	MOV	BX,word [@CMDOFF]  ;Get char. offset
	MOV	AL,byte [@F_SUPR]  ;Get super-shift flag
	TEST	AL,((255) and 0FFh)  ;Super-shift key in progress?
	JZ	@GIOKYB@_NOTSUP  ;Not a super-shift key
	CMP	AL,((255) and 0FFh)  ;F.SUPR is ^O377 or current character
	JNZ	@GIOKYB@_GTSFKX  ;Got the key
;Super-shifts are in the CS:
	DB	2EH  ; Code segment override
@GIOKYB@_NOTSUP:	MOV	AL,byte [BX+0]  ;Get next character
	XOR	AH,AH  ;Clear high byte
	INC	BX  ;Index to next key
@GIOKYB@_GTSFKX:	RET

@GIOKYB@_EOKTST:
	TEST	byte [@F_SUPR],((255) and 0FFh)  ;Super-shift key expansion?
	JZ	@GIOKYB@_EFKTST  ;No - testing end of function key
	OR	AL,AL  ;Test highbit (indicates end of key word)
	JNS	@GIOKYB@_NOHGBT  ;Not highbit terminated
	AND	AL,((127) and 0FFh)  ;Map out high bit
	CMP	AL,(("(") and 0FFh)  ;Supershift key ending in "("?
	JZ	@GIOKYB@_EOKTRU  ;Yes, don't end in space
	CMP	byte [cs:BX+0],((@@SUSR) and 0FFh)  ;$USR token?
	JZ	@GIOKYB@_EOKTRU  ;Yes, don't end in space
	CMP	byte [cs:BX+0],((@@SFN) and 0FFh)  ;$FN token?
	JZ	@GIOKYB@_EOKTRU  ;Yes, don't end in space
	MOV	BL,((" ") and 0FFh)  ;End in a space
	JMP	@GIOKYB@_EOKSSX  ; and exit

@GIOKYB@_NOHGBT:	INC	byte [@F_SUPR]  ;Test for last char. in F.SUPR
	DEC	byte [@F_SUPR]  ;(Depends on 128 chars in keyword char. set)
	JS	@GIOKYB@_EOKTSX  ;Last char NOT from F.SUPR (F.SUPR was 377)
	JMP	@GIOKYB@_EOKTRU  ;Last char from F.SUPR - end of supershift
;Test must always leave FLAGS.Z reset
@GIOKYB@_EFKTST:	OR	AL,AL  ;Test for null function key
	JZ	@GIOKYB@_EOKTRU  ;Null F key incountered
	TEST	byte [BX+0],((255) and 0FFh)  ;Test for end of function key
	JNZ	@GIOKYB@_EOKTSX  ;Not end of function key
	OR	SP,SP  ;There is always a character at this point
@GIOKYB@_EOKTRU:	MOV	BX,0  ;Prepare to turn off CMDOFF
@GIOKYB@_EOKSSX:
end if
; EXTRN	F_SUPR:WORD
if @GW_PASS = 1
	MOV	byte [@F_SUPR],BL  ;Turn off current supershift key expansion
@GIOKYB@_EOKTSX:	MOV	word [@CMDOFF],BX  ;Store new softkey expansion index
	RET

;SFTOFF - Turn off softkey expansion for the current softkey.  This routine
;         has been documented to OEMs for use in implementing PEEK/POKE
;         filters for addresses documented to IBM BASIC users.

; PUBLIC	SFTOFF
@SFTOFF:	MOV	word [@CMDOFF],0  ;Stop soft key expansion
	MOV	byte [@F_SUPR],((0) and 0FFh)  ;Turn off super shift flag
	RET

;KYBSNS - Detect whether keys are available in the keyboard buffer.
;         This routine has been documented to OEMs for use in implementation
;         of PEEK/POKE filters for addresses documented to IBM BASIC users.
;Entry - none
;Exit  - PSW.Z set indicates that the keyboard buffer is empty.
;        all registers preserved

; PUBLIC	KYBSNS
; EXTRN	NUMQ:NEAR
@KYBSNS:	PUSH	AX
	PUSH	SI
	MOV	SI,@KYBQDS  ;SI = keyboard queue descriptor
	CALL	@NUMQ  ;Get the number of keys available
	OR	AX,AX  ;Set flags
	POP	SI
	POP	AX
	RET

;FKYSNS - Sense the availability of a softkey.  This routine is documented to
;         IBMLIK OEMs for support of a PEEK/POKE address documented by IBM.
;Entry - none
;Exit  - PSW.C set indicates softkey expansion is in progress
;        PSW.Z set indicates that the next softkey is not the last key
;              of a supershift key.
;        All registers preserved

; PUBLIC	FKYSNS
@FKYSNS:	CMP	byte [@CMDOFF],((0) and 0FFh)  ;Test for expansion in progress
	JZ	@GIOKYB@_FKYSNX  ;Expansion not in progress
	CMP	byte [@F_SUPR],((255) and 0FFh)  ;Test for super-shift expansion
	JZ	@GIOKYB@_FKYSNW  ;SS key but not last key
	CMP	byte [@F_SUPR],((0) and 0FFh)  ;Test for super-shift expansion
	JZ	@GIOKYB@_FKYSNW  ;Function key expansion in progress
@GIOKYB@_FKYSNW:
	STC
@GIOKYB@_FKYSNX:	RET
;INKEY$ - get key from key-queue if one exists, else return null string.
; Returns 2-byte string for DBLCHR.  For function keys, returns next char
; of function key if key is not null.  If F-key is null, it returns
; 2-byte string which identifies function key.

; PUBLIC	INKEY
; EXTRN	INKMAP:NEAR,INFMAP:NEAR
; EXTRN	STRINI:NEAR,STRIN1:NEAR,SETSTR:NEAR,PUTNEW:NEAR,CHRGTR:NEAR
end if
; EXTRN	DSCPTR:WORD,VALTYP:WORD,FACLO:WORD
if @GW_PASS = 1

@INKEY:	CALL	@CHRGTR
	PUSH	BX  ;save text pointer
@GIOKYB@_INKGET:	CALL	@CHSNS  ;get next key from queue
	JZ	@GIOKYB@_NULRT  ;branch if no key is queued
	CALL	@INKMAP  ;OEM map routine for INKEY$
	JZ	@GIOKYB@_INKGET  ;OEM has no associated character
	JAE	@GIOKYB@_INKEY1  ;branch if not 2-byte sequence
	PUSH	AX  ;save char code
	MOV	AL,((2) and 0FFh)
	CALL	@STRINI  ;initialize 2-byte string
	MOV	BX,word [@DSCPTR]
	POP	DX  ;restore char code
	XCHG	DH,DL  ;return high-byte in left end of string
	MOV	word [BX+0],DX
	JMP	@PUTNEW
@GIOKYB@_INKEY1:	PUSH	AX
	CALL	@STRIN1  ;MAKE ONE CHAR STRING
	POP	AX
	MOV	DL,AL
	XCHG	AH,AL  ;put bytes in correct order
	CALL	@SETSTR  ;STUFF IN DESCRIPTOR AND GOTO PUTNEW
end if
; EXTRN	DSEGZ:WORD
if @GW_PASS = 1
@GIOKYB@_NULRT:	MOV	BX,@DSEGZ  ;GUARANTEED ZERO IN DATA SEGMENT
	MOV	word [@FACLO],BX
	MOV	byte [@VALTYP],((3) and 0FFh)
	POP	BX  ;restore text pointer
	RET
; SUBTTL  Cursor Support

;STCTYP Set the new cursor type
;       This routine determines the next cursor type.
;Entry - PSW.C set indicates the cursor must be the user cursor
;        PSW.C reset indicates the cursor must be the insert mode
;              cursor or the overstrike cursor.
;EXIT  - All registers preserved

; PUBLIC	STCTYP
end if
; EXTRN	CSRTYP:WORD,F_INST:WORD
if @GW_PASS = 1
@STCTYP:	PUSH	AX
	MOV	AL,((3) and 0FFh)  ;Assume user cursor
	JB	@GIOKYB@_CSRSET  ;Assumption correct
	DEC	AL  ;Assume overwrite mode cursor
	TEST	byte [@F_INST],((255) and 0FFh)  ;Test for insert mode
	JZ	@GIOKYB@_CSRSET  ;Ovewrite mode discovered
	DEC	AL  ;Set for insert mode
@GIOKYB@_CSRSET:	MOV	byte [@CSRTYP],AL  ;Save the type
	POP	AX
	RET

;SETCSR - Set the cursor to the new cursor type.
;         This routine ensures that the cursor is set to the new cursor type.
;Entry - none
;Exit  - all registers preserved

end if
; EXTRN	CSRTYP:WORD,CSRFLG:WORD
if @GW_PASS = 1
; EXTRN	CSRDSP:NEAR
; PUBLIC	SETCSR
@SETCSR:	PUSH	AX
	MOV	AL,byte [@CSRTYP]  ;Get cursor type
	CMP	byte [@CSRFLG],AL  ;Test for cursor change
	MOV	byte [@CSRFLG],AL  ;Remember the new cursor type
	JZ	@GIOKYB@_CSROK  ;Cursor already set properly
	CALL	@CSRDSP  ;Display the cursor
@GIOKYB@_CSROK:	POP	AX
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
