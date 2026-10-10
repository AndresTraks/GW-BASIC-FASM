; GWOEM - OEM-supplied layer for the IBM PC and compatibles, text mode only.
;
; GW-BASIC is machine independent: every OEM supplied the routines below, and
; that layer is not part of the released source.  This is a reconstruction of
; its text-mode part, written against the PC BIOS and the video buffer.  Each
; contract is taken from the call site, cited with the routine.
;
; 8088 instructions only - no PUSHA, no shift-by-immediate.
;
; Every routine preserves all registers it does not use to return a value.  The
; callers rely on that, and a stray clobber here would be untraceable.
;
; NOT implemented: graphics (SCREEN 1/2, PSET, LINE, PAINT, DRAW, GET/PUT),
; sound (SOUND, PLAY), light pen, joysticks, serial.  SCRSTT refuses a non-zero
; screen mode, so the graphics primitives are never reached; the rest return
; harmlessly.  See scripts/README.md.

if @GW_PASS = 1

; Tracing.  Set to 1 to have each entry point stamp a character into the bottom
; line of the screen as it is first reached.  This works when nothing else does,
; because it needs no part of GW-BASIC: it is how the init path was established
; to run as far as GETHED.
@GWOEM_TRACE = 0

macro MARK col, ch {
  if @GWOEM_TRACE
        push    es
        push    ax
        push    di
        mov     ax, 0B800h
        mov     es, ax
        mov     ax, 0F00h + ch
        mov     [es:24*80*2 + col*2], ax     ; presence: one fixed cell each
        mov     di, [cs:@GWOEM_SEQ]          ; order: appended, wrapping
        mov     [es:di], ax
        add     di, 2
        cmp     di, 24*80*2
        jb      @f
        mov     di, 23*80*2
    @@: mov     [cs:@GWOEM_SEQ], di
        pop     di
        pop     ax
        pop     es
  end if
}

@GWOEM_SEQ    dw 23*80*2                ; next cell of the chronological trace

; ---------------------------------------------------------------------------
; Geometry and the video buffer.  Held in the code segment because a .COM has
; CS = DS at entry and DS moves to the data segment during GWINIT.

@GWOEM_VSEG   dw 0B800h                 ; colour text buffer; 0B000h on MDA
@GWOEM_WIDTH  db 80
@GWOEM_HEIGHT db 25
@GWOEM_ATTR   db 7                      ; light grey on black

; DL = row, DH = column, both 1-based, as CSRY and CSRX are kept
; (SCNDRV: "MOV BYTE PTR CSRY,DL / MOV BYTE PTR CSRX,DH").
; Returns ES:DI addressing that cell.  Preserves everything else.
@GWOEM_VIDPOS:
        push    ax
        push    dx
        mov     es, [cs:@GWOEM_VSEG]
        dec     dl
        dec     dh
        mov     al, dl
        mul     byte [cs:@GWOEM_WIDTH]
        mov     dl, dh
        xor     dh, dh
        add     ax, dx
        add     ax, ax                  ; two bytes per cell
        mov     di, ax
        pop     dx
        pop     ax
        ret

; ---------------------------------------------------------------------------
; SCROUT - SCNDRV: "CALL SCROUT ; Send char in AX to BIOS at DX posn".
; Carry set would mean "continuation of an escape sequence" (SCNDRV's DOESC
; turns it into ESCFLG); this implementation never reports one.
@SCROUT:
        MARK 4,'3'
        push    es
        push    di
        push    ax
        call    @GWOEM_VIDPOS
        mov     ah, [cs:@GWOEM_ATTR]
        cld
        stosw
        pop     ax
        pop     di
        pop     es
        clc
        ret

; SCRINP - GIO86: "[AX]=Read char at (DH,DL)".  Entered with carry set when the
; call comes from the SCREEN function, which makes no difference here.
@SCRINP:
        MARK 12,'I'
        push    es
        push    di
        call    @GWOEM_VIDPOS
        mov     al, [es:di]
        xor     ah, ah
        pop     di
        pop     es
        ret

; CLREOL - SCNDRV: "Clear to end of line from (DH,DL)".
@CLREOL:
        MARK 14,'E'
        push    es
        push    di
        push    ax
        push    cx
        call    @GWOEM_VIDPOS
        mov     cl, [cs:@GWOEM_WIDTH]
        sub     cl, dh                  ; DH is 1-based, so this leaves width-col
        inc     cl                      ; ... and the cell at the cursor itself
        xor     ch, ch
        mov     al, ' '
        mov     ah, [cs:@GWOEM_ATTR]
        cld
        rep     stosw
        pop     cx
        pop     ax
        pop     di
        pop     es
        ret

