; [ This translation created 10-Feb-83 by Version 4.3 ]

if @GW_PASS = 1

include 'OEM.H'

; TITLE FIVEO 5.0 Features -WHILE/WEND, CALL, CHAIN, WRITE /P. Allen

@FIVEO@_TSHIBA=0
@FIVEO@_PC8A=0
	@FIVEO@_LABEL=@FIVEO@_PC8A
@FIVEO@_OKI=0
include 'GIO86U'
include 'MSDOSU'
if @CPM86
end if

; EXTRN	RESTORE:NEAR
end if
; EXTRN	SUBFLG:WORD,TEMP:WORD

; Code Segment ( terminated by END at bottom of file )

; EXTRN	CHRGTR:NEAR,SYNCHR:NEAR,DCOMPR:NEAR
; EXTRN	GETYPR:NEAR
; EXTRN	SNERR:NEAR,GETSTK:NEAR,PTRGET:NEAR,CRDO:NEAR
; EXTRN	VMOVFM:NEAR
; EXTRN	FRQINT:NEAR

; SUBTTL  WHILE , WEND
; PUBLIC	WHILE,WEND
; EXTRN	ERROR:NEAR,FRMCHK:NEAR,$FOR:NEAR,$WHILE:NEAR,WNDSCN:NEAR
; EXTRN	FRMEVL:NEAR
; EXTRN	NEWSTT:NEAR,FORSZC:NEAR,ERRWE:NEAR
; EXTRN	SAVSTK:WORD,NXTLIN:WORD,CURLIN:WORD,ENDFOR:WORD
if @GW_PASS = 1

; THIS CODE HANDLES THE STATEMENTS WHILE/WEND
; THE 8080 STACK IS USED TO PUT AN ENTRY ON FOR EACH ACTIVE WHILE
; THE SAME WAY ACTIVE GOSUB AND FOR ENTRIES ARE MADE.
; THE FORMAT IS AS FOLLOWS:
;       $WHILE - THE TOKEN IDENTIFYING THE ENTRY (1 BYTE)
;       A TEXT POINTER AT THE CHARACTER AFTER THE WEND OF THE WHILE BODY (2 BYTES)
;       A TEXT POINTER AT THE CHARACTER AFTER THE WHILE OF THE WHILE BODY (2 BYTES)
;       THE LINE NUMBER OF THE LINE THAT THE WHILE IS ON (2 BYTES)

;       TOTAL   7 BYTES

@WHILE:  ;KEEP THE WHILE TEXT POINTER HERE
	MOV	[@ENDFOR],BX  ;SAVE TEXT ADDRESS
	CALL	@WNDSCN  ;SCAN FOR THE MATCHING WEND
;CAUSE AN ERRWH IF NO WEND TO MATCH
	CALL	@CHRGTR  ;POINT AT CHARACTWER AFTER WEND
	XCHG	BX,DX  ;POSITION OF MATCHING WEND
	CALL	@FIVEO@_FNDWND  ;SEE IF THERE IS A STACK ENTRY FOR THIS WHILE
	LAHF
	INC	SP  ;GET RID OF THE NEWSTT ADDRESS ON THE STACK
	SAHF
	LAHF
	INC	SP
	SAHF
	JNZ	@FIVEO@_WNOTOL  ;IF NO MATCH NO NEED TO TRUNCATE THE STACK
	ADD	BX,CX  ;ELIMINATE EVERYTHING UP TO AND INCLUDING
;THE MATCHING WHILE ENTRY
	MOV	SP,BX
	MOV	[@SAVSTK],BX
@FIVEO@_WNOTOL:	MOV	BX,[@CURLIN]  ;MAKE THE STACK ENTRY
	PUSH	BX
	MOV	BX,[@ENDFOR]  ;GET TEXT POINTER FOR WHILE BACK
	PUSH	BX
	PUSH	DX  ;SAVE THE WEND TEXT POINTER
	JMP	@FIVEO@_FNWEND  ;FINISH USING WEND CODE

@WEND:	JZ	@FIVEO@_@Q@QL000
	JMP	@SNERR  ;STATEMENT HAS NO ARGUMENTS
@FIVEO@_@Q@QL000:
	XCHG	BX,DX  ;FIND MATCHING WHILE ENTRY ON STACK
	CALL	@FIVEO@_FNDWND
	JNZ	@FIVEO@_WEERR  ;MUST MATCH OR ELSE ERROR
	MOV	SP,BX  ;TRUNCATE STACK AT MATCH POINT
	MOV	[@SAVSTK],BX  ;[H,L] POINTING INTO STACK ENTRY
	MOV	DX,[@CURLIN]  ;REMEMBER WEND LINE #
	MOV	[@NXTLIN],DX  ;IN NXTLIN
	INC	BX  ;INDEX INTO STACK ENTRY TO GET VALUES
	INC	BX  ;SKIP OVER TEXT POINTER OF WEND
	MOV	DX,[BX]  ;SET [D,E]=TEXT POINTER OF WHILE
	INC	BX
	INC	BX
	MOV	BX,[BX]  ;[H,L]=LINE NUMBER OF WHILE
	MOV	[@CURLIN],BX  ;IN CASE OF ERROR OR CONTINUATION FIX CURLIN
	XCHG	BX,DX  ;GET TEXT POINTER OF WHILE FORMULA INTO [H,L]
