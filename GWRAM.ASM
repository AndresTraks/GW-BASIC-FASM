; [ This translation created 10-Feb-83 by Version 4.3 ]

if @GW_PASS = 1

include 'OEM.H'

; TITLE   GWRAM - GW BASIC OEM Independent RAM Declarations

; COMMENT	*
;         --------- --- ---- -- ---------
;         COPYRIGHT (C) 1981 BY MICROSOFT
;         --------- --- ---- -- ---------
;         *

include 'GIO86U'

@GWRAM@_MUSIC=@PLAYSW OR @BEEPSW
@GWRAM@_GRPMCL=1
@GWRAM@_NMPAGE=1

; PUBLIC	HEDING,$DATE,CERMSG

	@GWRAM@_QUOTE=34
	@GWRAM@_CR=13

; SUBTTL Sign on message and other data to be discarded after INIT

@HEDING:	@ACRLF
	DB	"(C) Copyright Microsoft 1982"
@@SDATE:	DB	"         "  ;$DATE
	@ACRLF
	DB	0  ;Terminate previous string.

@CERMSG:	@ACRLF  ;Command line error message
	DB	"Error detected in command line"
	@ACRLF
	DB	0

end if
if @GW_PASS = 2

; ASM86 version don't need to fool around with offsets into OEMBAS,
; as the linker can preload segments with data.  Thus, the R macros
; need only define the label and a size if the variable is not intitalized.

macro @R1 NAME,SIZE {
  @Q=@Q+SIZE
  @GWRAM@_QDS=@GWRAM@_QDS+SIZE
  NAME = $ - 1
  if SIZE
  DB	SIZE dup (?)
  end if
}

macro @R NAME,SIZE {
  @Q=@Q+SIZE
  @GWRAM@_QDS=@GWRAM@_QDS+SIZE
  label NAME word
  if SIZE
  DB	SIZE dup (?)
  end if
}

macro @RINIT NAME,SIZE {
  label NAME word
  @QQ=NAME-MOVDAT-@Q
  if @QQ
  display "FATAL @RINIT @GWRAM@_ERROR"
  end if
  @Q=@Q+SIZE
  @GWRAM@_QDS=@GWRAM@_QDS+SIZE
}

macro @ACRLF {
  DB	13
  DB	10
}

	@Q=0
	@GWRAM@_QDS=0
	@RINIT	MOVDAT,0
	@RINIT	@FREFLG,1  ;Flag to print BYTES FREE message
	DB	0
	@RINIT	@INITFG,1  ;Initialization complete flag
	DB	0  ;INITFG
	@RINIT	@ESCFLG,1  ;Escape seq. in progress flag
	DB	0
	@RINIT	@TWOBYT,1  ;Save location for collecting two byte chars
	DB	0

; Keyboard Support Variables

	@RINIT	@STRTAB,16*@NMKEYF  ;SOFTKEY table

;** The following line is used by a source maint. tool - do not remove
;** (OEM FUNCTION KEY DEFINITIONS) **************

	DB	"LIST"  ;FUNCTION 1
	DB	0
	DB	11 dup (?)
	DB	"RUN"  ;FUNCTION 2
	DB	@GWRAM@_CR,0
	DB	11 dup (?)
	DB	"LOAD"  ;FUNCTION 3
	DB	@GWRAM@_QUOTE,0
	DB	10 dup (?)
	DB	"SAVE"  ;FUNCTION 4
	DB	@GWRAM@_QUOTE,0
	DB	10 dup (?)
	DB	"CONT"  ;FUNCTION 5
	DB	@GWRAM@_CR,0
	DB	10 dup (?)
	DB	","  ;FUNCTION 6
	DB	@GWRAM@_QUOTE
	DB	"LPT1:"
	DB	@GWRAM@_QUOTE,0
	DB	7 dup (?)
	DB	"TRON"  ;FUNCTION 7
	DB	@GWRAM@_CR,0
	DB	10 dup (?)
	DB	"TROFF"  ;FUNCTION 8
	DB	@GWRAM@_CR,0
	DB	9 dup (?)
	DB	"KEY"  ;FUNCTION 9
	DB	0
	DB	12 dup (?)
	DB	"SCREEN 0,0,0"  ;FUNCTION :
	DB	@GWRAM@_CR,0
	DB	2 dup (?)