; CLRSCN - clearing the screen is split between the two layers, and this is the
; OEM half.  SCNDRV's CCLRSN enters with "CLC ; no-carry = internal parameter /
; MOV AL,LOW 2 ; specify text only" and then falls into WHOME, so the caller
; positions the cursor afterwards; GWSTS's CLS statement calls it directly.
;
; Erasing the hardware is this layer's job.  The driver's half is SCNCLR, which
; runs TTBINI over the line terminator table, homes the graphics and text
; cursors and refreshes the soft-key line -- and which, like SCNSWI, is PUBLIC
; in SCNDRV and called from nowhere in GW-BASIC, so the OEM layer is the only
; thing that can call it.  It matters: LINTTB is uninitialised storage, and a
; zero entry reads as a WRAP terminator, so until TTBINI has run every line
; looks like a continuation of the one above it and the first ENTER sends the
; cursor to the bottom of the screen.
@CLRSCN:
        MARK 8,'5'
        push    ax
        push    bx
        push    cx
        push    dx
        push    si
        push    di
        push    es
        mov     es, [cs:@GWOEM_VSEG]
        xor     di, di
        mov     al, [cs:@GWOEM_WIDTH]
        mul     byte [cs:@GWOEM_HEIGHT]
        mov     cx, ax
        mov     al, ' '
        mov     ah, [cs:@GWOEM_ATTR]
        cld
        rep     stosw
        call    @SCNCLR
        pop     es
        pop     di
        pop     si
        pop     dx
        pop     cx
        pop     bx
        pop     ax
        clc
        ret

; SCROLL - a rectangular block move.  SCNDRV, scrolling up by one line:
;   AL = source row, AH = source column, BL = destination row,
;   BH = destination column, CL = row count, CH = column count; all 1-based.
; Source and destination overlap, so the row order follows the direction.
@SCROLL:
        MARK 16,'L'
        push    es
        push    ds
        push    ax
        push    bx
        push    cx
        push    dx
        push    si
        push    di
        or      cl, cl
        jz      @@sc_done
        or      ch, ch
        jz      @@sc_done
        cmp     al, bl
        jb      @@sc_desc
; source at or below the destination: copy rows top down
@@sc_asc:
        call    @GWOEM_SCROW
        inc     al
        inc     bl
        dec     cl
        jnz     @@sc_asc
        jmp     @@sc_done
; source above the destination: copy rows bottom up
@@sc_desc:
        push    cx
        mov     ch, cl
        dec     ch
        add     al, ch                  ; start at the last row of each block
        add     bl, ch
        pop     cx
@@sc_desc1:
        call    @GWOEM_SCROW
        dec     al
        dec     bl
        dec     cl
        jnz     @@sc_desc1
@@sc_done:
        pop     di
        pop     si
        pop     dx
        pop     cx
        pop     bx
        pop     ax
        pop     ds
        pop     es
        ret

; One row of a block move: source (AL,AH), destination (BL,BH), CH columns.
@GWOEM_SCROW:
        push    ax
        push    cx
        push    dx
        mov     dl, al
        mov     dh, ah
        call    @GWOEM_VIDPOS
        mov     si, di
        mov     dl, bl
        mov     dh, bh
        call    @GWOEM_VIDPOS
        mov     cl, ch
        xor     ch, ch
        push    ds
        mov     ds, [cs:@GWOEM_VSEG]
        cld
        rep     movsw
        pop     ds
        pop     dx
        pop     cx
        pop     ax
        ret

; ---------------------------------------------------------------------------
; CSRDSP - GWSTS: called after CSRFLG changed, with AL the new cursor type;
; 0 means off.  Uses the BIOS so the hardware cursor shape is right.
@CSRDSP:
        MARK 18,'C'
        push    ax
        push    bx
        push    cx
        push    dx
        or      al, al
        jz      @@csr_off
        mov     cx, 0607h               ; a normal underline cursor
        jmp     @@csr_set
@@csr_off:
        mov     cx, 2000h               ; bit 5 set = cursor off
@@csr_set:
        mov     ah, 1
        int     10h
        pop     dx
        pop     cx
        pop     bx
        pop     ax
        ret

; SWIDTH - GWSTS: "MOV AL,DL ;pass Width in AL / MOV CL,LINCNT ;pass Height in
; CL / CALL SWIDTH ;Let screen editor set width".  Only the width this layer
; was built for is accepted; anything else returns carry for "Illegal function
; call".
@SWIDTH:
        MARK 20,'W'
        push    ax
        cmp     al, [cs:@GWOEM_WIDTH]
        pop     ax
        jne     @@sw_bad
        clc
        ret