@FIVEO@_FNWEND:	CALL	@FRMEVL  ;EVALUATE FORMULA
; EXTRN	VSIGN:NEAR
	PUSH	BX  ;SAVE TEXT POINTER
	CALL	@VSIGN  ;GET IF TRUE OR FALSE
	POP	BX  ;GET BACK WHILE TEXT POINTER
	JZ	@FIVEO@_FLSWHL  ;GO BACK AT WEND IF FALSE
	MOV	CX,@@SWHILE  ;COMPLETE WHILE ENTRY
	MOV	CH,CL  ;NEED IT IN THE HIGH BYTE
	PUSH	CX
	JMP	@NEWSTT

@FIVEO@_FLSWHL:	MOV	BX,[@NXTLIN]  ;SETUP CURLIN FOR WEND
	MOV	[@CURLIN],BX
	POP	BX  ;TAKE OFF TEXT OF WEND AS NEW TEXT POINTER
	POP	CX  ;GET RID OF TEXT POINTER OF WHILE
	POP	CX  ;TAKE OFF LINE NUMBER OF WHILE
	JMP	@NEWSTT

; THIS SUBROUTINE SEARCHES THE STACK FOR AN WHILE ENTRY
; WHOSE WEND TEXT POINTER MATCHES [D,E]. IT RETURNS WITH ZERO TRUE
; IF A MATCH IS FOUND AND ZERO FALSE OTHERWISE. FOR ENTRIES
; ARE SKIPPED OVER, BUT GOSUB ENTRIES ARE NOT.

	@FIVEO@_WHLSIZ=7

; Note - 8086 versions force stack entries to be an even length
; so stack accesses won't cross word boundaries.  This is done
; for speed.  To accomplish this, an extra byte is pushed on
; top of the WHILE token.  This extra byte is NOT reflected in
; the value of WHLSIZ but is taken care of by the code.

@FIVEO@_FNDWND:	MOV	BX,4  ;SKIP OVER RETURN ADDRESS AND NEWSTT
	ADD	BX,SP
@FIVEO@_FNDWN2:
	INC	BX
	MOV	AL,byte [BX]  ;GET THE ENTRY TYPE
	INC	BX
	MOV	CX,@@SFOR
	CMP	AL,CL  ;SEE IF ITS $FOR
	JNZ	@FIVEO@_FNDWN3
	MOV	CX,@FORSZC-1  ;Yes, so skip over it.  Note that
	ADD	BX,CX  ;the pointer has already been
	JMP	@FIVEO@_FNDWN2  ;incremented once.

@FIVEO@_FNDWN3:	MOV	CX,@@SWHILE
	CMP	AL,CL
	JZ	$+3
	RET
	@INS86	71,27  ;CMP [BX],DX-SAME WEND?
	MOV	CX,@FIVEO@_WHLSIZ-1  ;Note that the pointer has
;already been incremented once.
	JNZ	$+3
	RET  ;RETURN IF ENTRY MATCHES
	ADD	BX,CX
	JMP	@FIVEO@_FNDWN2

@FIVEO@_WEERR:	MOV	DX,@ERRWE
	JMP	@ERROR

; SUBTTL  CHAIN
end if
; EXTRN	TXTTAB:WORD,VALTYP:WORD
; EXTRN	$COMMON:NEAR,$MERGE:NEAR,FRMEVL:NEAR,OMERR:NEAR,SCRTCH:NEAR
; EXTRN	LINGET:NEAR
; EXTRN	$DELETE:NEAR
; PUBLIC	CHAIN,COMMON
; EXTRN	PTRGTN:NEAR,PTRGTR:NEAR
; EXTRN	MOVE1:NEAR,NEWSTT:NEAR,PTRGET:NEAR,STRCPY:NEAR
; EXTRN	GARBA2:NEAR
; EXTRN	FRETOP:WORD

; EXTRN	SAVFRE:WORD
; EXTRN	IADAHL:NEAR
; EXTRN	TEMP3:WORD,TEMP9:WORD,VARTAB:WORD,ARYTAB:WORD,CHNFLG:WORD
; EXTRN	STREND:WORD
; EXTRN	CURLIN:WORD,SAVSTK:WORD,ENDBUF:WORD,MRGFLG:WORD,MDLFLG:WORD
; EXTRN	CHNLIN:WORD,CMEPTR:WORD,CMSPTR:WORD
if @GW_PASS = 1
; EXTRN	BLTUC:NEAR,DATA:NEAR
; EXTRN	FNDLIN:NEAR,USERR:NEAR,ERSFIN:NEAR,FCERR:NEAR,NOARYS:NEAR
; EXTRN	DEL:NEAR,LINKER:NEAR,SCNLIN:NEAR,FRQINT:NEAR
; This is the code for the CHAIN statement
; The syntax is:
; CHAIN [MERGE]<file name>[,[<line number>][,ALL][,DELETE <range>]]
; The steps required to execute a CHAIN are:

; 1.) Scan arguments

; 2.) Scan program for all COMMON statements and
;       mark specified variables.

; 3.) Squeeze unmarked entries from symbol table.

; 4.) Copy string literals to string space

; 5.) Move all simple variables and arrays into the
;       bottom of string space.

; 6.) Load new program

; 7.) Move variables back down positioned after program.