;**(END OF DEFINITIONS) *************************
;The preceding line is used by a source maint. tool - do not remove.

	@RINIT	ENDTAB,0
	@GWRAM@_DIST=ENDTAB-@STRTAB-(16*@NMKEYF)
if @GWRAM@_DIST
end if

	@RINIT	@CMDOFF,2  ;Index into ESCBUFF or STRTAB
	DW	0
	@RINIT	@FKCNUM,1  ;Number of chars. per fun. key to display
	DB	6  ; on the last line
	@RINIT	ACTPAG,1  ;Active page
	DB	1 dup (?)
	@RINIT	@F_EDPG,1  ; Flag - =^O377 indicates program statement edit
	DB	0
	@RINIT	@SEMFLG,1  ; Flag - non-zero indicates INPUT; statement(no
	DB	0  ;        CRLF at end of input)
	@RINIT	@F_CRET,1  ;Zero indicates last character output was CR
	DB	255
	@RINIT	@F_INST,1  ; Flag - =^O377 indicates insert mode
	DB	0
	@RINIT	@F_EDIT,1  ; Flag - non-zero indicates INLIN active
	DB	0

;MACLNG variables for DRAW

	@RINIT	@DRWSCL,1  ;DRAW: SCALE
	DB	0  ;DRAW POS,2 ling factor
	@RINIT	@DRWFLG,1  ;OPTION FLAGS
	DB	0  ;DRAW flag
	@RINIT	@DRWANG,1  ;DRAW "ANGLE" (0..3)
	DB	0  ;DRAW translation angle
	@RINIT	@MCLPTR,2  ;MAC LANG PTR
	DB	2 dup (?)  ;Other DRAW vars. not initialized
	@RINIT	@MCLLEN,1  ;STRING LENGTH
	DB	1 dup (?)
	@RINIT	@MCLTAB,2  ;PTR TO COMMAND TABLE
	DB	2 dup (?)
;OEM Independent Music Locations
	@RINIT	@OCTAVE,1  ;PLAY: OCTAVE
	DB	4  ;OCTAVE
	@RINIT	@BEATS,1  ;BEATS
	DB	120  ;BEATS (default = 120 L4 notes per minute)
	@RINIT	@NOTELN,1  ;NOTE LENGTH
	DB	4  ;NOTELN
	@RINIT	@NOTE1L,1  ;One (current) Note Length
	DB	4  ;NOTE1L
	@RINIT	@MSCALE,1  ;Note Length Scale Factor (ML,MN,MS)
	DB	3  ;MSCALE (default = 7/8 time)
	@RINIT	@MMODE,1  ;Music Mode (Foreground/Background)
	DB	0  ;MMODE (default = forground)
	@RINIT	SNDTIC,1  ;Sound/Clock tick modulo counter
	DB	1 dup (?)
	@RINIT	SNDBAS,2  ;Base addr of Sound Queue Cells
	DB	2 dup (?)
	@RINIT	SNDOUT,2  ;Base addr of Sound Queue Buffer
	DB	2 dup (?)
; SUBTTL  Page Dependent OEM Independent Variables

; Page Dependent variables arranged as follows:
; Variables which are initialized by block move are declared using the RINIT
; macro.  These declarations are made within the definition of macro PDIRAM
; (page dependent initialized RAM).
; Variables which are not initialized by block move are declared using the R
; macro.  These declarations are made within the definition of macro PDURAM
; (page dependent uninitialized RAM).
; The memory map for multi page page dependent variables is as follows:
;--------------------------------------------------------------------------

; CS: resident initialization values are copied to DS: by the same copy
;     as usual.

;--------------------------------------------------------------------------

; DS:PDIDS1:              ;Beginning of ini value block copied from CS:
;                         ; This block is used to initialize pages at
;                         ; various times during execution.