@@sw_bad:
        stc
        ret

; SCRSTT - GWSTS: "CALL SCRSTT ;Process params / JB FCERGO ;Error detected in
; low level routine".  This layer has no graphics, so every SCREEN request is
; refused and the pixel primitives are never reached.
@SCRSTT:
        MARK 22,'S'
        stc
        ret

; PRTMAP, EDTMAP - SCNDRV: "Map print function/output character codes" and
; "Map edit function/output character code".  Entered with AL the character and
; the carry set for a two-byte character.  SCNDRV then does:
;
;   CTLEDT: JZ  CTLDPY      ; ZF = 1 means ignore the character
;           CMP AH,255      ; AH = 255 means AL is a function, not a character
;           JNZ CTLDSX      ;   otherwise print it
;           ...
;           MOV AX,FUNTAB[BX]   ; dispatch on AL
;
; and FUNTAB is indexed by the ASCII control code itself -- entry 13 is
; LCARET (carriage return), 10 is LFEED, 8 is BAKSPC -- so the mapping is the
; identity, and all this has to decide is function versus character.  Without
; it, carriage return and linefeed reach SCROUT and are drawn as glyphs.
;
; Three ranges are functions.  Under 32 is a C0 control code.  127 is DEL,
; which CTLNDL turns into a space and so into FUNTAB entry 32, CDELET.  255 is
; GW-BASIC's "mark line as not for input": GWMAIN prints it after "Ok" with
; "MOV AL,LOW 377O / CALL OUTDO ;FLAG AS NOT USER INPUT", and BIMISC after a
; LIST line, and CTLNMK answers it by setting TRMNUL on the line's terminator.
; Reported as a character instead, it is drawn as a glyph -- which is what the
; stray character after the "Ok" prompt was.
@PRTMAP:
@EDTMAP:
        cmp     al, 32
        jb      @@pm_func               ; C0 control code
        cmp     al, 127
        je      @@pm_func               ; DEL, which SCNDRV maps to a space
        cmp     al, 255
        je      @@pm_func               ; "mark line as not for input"
        xor     ah, ah                  ; a character: print it
        or      al, al                  ; ZF = 0, AL is 32 or more here
        ret
@@pm_func:
        mov     ah, 255                 ; a function; AL already indexes FUNTAB
        or      ah, ah                  ; ZF = 0
        ret

; ---------------------------------------------------------------------------
; KEYINP - GIOKYB's POLKEY: "CALL KEYINP ; [AX]=next key from keyboard if one
; exists / JE POLKXI ;branch if no key present / JAE NOTTWO ;branch if not
; 2-byte key sequence".  So AX is the key, ZF means nothing is waiting, and
; carry means AH holds a prefix byte -- which this layer never reports.
;
; The key has to come from DOS, not from INT 16h.  MS-DOS 1.25's IO.SYS takes
; over INT 9 and queues scan codes itself, leaving the BIOS buffer at 40:1A
; permanently empty, so INT 16h never reports a key under it.  MSDOSU declares
; exactly two console/printer calls, "C_DCIO=6 ;Direct console I/O" and
; "C_PRTO=5 ;Printer output", which is what the original layer used; POLKEY's
; own test of MSDCCF, "MSDOS Ctl-C Interrupt flag", says the same.
;
; Extended keys arrive as a zero byte followed by the scan code.  Both are
; dropped, which is what costs this layer its arrow and function keys.
@KEYINP:
        MARK 6,'4'
        push    dx
        mov     ah, 6                   ; MSDOSU C_DCIO, direct console I/O
        mov     dl, 0FFh                ; ... input, without waiting
        int     21h
        pop     dx
        jz      @@ki_none               ; nothing waiting
        or      al, al
        jz      @@ki_ext                ; prefix of an extended key
        xor     ah, ah
        or      ax, ax                  ; ZF = 0, CF = 0: a one-byte key
        ret
@@ki_ext:
        push    dx
        mov     ah, 6
        mov     dl, 0FFh
        int     21h                     ; swallow the scan code
        pop     dx
@@ki_none:
        xor     ax, ax
        or      ax, ax                  ; ZF = 1
        ret

; The keyboard and function-key maps.  Their contracts are not established from
; the call sites, so they do nothing rather than guess: no key translation and
; no soft-key display.  Arrow keys, INKEY$ on extended keys and the KEY
; statement are the casualties.
@INKMAP:
@INFMAP:
@MAPSUP:
@FKYADV:
@FKYFMT:
        ret