; 8.) Run program
@CHAIN:
	XOR	AL,AL  ;Assume no MERGE
	MOV	byte [@MRGFLG],AL
	MOV	byte [@MDLFLG],AL  ;Also no MERGE w/ DELETE option
end if
; EXTRN	OPTFLG:WORD,TOPTFG:WORD,OPTVAL:WORD,TOPTVL:WORD
if @GW_PASS = 1
	MOV	AL,byte [@OPTFLG]
	MOV	byte [@TOPTFG],AL  ;SAVE OPTION BASE VALUE
	MOV	AL,byte [@OPTVAL]  ;SAVE OPTION VALUE FOR ARRAY BASE
	MOV	byte [@TOPTVL],AL
	MOV	AL,byte [BX]  ;Get current char
	MOV	DX,@@SMERGE  ;Is it MERGE?
	CMP	AL,DL  ;Test
	JNZ	@FIVEO@_NTCHNM  ;NO
	MOV	byte [@MRGFLG],AL  ;Set MERGE flag
	INC	BX
@FIVEO@_NTCHNM:	DEC	BX  ;Rescan file name
	CALL	@CHRGTR
; EXTRN	PRGFLI:NEAR
	CALL	@PRGFLI  ;Evaluate file name and OPEN it
	PUSH	BX  ;Save text pointer
	MOV	BX,0  ;Get zero
	MOV	[@CHNLIN],BX  ;Assume no CHAIN line #
	POP	BX  ;Restore text pointer
	DEC	BX  ;Back up pointer
	CALL	@CHRGTR  ;Scan char
	JNZ	@FIVEO@_@Q@QL001
	JMP	@FIVEO@_NTCHAL  ;No line number etc.
@FIVEO@_@Q@QL001:
	CALL	@SYNCHR
	DB	44  ;Must be comma
	CMP	AL,((44) and 0FFh)  ;Ommit line # (Use ALL for instance)
	JZ	@FIVEO@_NTLINF  ;YES
	CALL	@FRMEVL  ;Evaluate line # formula
	PUSH	BX  ;Save text poiner
	CALL	@FRQINT  ;Force to int in [H,L]
	MOV	[@CHNLIN],BX  ;Save it for later
	POP	BX  ;Restore text poiner
	DEC	BX  ;Rescan last char
	CALL	@CHRGTR
	JZ	@FIVEO@_NTCHAL  ;No ALL i.e. preserve all vars across CHAIN
@FIVEO@_NTLINF:	CALL	@SYNCHR
	DB	44  ;Should be comma here
	MOV	DX,@@SDELETE  ;Test for DELETE option
	CMP	AL,DL  ;Is it?
	JZ	@FIVEO@_CHMWDL  ;Yes
	CALL	@SYNCHR
	DB	"A"  ;Check for "ALL"
	CALL	@SYNCHR
	DB	"L"
	CALL	@SYNCHR
	DB	"L"
	JNZ	@FIVEO@_@Q@QL002
	JMP	@FIVEO@_DNCMDA  ;Goto step 3
@FIVEO@_@Q@QL002:
	CALL	@SYNCHR
	DB	44  ;Force comma to appear
	CMP	AL,DL  ;Must be DELETE
	JZ	@FIVEO@_@Q@QL003
	JMP	@SNERR  ;No, give error
@FIVEO@_@Q@QL003:
	OR	AL,AL  ;Flag to goto DNCMDA
@FIVEO@_CHMWDL:	PUSHF  ;Save ALL flag
	MOV	byte [@MDLFLG],AL  ;Set MERGE w/ DELETE
	CALL	@CHRGTR  ;Get char after comma
	CALL	@SCNLIN  ;Scan line range
; EXTRN	DEPTR:NEAR
	PUSH	CX
	CALL	@DEPTR  ;Change pointers back to numbers
	POP	CX
	POP	DX  ;Pop max line off stack
	PUSH	CX  ;Save pointer to start of 1st line
	MOV	BX,CX  ;Save pointer to start line
	MOV	[@CMSPTR],BX
	CALL	@FNDLIN  ;Find the last line
	JAE	@FIVEO@_FCERRG  ;Must have exact match on end of range
	MOV	DH,BH  ;[D,E] =  pointer at the start of the line
	MOV	DL,BL  ;beyond the last line in the range
	MOV	[@CMEPTR],BX  ;Save pointer to end line
	POP	BX  ;Get back pointer to start of range
	CMP	BX,DX  ;Make sure the start comes before the end
@FIVEO@_FCERRG:	JNAE	@FIVEO@_@Q@QL004
	JMP	@FCERR  ;If not, "Illegal function call"
@FIVEO@_@Q@QL004:
	POPF  ;Flag that says whether to go to DNCMDA
	JZ	@FIVEO@_@Q@QL005
	JMP	@FIVEO@_DNCMDA  ;"ALL" option was present
@FIVEO@_@Q@QL005:
@FIVEO@_NTCHAL:	MOV	BX,[@CURLIN]  ;Save current line number on stack
	PUSH	BX
	MOV	BX,[@TXTTAB]  ;Start searching for COMMONs at program start
	DEC	BX  ;Compensate for next instr
@FIVEO@_CLPSC1:	INC	BX  ;Look at first char of next line
@FIVEO@_CLPSCN:	MOV	AL,byte [BX]  ;Get char from program
	INC	BX
	OR	AL,byte [BX]  ;Are we pointing to program end?
	JNZ	@FIVEO@_@Q@QL006
	JMP	@FIVEO@_CLPFIN  ;Yes