;           (initialization values set by CS: to DS: block move)

; DS:FPDVAR:              ;First page dependent variable

;           (first come vars initializable by block move from PDIDS1.
;            Then come all other vars. which are page dependent.)

; DS:LPDVAR:              ;Address of end of variables for active page
;                         ; The variables between FPDVAR and LPDVAL are the
;                         ; ones that are labeled as per RINIT and R macros.

; (Lastly comes (LPDVAR-FPDVAR)*NMPAGE RAM locations used to store the state
;   of each page while it is not active.)

;In systems where only one page is available label FPDVAL is made to
; coincide with label PDIDS1 and there are no locations reserved to store
; the state of the page while it is not active.

; PUBLIC	PDIDS1
; PUBLIC	FPDVAR,LPDVAR

macro @PDIRAM {
  @RINIT	@KEYSW,1
  DB	0
}

macro @PDURAM {
  @R	@LINLEN,1
  @R	@LINCNT,1
  @R	@CRTWID,1
  @R	@WDOTOP,1
  @R	@WDOBOT,1
  @R	@WDOLFT,1
  @R	@WDORGT,1
  @R	@WDTFLG,1
  @R	@LINTTB,2*(@NMLINE+1)
  @R	@TRMCUR,2
  @R	@FSTLIN,1
  @R	@FSTCOL,1
  @R	@LSTLIN,1
  @R	@LSTCOL,1
  @R	@CSRY,1
  @R	@CSRX,1
}

macro @RINIT NAME,SIZE {
  @GWRAM@_QDS=@GWRAM@_QDS+SIZE
}

	@GWRAM@_QDS=@Q

	@R	@PDIDS1,0  ;Page Dependent DS: init. value block start
	@PDIRAM  ;Insert Ini values
	@FPDVAR=@PDIDS1  ;INI area and First Page Dependent VARiable
; are overlaid in this case
macro @RINIT NAME,SIZE {
  label NAME word
  @QQ=NAME-MOVDAT-@GWRAM@_QDS
  if @QQ
  display "FATAL @RINIT @GWRAM@_ERROR"
  end if
  @Q=@Q+SIZE
  @GWRAM@_QDS=@GWRAM@_QDS+SIZE
}

;Although RINIT is used subsequently there are no more CS: RAM locations
; to declare.   The RINIT will be used for DS: declaration only

; Now declare the labeled DS: for 1 page systems.  This area is the
;       labeled active page for multi-page systmes

	@PDIRAM  ;Declare Active Page Inited RAM

	@PDURAM  ;Declare Active Page Uninit RAM
	@R	@LPDVAR,0  ;End of active page vars in DS:

macro @RINIT NAME,SIZE {
  if SIZE
  DB	SIZE dup (?)
  @GWRAM@_QDS=@GWRAM@_QDS+SIZE
  end if
}
macro @R NAME,SIZE {
  if SIZE
  DB	SIZE dup (?)
  @GWRAM@_QDS=@GWRAM@_QDS+SIZE
  end if
}

;Now put back the R macro for use by Page Independent Uninitialized RAM
; declarations.

;P.I.U. RAM MUST be declared after all P.D.U. RAM, P.D.I. RAM,
; and P.I.I. RAM.

macro @R NAME,SIZE {
  label NAME word
  if SIZE
  DB	SIZE dup (?)
  end if
  @QQ=NAME-MOVDAT-@GWRAM@_QDS
  if @QQ
  display "FATAL @RINIT @GWRAM@_ERROR"
  end if
  @Q=@Q+SIZE
  @GWRAM@_QDS=@GWRAM@_QDS+SIZE
}
; SUBTTL  Page Independent Uninitialized RAM Location Definitions