; SNDLPT - GIOLPT: "Call OEM routine to output to printer", character in AL.
; Through DOS, for the same reason as KEYINP: MSDOSU declares "C_PRTO=5
; ;Printer output" and nothing else that would reach a printer.
@SNDLPT:
        push    ax
        push    dx
        mov     dl, al
        mov     ah, 5                   ; MSDOSU C_PRTO, printer output
        int     21h
        pop     dx
        pop     ax
        ret

; ---------------------------------------------------------------------------
; GWINI - GWINIT: "CALL GWINI ;OEM specific initialization", called after
; SCNIPL, so whatever it sets here wins.  Picks the video buffer from the BIOS
; mode byte, tells the screen driver the geometry and clears the screen.
;
; The geometry goes through SCNSWI rather than being written into CRTWID and the
; window variables here.  SCNSWI is SCNDRV's own "Set CRT physical line width
; ... on entry: AL=width, CL=height", it is PUBLIC and nothing in GW-BASIC calls
; it, and it knows things this layer should not have to: it sets LINLEN as well
; as CRTWID, sets WDORGT to the width (not the width plus one, whatever GWRAM's
; comment says), and reserves the last line for the function-key display with
; "DEC CL ; Reserve status line".
@GWINI:
        MARK 0,'1'
        push    ax
        push    cx
        push    ds
        mov     ax, 40h
        mov     ds, ax
        mov     al, [ds:49h]            ; current BIOS video mode
        pop     ds
        cmp     al, 7
        jne     @@gi_colour
        mov     word [cs:@GWOEM_VSEG], 0B000h
@@gi_colour:
        mov     byte [@KEYSW], 0        ; this layer has no soft-key display
        mov     al, [cs:@GWOEM_WIDTH]
        mov     cl, [cs:@GWOEM_HEIGHT]
        call    @SCNSWI
        call    @CLRSCN
        pop     cx
        pop     ax
        ret

; GETHED - GWINIT: "CALL GETHED ;Get OEM specific portion of the heading /
; JNZ PRNTIT ;Always print the heading option", then "PRNTIT: CALL STROUT".
; STROUT prints a zero-terminated string from CS:[BX] (MATH1), so BX must point
; into the code segment.  Returning non-zero prints it unconditionally.
@GETHED:
        MARK 2,'2'
        ; GWINIT sets KEYSW to 255 just before this call -- "if heading is
        ; printed, display Fn keys also" -- and then calls SKEYON, which walks
        ; the ten soft keys through FKYFMT and FKYADV.  Those are not
        ; implemented here, so decline the display rather than hang in it.
        mov     byte [@KEYSW], 0
        mov     bx, @GWOEM_HEAD
        or      bx, bx                  ; ZF = 0, the address is non-zero
        ret
@GWOEM_HEAD:
        db      13, 10, 'GW-BASIC', 0

; GWTERM, SEGINI - termination and post-DS-move initialisation; nothing to do.
@GWTERM:
        MARK 26,'T'
        ret
@SEGINI:
        MARK 10,'6'
        ret

; SETCBF - GIOCOM: "MOV DX,CSWSIZ ;Segment size request / CALL SETCBF ;Report
; buffer size/loc / JB GOMERR ; & validate size / MOV CSWSIZ,DX".  No serial
; support, so the request is accepted unchanged and no buffer is reserved.
@SETCBF:
        MARK 24,'B'
        clc
        ret

; PEKFLT, POKFLT - GWMAIN: PEEK and POKE filters.  "JNZ ... / JMP PEKVAL
; ;Filter returned the appropriate value", so non-zero means "not handled, do
; the real thing".
@PEKFLT:
@POKFLT:
        push    ax
        mov     al, 1
        or      al, al                  ; ZF = 0
        pop     ax
        ret

; ---------------------------------------------------------------------------
; The rest of the OEM layer, which this text-mode reconstruction does not
; implement.  SCRSTT refuses every screen mode, so the graphics primitives are
; unreachable; the sound, light pen, joystick and serial entry points return
; without doing anything.

@SETC:
@READC:
@STOREC:
@FETCHC:
@MAPXYC:
@SCALXY:
@SCANL:
@SCANR:
@UPC:
@DOWNC:
@LEFTC:
@RIGHTC:
@TUPC:
@TDOWNC:
@NREAD:
@NWRITE:
@NSETCX:
@PIXSIZ:
@GRPSIZ:
@GTASPC:
@PGINIT:
@PNTINI:
@SETATR:
@SETCLR:
@SETFBC:
@GETFBC:
@SCRATR:
@CSRATR:
@DONOTE:
@POLLEV:
@RDPEN:
@RDSTIK:
@RDTRIG:
@LCPY:
@INICOM:
@SNDCOM:
@RECCOM:
@STACOM:
@TRMCOM:
        ret

end if
