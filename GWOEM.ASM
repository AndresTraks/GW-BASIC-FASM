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
        mov     ax, 0B800h
        mov     es, ax
        mov     ax, 0F00h + ch
        mov     [es:24*80*2 + col*2], ax
        pop     ax
        pop     es
  end if
}

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

; CLRSCN - GWSTS calls it with AL = 2 ("specify text only") and carry clear
; ("no-carry = internal parameter"), then falls into WHOME, so the caller
; positions the cursor afterwards.
@CLRSCN:
        MARK 8,'5'
        push    es
        push    di
        push    ax
        push    cx
        mov     es, [cs:@GWOEM_VSEG]
        xor     di, di
        mov     al, [cs:@GWOEM_WIDTH]
        mul     byte [cs:@GWOEM_HEIGHT]
        mov     cx, ax
        mov     al, ' '
        mov     ah, [cs:@GWOEM_ATTR]
        cld
        rep     stosw
        pop     cx
        pop     ax
        pop     di
        pop     es
        clc
        ret

; SCROLL - a rectangular block move.  SCNDRV, scrolling up by one line:
;   AL = source row, AH = source column, BL = destination row,
;   BH = destination column, CL = row count, CH = column count; all 1-based.
; Source and destination overlap, so the row order follows the direction.
@SCROLL:
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
@PRTMAP:
@EDTMAP:
        cmp     al, 32
        jb      @@pm_func               ; C0 control code
        cmp     al, 127
        je      @@pm_func               ; DEL, which SCNDRV maps to a space
        cmp     ah, 255                 ; a character: print it.  AH is left
        jne     @@pm_ok                 ; alone unless it would be mistaken
        xor     ah, ah                  ; for the function marker
@@pm_ok:
        or      al, al                  ; ZF = 0, AL is 32 or more here
        ret
@@pm_func:
        mov     ah, 255                 ; a function; AL already indexes FUNTAB
        or      ah, ah                  ; ZF = 0
        ret

; ---------------------------------------------------------------------------
; KEYINP - GIO86: "[AX]=next key from keyboard if one exists / JE POLKXI
; ;branch if no key present".  So AX is the character and ZF means "nothing".
; Extended keys (BIOS returns AL = 0) are discarded here, which is what costs
; this layer its arrow keys and function keys.
@KEYINP:
        MARK 6,'4'
        mov     ah, 1
        int     16h
        jz      @@ki_none
        xor     ah, ah
        int     16h                     ; AL = ASCII, AH = scan code
        or      al, al
        jz      @@ki_none               ; extended key: swallowed
        xor     ah, ah
        or      ax, ax                  ; ZF = 0, AL is non-zero here
        ret
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
@SNDLPT:
        push    ax
        push    dx
        xor     ah, ah
        xor     dx, dx                  ; LPT1
        int     17h
        pop     dx
        pop     ax
        ret

; ---------------------------------------------------------------------------
; GWINI - GWINIT: "CALL GWINI ;OEM specific initialization", called after
; SCNIPL, so whatever it sets here wins.  Picks the video buffer from the BIOS
; mode byte and states the window geometry the screen driver works within.
@GWINI:
        MARK 0,'1'
        push    ax
        push    ds
        mov     ax, 40h
        mov     ds, ax
        mov     al, [ds:49h]            ; current BIOS video mode
        pop     ds
        cmp     al, 7
        jne     @@gi_colour
        mov     word [cs:@GWOEM_VSEG], 0B000h
@@gi_colour:
        pop     ax
        push    ax
        mov     al, [cs:@GWOEM_WIDTH]
        mov     byte [@CRTWID], al
        mov     byte [@LINLEN], al
        inc     al                      ; GWRAM: "Rightmost column plus one"
        mov     byte [@WDORGT], al
        mov     al, [cs:@GWOEM_HEIGHT]
        mov     byte [@LINCNT], al
        mov     byte [@WDOBOT], al
        mov     al, 1
        mov     byte [@WDOTOP], al
        mov     byte [@WDOLFT], al
        mov     byte [@CSRY], al
        mov     byte [@CSRX], al
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
@SEGINI:
        MARK 10,'6'
        ret

; SETCBF - GIOCOM: "MOV DX,CSWSIZ ;Segment size request / CALL SETCBF ;Report
; buffer size/loc / JB GOMERR ; & validate size / MOV CSWSIZ,DX".  No serial
; support, so the request is accepted unchanged and no buffer is reserved.
@SETCBF:
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