@FIVEO@_@Q@QL006:
	INC	BX
	MOV	DX,[BX]  ;Get line # in [D,E]
	INC	BX
	MOV	[@CURLIN],DX  ;Save current line # in CURLIN for errors
@FIVEO@_CSTSCN:	CALL	@CHRGTR  ;Get statment type
@FIVEO@_AFTCOM:	OR	AL,AL
	JZ	@FIVEO@_CLPSC1  ;EOL Scan next one
	CMP	AL,((":") and 0FFh)  ;Are we looking at colon
	JZ	@FIVEO@_CSTSCN  ;Yes, get next statement
	CMP	AL,((254) and 0FFh)  ;COMMONs prceeded by 254
	JNZ	@FIVEO@_NOCOMM  ;not one
	INC	BX  ;move ahead
	MOV	AL,byte [BX]
	MOV	DX,@@SCOMMON  ;Test for COMMON, avoid byte externals
	CMP	AL,DL  ;Is it a COMMON?
	JZ	@FIVEO@_DOCOMM  ;Yes, handle it
	DEC	BX  ;Back up the pointer.
@FIVEO@_NOCOMM:	CALL	@CHRGTR  ;Get first char of statement
	CALL	@DATA  ;Skip over statement
	DEC	BX  ;Back up to rescan terminator
	JMP	@FIVEO@_CSTSCN  ;Scan next one
@FIVEO@_DOCOMM:	CALL	@CHRGTR  ;Get thing after COMMON
	JZ	@FIVEO@_AFTCOM  ;Get next thing
@FIVEO@_NXTCOM:	PUSH	BX  ;Save text pointer
	MOV	AL,((1) and 0FFh)  ;Call PTRGET to search for array
	MOV	byte [@SUBFLG],AL
	CALL	@PTRGTN  ;This subroutine in F3 scans variables
	JZ	@FIVEO@_FNDAAY  ;Found array
	MOV	AL,CH  ;Try finding array with COMMON bit set
	OR	AL,((128) and 0FFh)
	MOV	CH,AL
	XOR	AL,AL  ;Set zero CC
	CALL	@ERSFIN  ;Search array table
	MOV	AL,((0) and 0FFh)  ;Clear SUBFLG in all cases
	MOV	byte [@SUBFLG],AL
	JNZ	@FIVEO@_NTFN2T  ;Not found, try simple
	MOV	AL,byte [BX]  ;Get terminator, should be "("
	CMP	AL,(("(") and 0FFh)  ;Test
	JNZ	@FIVEO@_SCNSMP  ;Must be simple then
	POPF  ;Get rid of saved text pointer
	JMP	@FIVEO@_COMADY  ;Already was COMMON, ignore it
@FIVEO@_NTFN2T:	MOV	AL,byte [BX]  ;Get terminator
	CMP	AL,(("(") and 0FFh)  ;Array specifier?
	POP	DX  ;(DE:=saved text pointer.)
	JZ	@FIVEO@_SKPCOM  ;Yes, undefined array - just skip it.
	PUSH	DX  ;No, resave pointer to start of variable
@FIVEO@_SCNSMP:	POP	BX  ;Rescan variable name for start
	CALL	@PTRGTN  ;Evaluate as simple
	OR	DX,DX  ;If var not found, [D,E]=0
	JNZ	@FIVEO@_COMFNS  ;Found it
	MOV	AL,CH  ;Try to find in COMMON
	OR	AL,((128) and 0FFh)  ;Set COMMON bit
	MOV	CH,AL
	MOV	DX,@FIVEO@_COMPT2  ;push on return address
	PUSH	DX
	MOV	DX,@PTRGTR  ;address to common return point
	PUSH	DX
	MOV	AL,byte [@VALTYP]  ;Must have VALTYP in [D]
	MOV	DH,AL
	JMP	@NOARYS  ;Search symbol table
@FIVEO@_COMPT2:	OR	DX,DX  ;Found?
	JZ	@FIVEO@_SKPCOM  ;No, just skip over this variable.
@FIVEO@_COMFNS:	PUSH	BX  ;Save text pointer
	MOV	CH,DH  ;Get pointer to var in [B,C]
	MOV	CL,DL
	MOV	BX,@FIVEO@_BCKUCM  ;Loop back here
	PUSH	BX
@FIVEO@_CBAKBL:	DEC	CX  ;Point at first char of rest
@FIVEO@_LPBKNC:	MOV	SI,CX
	MOV	AL,[SI]  ;Back up until plus byte
	DEC	CX
	OR	AL,AL
	JNS	@FIVEO@_@Q@QL007
	JMP	@FIVEO@_LPBKNC
@FIVEO@_@Q@QL007:
;Now point to 2nd char of var name
	MOV	SI,CX
	MOV	AL,[SI]  ;set COMMON bit
	OR	AL,((128) and 0FFh)
	MOV	DI,CX
	STOSB
	RET  ;done
@FIVEO@_FNDAAY:	MOV	byte [@SUBFLG],AL  ;Array found, clear SUBFLG
	MOV	AL,byte [BX]  ;Make sure really array spec
	CMP	AL,(("(") and 0FFh)  ;Really an array?
	JNZ	@FIVEO@_SCNSMP  ;No, scan as simp
	POP	SI  ;XTHL
	XCHG	SI,BX
	PUSH	SI  ;Save text pointer, get rid of saved text pointer