;OEM Independent Graphics Locations

	@R	@GRPACX,2  ; Previous X Coordinate
	@R	@GRPACY,2  ; Previous Y Coordinate
	@R	@ATRBYT,1  ;Attribute Byte to Store
	@R	@GXPOS,2  ;X Position of Second Coordinate
	@R	@GYPOS,2  ;Y Position of Second Coordinate
	@R1	@MAXUPD,2  ;Address of Major Axis Move Update
	@R1	@MINUPD,2  ;Address of Minor Axis Move Update
	@R	@MAXDEL,2  ;Largest Delta for Line
	@R	@MINDEL,2  ;Smaller of 2 Deltas for Line
	@R	@ASPECT,2  ;ASPECT RATIO
	@R	@CENCNT,2  ;END CIRCLE POINT COUNT
	@R	@CLINEF,1  ;LINE-TO-CENTER FLAG
	@R	@CNPNTS,2  ;1/8 NO. OF PTS IN CIRCLE
	@R	@CPLOTF,1  ;PLOT FLAG
	@R	@CPCNT,2  ;1/8 NO. OF PTS IN CIRCLE
	@R	@CPCNT8,2  ;NO. OF PTS IN CIRCLE
	@R	@CRCSUM,2  ;CIRCLE SUM
	@R	@CSTCNT,2  ;START COUNT
	@R	@CSCLXY,1  ;FLAG WHETHER ASPECT WAS .GT. 1
	@R	@CSAVEA,2  ;ADVGRP C save area
	@R	@CSAVEM,1  ;ADVGRP C save area
	@R	@CXOFF,2  ;X OFFSET FROM CENTER SAVE LOC
	@R	@CYOFF,2  ;Y OFFSET SAVE LOCATION
	@R	@LOHMSK,1  ;RAM SAVE AREA FOR LEFT OVERHANG
	@R	@LOHDIR,1  ;*** LOHMSK & LOHDIR MUST BE CONTIG !
	@R	@LOHADR,2
	@R	@LOHCNT,2
	@R	@LFPROG,1  ;PAINT: SCAN LINE ALREADY PAINTED FLAGS
	@R	@RTPROG,1
	@R	@SKPCNT,2  ;SKIP COUNT
	@R	@MOVCNT,2  ;MOVE COUNT
	@R	@PDIREC,1  ;PAINT DIRECTION
	@R	@PUTFLG,1  ;WHETHER DOING PUT() OR GET()
	@R	@QUEINP,2
	@R	@QUEOUT,2
	@R	@PSNLEN,2  ;Queue present length
	@R	@QUELEN,2  ;Maximum queue length

	@R	@SAVLEN,2  ;used by BLOAD, BSAVE

;Device Variables

; PUBLIC	FOPTSZ
	@FOPTSZ=64  ;size of file open options buffer

	@R	@FILOPT,@FOPTSZ  ;buffer for Special-Device Open Options

;Line Printer variables

;       note: If size of LPT Device Control Block changes,
;             routine GLPDCB in GIOLPT must be changed.

	@R	@LP1DCB,4*@NMLPT  ;LPT1 device control block
;2 bytes (width, position)

;Keyboard variables

; PUBLIC	KYBQSZ
	@KYBQSZ=32
	@R	@KYBQDS,8  ;queue descriptor (for format see GIO86)
	@R	@KYBQUE,@KYBQSZ  ;buffer circular key queue

;RS232C variables

	@R	@MSWSIZ,2  ;/M: value
	@R	@MSWFLG,1  ;/M: exists flag
	@R	@CSWSIZ,2  ;/C: value
	@R	@CSWFLG,1  ;/C: exists flag
	@R	@NEWDS,2  ;New DS:
	@R	@COMDSC,18  ;buffer used to communicate RS232 requests to OS
	@R	@CM1DCB,24*@NMCOMT  ;COM1 device control block (24 bytes per device)
	@R	@LSTIOB,1  ;Contains Last RS232 unit accessed (0..15)
;2 bytes (width, position)
;2 bytes (width, position)

; RAM USED FOR EVENT TRAPPING

	@R	@TRPTBL,3*@NUMTRP  ;trap table - see GWSTS
	@R	@ONGSBF,1  ;see NEWSTT
	@R	@SOFTKY,1  ;used by key trapping in GWSTS
	@R	@F_SUPR,1  ; Flag - non-zero =  super shift expansion

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