@FIVEO@_BAKCOM:	DEC	CX  ;Point at last char of name extension
	DEC	CX
	CALL	@FIVEO@_CBAKBL  ;Back up before variable and mark as COMMON
@FIVEO@_BCKUCM:	POP	BX  ;Restore text pointer
@FIVEO@_SKPCOM:	DEC	BX  ;Rescan terminator
	CALL	@CHRGTR
	JNZ	@FIVEO@_@Q@QL008
	JMP	@FIVEO@_AFTCOM  ;End of COMMON statement
@FIVEO@_@Q@QL008:
	CMP	AL,(("(") and 0FFh)  ;End of COMMON array spec?
	JNZ	@FIVEO@_CHKCST  ;No, should be comma
@FIVEO@_COMADY:	PUSH	BX
	CALL	@CHRGTR  ;Fetch char after paren
	CMP	AL,((")") and 0FFh)
	JZ	@FIVEO@_COMRPN  ;Only right paren follows
	POP	BX
; EXTRN	EVAL:NEAR
	CALL	@EVAL  ;Possible number of dimensions(compiler compatible)
	CALL	@GETYPR
	JNZ	@FIVEO@_@Q@QL009
	JMP	@FCERR  ;Dimensions argument cannot be string
@FIVEO@_@Q@QL009:
	JMP	@FIVEO@_COMRP1
@FIVEO@_COMRPN:	POP	DX
@FIVEO@_COMRP1:	CALL	@SYNCHR
	DB	")"  ;Right paren should follow
	JNZ	@FIVEO@_@Q@QL010
	JMP	@FIVEO@_AFTCOM  ;End of COMMON
@FIVEO@_@Q@QL010:
@FIVEO@_CHKCST:	CALL	@SYNCHR
	DB	44  ;Force comma to appear here
	JMP	@FIVEO@_NXTCOM  ;Get next COMMON variable
; Step 3 - Squeeze..
@FIVEO@_CLPFIN:	POP	BX  ;Restore previous CURLIN
	MOV	[@CURLIN],BX
	MOV	DX,[@ARYTAB]  ;End of simple var squeeze to [D,E]
	MOV	BX,[@VARTAB]  ;Start of simps
@FIVEO@_CLPSLP:	CMP	BX,DX  ;Are we done?
	JZ	@FIVEO@_DNCMDS  ;Yes done, with simps
	PUSH	BX  ;Save where this simp is
	MOV	CL,byte [BX]  ;Get VALTYP
	INC	BX
	INC	BX
	MOV	AL,byte [BX]  ;Get COMMON bit
	OR	AL,AL  ;Set minus if COMMON
	PUSHF  ;Save indicator
	AND	AL,((127) and 0FFh)  ;Clear COMMON bit
	MOV	byte [BX],AL  ;Save back
	INC	BX
	CALL	@IADAHL  ;Skip over rest of var name
	MOV	CH,((0) and 0FFh)  ;Skip VALTYP bytes
	ADD	BX,CX
	POPF  ;Get indicator whether to delete
	POP	CX  ;Pointer to where var started
	JNS	@FIVEO@_@Q@QL011
	JMP	@FIVEO@_CLPSLP
@FIVEO@_@Q@QL011:
	PUSH	CX  ;This is where we will resume scanning vars later
	CALL	@FIVEO@_VARDLS  ;Delete variable
	MOV	BX,[@ARYTAB]  ;Now correct ARYTAB by # of bytes deleted
	ADD	BX,DX  ;Add negative difference between old and new
	MOV	[@ARYTAB],BX  ;Save new ARYTAB
	XCHG	BX,DX  ;To [D,E]
	POP	BX  ;Get current place back in [H,L]
	JMP	@FIVEO@_CLPSLP
@FIVEO@_VARDLS:	XCHG	BX,DX  ;Point to where var ends
@FIVEO@_VARDL1:	MOV	BX,[@STREND]  ;One beyond last byte to move
@FIVEO@_DLSVLP:	CMP	BX,DX  ;Done?
	MOV	SI,DX
	MOV	AL,[SI]  ;Grab byte
	MOV	DI,CX
	STOSB  ;Move down
	LAHF
	INC	DX  ;Increment pointers
	SAHF
	LAHF
	INC	CX
	SAHF
	JNZ	@FIVEO@_DLSVLP
	MOV	AL,CL  ;Get difference between old and new
	SUB	AL,BL  ;Into [D,E] ([D,E]=[B,C]-[H,L])
	MOV	DL,AL
	MOV	AL,CH
	SBB	AL,BH
	MOV	DH,AL
	DEC	DX  ;Correct # of bytes
	DEC	CX  ;Moved one too far
	MOV	BX,CX  ;Get new STREND [H,L]
	MOV	[@STREND],BX  ;Store it
	RET
@FIVEO@_DNCMDS:	MOV	DX,[@STREND]  ;Limit of array search
@FIVEO@_CLPAKP:	CMP	BX,DX  ;Done?
	JZ	@FIVEO@_DNCMDA  ;Yes
	PUSH	BX  ;Save pointer to VALTYP
	INC	BX  ;Move down to COMMON bit
	INC	BX
	MOV	AL,byte [BX]  ;Get it
	OR	AL,AL  ;Set CC's
	PUSHF  ;Save COMMON indicator
	AND	AL,((127) and 0FFh)  ;Clear COMMON bit
	MOV	byte [BX],AL  ;Save back
	INC	BX  ;Point to length of array
	CALL	@IADAHL  ;Add length of var name
	MOV	CL,byte [BX]  ;Get length of array in [B,C]
	INC	BX
	MOV	CH,byte [BX]
	INC	BX
	ADD	BX,CX  ;[H,L] now points after array
	POPF  ;Get back COMMON indicator
	POP	CX  ;Get pointer to start of array
	JNS	@FIVEO@_@Q@QL012
	JMP	@FIVEO@_CLPAKP  ;COMMON, dont delete!
@FIVEO@_@Q@QL012:
	PUSH	CX  ;Save so we can resume
	CALL	@FIVEO@_VARDLS  ;Delete the array
	XCHG	BX,DX  ;Returns with STREND in HL, so put in DE
	POP	BX  ;Get back pointer to the next array
	JMP	@FIVEO@_CLPAKP  ;Check next array
; Step 4 - Copy literals into string space
; This code is very similar to the string garbage collect code
; If BIGSTR is on, we also have to fix up the string back pointers.
@FIVEO@_DNCMDA:
	MOV	BX,[@VARTAB]  ;Look at simple strings
@FIVEO@_CSVAR:	MOV	DX,[@ARYTAB]  ;Limit of search to [D,E]
	CMP	BX,DX  ;Done?
	JZ	@FIVEO@_CAYVAR  ;Yes
	CALL	@SKPNAM  ;Skip name, returns Z if was a string
	JNZ	@FIVEO@_CSKPVA  ;Skip this var, not string
	CALL	@FIVEO@_CDVARS  ;Copy this guy into string space if nesc
	XOR	AL,AL  ;CDVARS has already incremented [H,L]
@FIVEO@_CSKPVA:
	MOV	DL,AL
	MOV	DH,((0) and 0FFh)  ;Add length of VALTYP
	ADD	BX,DX
	JMP	@FIVEO@_CSVAR
@FIVEO@_CAYVA2:	POP	CX  ;Adjust stack
@FIVEO@_CAYVAR:	MOV	DX,[@STREND]  ;New limit of search
	CMP	BX,DX  ;Done?
	JZ	@FIVEO@_DNCCLS  ;Yes
	CALL	@SKPNAM  ;Skip over name
	PUSH	AX  ;Save VALTYP
	MOV	CL,byte [BX]  ;Get length of array
	INC	BX
	MOV	CH,byte [BX]  ;Into [B,C]
	INC	BX
	POP	AX  ;Get back VALTYP
	PUSH	BX  ;Save pointer to array element
	ADD	BX,CX  ;Point after array
	CMP	AL,((3) and 0FFh)  ;String array?
	JNZ	@FIVEO@_CAYVA2  ;No, look at next one
	MOV	[@TEMP3],BX  ;Save pointer to end of array
	POP	BX  ;Get back pointer to array start
	MOV	CL,byte [BX]  ;Pick up number of DIMs
	MOV	CH,((0) and 0FFh)  ;Make double with high zero
	ADD	BX,CX  ;Go past DIMS
	ADD	BX,CX
	INC	BX  ;One more to account for # of DIMs
@FIVEO@_CAYSTR:	MOV	DX,[@TEMP3]  ;Get end of array
	CMP	BX,DX  ;See if at end of array
	JZ	@FIVEO@_CAYVAR  ;Get next array
	MOV	CX,@FIVEO@_CAYSTR  ;Do next str in array
	PUSH	CX  ;Save branch address on stack
@FIVEO@_CDVARS:
	MOV	AL,byte [BX]  ;Get length of array entry
	INC	BX  ;Also pick up pointer into [D,E]
	MOV	DX,[BX]  ;Get data pointer
	INC	BX
	INC	BX
	OR	AL,AL  ;Set CC's on length
	JNZ	$+3
	RET  ;Ignore null strings
	PUSH	BX  ;Save where we are
	MOV	BX,[@VARTAB]  ;Is string in program text or disk buffers?
	CMP	BX,DX  ;Compare
	POP	BX  ;Restore where we are
	JNB	$+3
	RET  ;No, must be in string space
	PUSH	BX  ;save where we are again.
	MOV	BX,[@TXTTAB]  ;is it in buffers?
	CMP	BX,DX  ;test
	POP	BX  ;Restore where we are
	JNAE	$+3
	RET  ;in buffers, do nothing
	PUSH	BX  ;Save where we are for nth time
	DEC	BX  ;Point to start of descriptor
	DEC	BX
	DEC	BX
	PUSH	BX  ;Save pointer to start
	CALL	@STRCPY  ;Copy string into DSCTMP
	POP	BX  ;Destination in [H,L], source in [D,E]
	MOV	CH,((3) and 0FFh)  ;# of bytes to move
	CALL	@MOVE1  ;Move em
	POP	BX  ;Where we are
	RET
; Step 5 - Move stuff up into string space!
@FIVEO@_DNCCLS:
	CALL	@GARBA2  ;Get rid of unused strings
	MOV	BX,[@STREND]  ;Load end of vars
	MOV	CX,BX  ;Into [B,C]
	MOV	DX,[@VARTAB]  ;Start of simps into [D,E]
	MOV	BX,[@ARYTAB]
	SUB	BX,DX  ;Get length of simps in [H,L]
	MOV	[@TEMP9],BX  ;Save here
	MOV	BX,[@FRETOP]  ;Destination of high byte
	MOV	[@SAVFRE],BX  ;Save FRETOP to restore later
	CALL	@BLTUC  ;Move stuff up
	MOV	BX,CX  ;Now adjust top of memory below saved vars
	DEC	BX  ;One lower to be sure
	MOV	[@FRETOP],BX  ;Update FRETOP to reflect new value
	MOV	AL,byte [@MDLFLG]  ;MERGE w/ DELETE?
	OR	AL,AL  ;Test
	JZ	@FIVEO@_NTMDLT  ;No
	MOV	BX,[@CMSPTR]  ;Start of lines to delete
	MOV	CX,BX  ;Into [B,C]
	MOV	BX,[@CMEPTR]  ;End of lines to delete
	CALL	@DEL  ;Delete the lines
	MOV	[@ARYTAB],BX  ;***also set up ARYTAB and STREND
	MOV	[@STREND],BX  ;in case we get error in CHAIN
;because of file lookup and then have to
;look at variables later (shouldnt be any)
;***PGA 7/7/81
	CALL	@LINKER  ;Re-link lines just in case
; Step 6 - load new program
@FIVEO@_NTMDLT:	MOV	AL,((1) and 0FFh)  ;Set CHAIN flag
	MOV	byte [@CHNFLG],AL
; EXTRN	CHNENT:NEAR,OKGETM:NEAR
	MOV	AL,byte [@MRGFLG]  ;MERGEing?
	OR	AL,AL  ;Set cc'S
	JZ	@FIVEO@_@Q@QL013
	JMP	@OKGETM  ;Do MERGE
@FIVEO@_@Q@QL013:
	JMP	@CHNENT  ;Jump to LOAD code
; Step 7 - Move stuff back down
; PUBLIC	CHNRET
@CHNRET:
	MOV	AL,byte [@TOPTVL]
	MOV	byte [@OPTVAL],AL  ;RESTORE IOTION BASE VALUE
	MOV	AL,byte [@TOPTFG]
	MOV	byte [@OPTFLG],AL  ;LRESTORE OPTION FLG
	XOR	AL,AL  ;Clear CHAIN, MERGE flags
	MOV	byte [@CHNFLG],AL
	MOV	byte [@MRGFLG],AL
	MOV	BX,[@VARTAB]  ;Get current VARTAB
	MOV	CX,BX  ;Into [B,C]
	MOV	BX,[@TEMP9]  ;Get length of simps
	ADD	BX,CX  ;Add to present VARTAB to get new ARYTAB
	MOV	[@ARYTAB],BX
	MOV	BX,[@FRETOP]  ;Where to start moving
	INC	BX  ;One higher
	XCHG	BX,DX  ;Into [D,E]
	MOV	BX,[@SAVFRE]  ;Last byte to move
	MOV	[@FRETOP],BX  ;Restore FRETOP from this
@FIVEO@_MVBKVR:	CMP	BX,DX  ;Done?
	MOV	SI,DX
	MOV	AL,[SI]  ;Move byte down
	MOV	DI,CX
	STOSB
	LAHF
	INC	DX  ;Increment pointers
	SAHF
	LAHF
	INC	CX
	SAHF
	JNZ	@FIVEO@_MVBKVR
	DEC	CX  ;Point to last var byte
	MOV	BX,CX  ;[H,L]=last var byte
	MOV	[@STREND],BX  ;This is new end
end if
; EXTRN	NLONLY:WORD
if @GW_PASS = 1
	XOR	AL,AL
	MOV	byte [@NLONLY],AL  ;allow all files to be closed
; EXTRN	FINPRT:NEAR
	CALL	@FINPRT  ;close file zero and reset PTRFIL to 0
	XOR	AL,AL
	CALL	@RESTORE  ;Make sure DATA is valid by doing RESTORE
	MOV	DX,[@CHNLIN]  ;Get CHAIN line # in [D,E]
	MOV	BX,[@TXTTAB]  ;Get prog start in [H,L]
	DEC	BX  ;Point at zero before program

	OR	DX,DX  ;line number zero?
	JNZ	@FIVEO@_@Q@QL014
	JMP	@NEWSTT  ;line #=0, go...
@FIVEO@_@Q@QL014:
	CALL	@FNDLIN  ;Try to find destination line
	JNAE	@FIVEO@_@Q@QL015
	JMP	@USERR  ;Not there...
@FIVEO@_@Q@QL015:
	DEC	CX  ;Point to zero on previous line
	MOV	BX,CX  ;Make text pointer for NEWSTT
	JMP	@NEWSTT  ;Bye...

; Convenience routine to skip a variable's name pointed to by HL.
; Returns VALTYP in A with the zero flag set if it is a string.

; PUBLIC	SKPNAM
@SKPNAM:
	MOV	AL,byte [BX]  ;Get VALTYP
	INC	BX  ;Point to length of long var name
	INC	BX
	INC	BX
	PUSH	AX  ;Save VALTYP
	CALL	@IADAHL  ;Move past long variable name
	POP	AX  ;Get back VALTYP
	CMP	AL,((3) and 0FFh)  ;String?
	RET

@COMMON:
	JMP	@DATA

; SUBTTL  WRITE
; EXTRN	FINPRT:NEAR
; EXTRN	FOUT:NEAR,STRLIT:NEAR,STRPRT:NEAR,OUTDO:NEAR
end if
; EXTRN	FACLO:WORD
if @GW_PASS = 1
; PUBLIC	WRITE
@WRITE:
; EXTRN	FILGET:NEAR
	MOV	CL,((@MD_SQO) and 0FFh)  ;Setup output file
	CALL	@FILGET
@FIVEO@_WRTCHR:	DEC	BX
	CALL	@CHRGTR  ;Get another character
	JZ	@FIVEO@_WRTFIN  ;Done with WRITE
@FIVEO@_WRTMLP:	CALL	@FRMEVL  ;Evaluate formula
	PUSH	BX  ;Save the text pointer
	CALL	@GETYPR  ;See if we have a string
	JZ	@FIVEO@_WRTSTR  ;We do
	CALL	@FOUT  ;Convert to a string
	CALL	@STRLIT  ;Literalize string
	MOV	BX,[@FACLO]  ;Get pointer to string
	INC	BX  ;Point to address field
	MOV	DX,[BX]
	INC	BX
	MOV	SI,DX
	MOV	AL,[SI]  ;Is number positive?
	CMP	AL,((" ") and 0FFh)  ;Test
	JNZ	@FIVEO@_WRTNEG  ;No, must be negative
	INC	DX
	MOV	byte [BX],DH
	DEC	BX
	MOV	byte [BX],DL
	DEC	BX
	DEC	byte [BX]  ;Adjust length of string (length.LT.255 so OK)
@FIVEO@_WRTNEG:	CALL	@STRPRT  ;Print the number
@FIVEO@_NXTWRV:	POP	BX  ;Get back text pointer
	DEC	BX  ;Back up pointer
	CALL	@CHRGTR  ;Get next char
	JZ	@FIVEO@_WRTFIN  ;end
	CMP	AL,((59) and 0FFh)  ;Semicolon?
	JZ	@FIVEO@_WASEMI  ;Was one
	CALL	@SYNCHR
	DB	44  ;Only possib left is comma
	DEC	BX  ;to compensate for later CHRGET
@FIVEO@_WASEMI:	CALL	@CHRGTR  ;Fetch next char
	MOV	AL,((44) and 0FFh)  ;put out comma
	CALL	@OUTDO
	JMP	@FIVEO@_WRTMLP  ;Back for more
@FIVEO@_WRTSTR:	MOV	AL,((34) and 0FFh)  ;put out double quote
	CALL	@OUTDO  ;Send it
	CALL	@STRPRT  ;print the string
	MOV	AL,((34) and 0FFh)  ;Put out another double quote
	CALL	@OUTDO  ;Send it
	JMP	@FIVEO@_NXTWRV  ;Get next value
@FIVEO@_WRTFIN:
; EXTRN	CMPFBC:NEAR
end if
; EXTRN	PTRFIL:WORD
if @GW_PASS = 1
	PUSH	BX  ;Save text pointer
	MOV	BX,[@PTRFIL]  ;See if disk file
	MOV	AL,BH
	OR	AL,BL
	JZ	@FIVEO@_NTRNDW  ;No
	PUSH	BX  ;Save FDB pointer
	MOV	CX,@F_DEV
	ADD	BX,CX  ;HL points to Device Entry in FDB
	MOV	AL,byte [BX]  ;[A]=device id
	OR	AL,AL  ;if disk [A] will be 0..n
	POP	BX
	JNS	@FIVEO@_@Q@QL016
	JMP	@FIVEO@_NTRNDW  ;branch if special device ([A] is negative)
@FIVEO@_@Q@QL016:
	PUSH	BX
	MOV	CX,@F_MODE
	ADD	BX,CX  ;HL points to File Mode Byte in FDB
	MOV	AL,byte [BX]  ;[A]=file mode
	POP	BX  ;Restore FDB pointer
	CMP	AL,((@MD_RND) and 0FFh)  ;Random?
	JNZ	@FIVEO@_NTRNDW  ;NO
	CALL	@CMPFBC  ;See how many bytes left
	MOV	AL,BL  ;do subtract
	SUB	AL,DL
	MOV	BL,AL
	MOV	AL,BH
	SBB	AL,DH
	MOV	BH,AL
	@FIVEO@_CRLFSQ=2  ;Number of bytes in CR/LF sequence
	MOV	DX,0-@FIVEO@_CRLFSQ  ;Subtract bytes in <cr>
	LAHF
	ADD	BX,DX
	RCR	SI,1
	SAHF
	RCL	SI,1
	JAE	@FIVEO@_NTRNDW  ;Not enough, give error eventually
@FIVEO@_NXTWSP:	MOV	AL,((" ") and 0FFh)  ;Put out spaces
	CALL	@OUTDO  ;Send space
	DEC	BX  ;Count down
	MOV	AL,BH  ;Count down
	OR	AL,BL
	JNZ	@FIVEO@_NXTWSP
@FIVEO@_NTRNDW:	POP	BX  ;Restore [H,L]
	CALL	@CRDO  ;Do crlf
	JMP	@FINPRT
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
