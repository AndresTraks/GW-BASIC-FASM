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
; Within the row the two can overlap in either direction: SCNDRV's MVCH20 opens
; up space for an insert with "TO=CURPOS+COUNT" on the same line, and a copy
; that ran forward over that would smear the first character across the rest.
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
        cmp     di, si
        jbe     @@sr_fwd                ; destination at or before the source
        push    ax                      ; after it: run the copy from the end
        mov     ax, cx
        dec     ax
        add     ax, ax
        add     si, ax
        add     di, ax
        pop     ax
        std
        rep     movsw
        cld
        jmp     @@sr_done
@@sr_fwd:
        cld
        rep     movsw
@@sr_done:
        pop     ds
        pop     dx
        pop     cx
        pop     ax
        ret

; ---------------------------------------------------------------------------
; CSRDSP - GWSTS, for LOCATE: "MOV DX,AX ;Load cursor position / MOV AL,3
; ;Signal for user cursor / CALL CSRDSP ;Set cursor", where that AX has just
; been through SCNLOC, which is "MOV CSRX,AH / MOV CSRY,AL".  So DH is the
; column and DL the row, both 1-based, and AL is the cursor type: 0 off, 1
; insert, 2 overwrite, 3 user.  Every other caller arrives through SETCSR,
; which the call sites precede with SCNPOS -- "DH=column, DL=row" -- so the
; position is always there behind it.
;
; Both halves matter here.  SCROUT writes characters straight into the buffer,
; so the hardware cursor moves only when this routine moves it: left to the
; shape alone, it stays wherever DOS left it before GW-BASIC cleared the
; screen, which is the bottom of it.
@CSRDSP:
        MARK 18,'C'
        push    ax
        push    bx
        push    cx
        push    dx
        push    ax                      ; the type, for once the cursor is put
        mov     cl, dl                  ; GW-BASIC counts DH column, DL row,
        mov     dl, dh                  ;  from one; the BIOS counts DH row,
        mov     dh, cl                  ;  DL column, from zero
        dec     dh
        dec     dl
        xor     bh, bh                  ; page 0
        mov     ah, 2
        int     10h
        pop     ax
        or      al, al
        jz      @@csr_off
        cmp     word [cs:@GWOEM_VSEG], 0B000h
        je      @@csr_mono
        mov     cx, 0607h               ; a colour cell is eight lines high
        cmp     al, 1
        jne     @@csr_set
        mov     cx, 0407h               ; insert mode: half the cell
        jmp     @@csr_set
@@csr_mono:
        mov     cx, 0C0Dh               ; a monochrome cell is fourteen
        cmp     al, 1
        jne     @@csr_set
        mov     cx, 070Dh
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
; CL / CALL SWIDTH ;Let screen editor set width", and on return "JB GFCERR".
; The caller does nothing else, so setting the hardware and telling the screen
; driver are both this routine's job -- the same pair GWINI does.
@SWIDTH:
        MARK 20,'W'
        push    ax
        push    bx
        push    cx
        push    dx
        cmp     cl, [cs:@GWOEM_HEIGHT]  ; one height, and no 43-line EGA here
        jne     @@sw_bad
        cmp     word [cs:@GWOEM_VSEG], 0B000h
        je      @@sw_mono
        cmp     al, 40
        je      @@sw_set
        cmp     al, 80
        je      @@sw_set
        jmp     @@sw_bad
@@sw_mono:
        cmp     al, 80                  ; the monochrome adapter has one width
        jne     @@sw_bad
        jmp     @@sw_tell
@@sw_set:
        push    ds
        mov     bx, 40h
        mov     ds, bx
        mov     bl, [ds:49h]            ; the mode in use ...
        pop     ds
        and     bl, 1                   ; ... for its colour burst, 0 or 1
        cmp     al, 40
        jne     @@sw_wide
        mov     al, bl                  ; 40 columns: BIOS mode 0 or 1
        xor     ah, ah
        int     10h
        mov     al, 40
        jmp     @@sw_tell
@@sw_wide:
        mov     al, 2                   ; 80 columns: BIOS mode 2 or 3
        add     al, bl
        xor     ah, ah
        int     10h
        mov     al, 80
@@sw_tell:
        mov     [cs:@GWOEM_WIDTH], al
        mov     cl, [cs:@GWOEM_HEIGHT]
        call    @SCNSWI                 ; LINLEN, CRTWID, WDORGT, status line
        call    @CLRSCN
        pop     dx
        pop     cx
        pop     bx
        pop     ax
        clc
        ret
@@sw_bad:
        pop     dx
        pop     cx
        pop     bx
        pop     ax
        stc
        ret

; SCRSTT - GWSTS: "CALL SCRSTT ;Process params / JB FCERGO ;Error detected in
; low level routine", with BX pointing at the parameter list GTPRMS built in
; BUF.  GWSTS describes it: "a list which is headed by a one word parameter
; count.  The remaining list entries are two bytes long.  The first byte is 0
; if the SCREEN parameter was null.  The second byte is the parameter value".
;
; SCREEN mode, burst, apage, vpage.  The only screen here is the text one, so
; mode 0 is accepted and everything else refused -- which keeps the graphics
; primitives unreachable.  The burst is meaningless without composite output
; and is ignored; the pages must be 0, there being one of them.
@SCRSTT:
        MARK 22,'S'
        push    ax
        push    cx
        push    si
        mov     si, bx
        mov     cl, [si]                ; the parameter count
        xor     ch, ch
        inc     si
        jcxz    @@ss_ok
        cmp     byte [si], 0
        je      @@ss_burst              ; a null mode leaves the screen alone
        cmp     byte [si+1], 0
        jne     @@ss_bad                ; any other mode wants graphics
@@ss_burst:
        add     si, 2
        dec     cx
        jcxz    @@ss_ok
        add     si, 2                   ; the burst, which text mode ignores
        dec     cx
        jcxz    @@ss_ok
@@ss_page:
        cmp     byte [si], 0
        je      @@ss_pnext
        cmp     byte [si+1], 0
        jne     @@ss_bad                ; one page, so only page 0
@@ss_pnext:
        add     si, 2
        dec     cx
        jcxz    @@ss_ok
        jmp     @@ss_page
@@ss_ok:
        pop     si
        pop     cx
        pop     ax
        clc
        ret
@@ss_bad:
        pop     si
        pop     cx
        pop     ax
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
; carry means AH holds a prefix byte.
;
; The key has to come from DOS, not from INT 16h.  MS-DOS 1.25's IO.SYS takes
; over INT 9 and queues scan codes itself, leaving the BIOS buffer at 40:1A
; permanently empty, so INT 16h never reports a key under it.  MSDOSU declares
; exactly two console/printer calls, "C_DCIO=6 ;Direct console I/O" and
; "C_PRTO=5 ;Printer output", which is what the original layer used; POLKEY's
; own test of MSDCCF, "MSDOS Ctl-C Interrupt flag", says the same.
;
; A key with no character arrives from DOS as a zero followed by its scan code,
; the IBM convention.  Translating it is this layer's job, because GW-BASIC has
; a keyboard encoding of its own and knows nothing of scan codes.  Two prefixes
; carry it, both named at the call sites:
;
;   (255, n)  a control function.  POLKEY calls it "the control function range"
;             and offers it to TRPCHK; SCNDRV's CTLDSP hands the second byte to
;             EDTMAP and dispatches it through FUNTAB, which is indexed by the
;             ASCII control code -- entry 30 is WCSUP, 31 WCSDWN, 29 WCSREG,
;             28 WCSADV -- so the second byte is that index.
;   (128, 32+n)  function key n.  CHKFKY tests exactly this and expands the
;             soft key from STRTAB.
@KEYINP:
        MARK 6,'4'
        push    dx
        mov     ah, 6                   ; MSDOSU C_DCIO, direct console I/O
        mov     dl, 0FFh                ; ... input, without waiting
        int     21h
        pop     dx
        jz      @@ki_none               ; nothing waiting
        or      al, al
        jz      @@ki_ext                ; zero: a scan code follows
        cmp     al, 27
        je      @@ki_esc
        xor     ah, ah
        or      ax, ax                  ; ZF = 0, CF = 0: a one-byte key
        ret
; ESC erases the line being edited, which is FUNTAB entry 21, LDELET.  INKMAP
; turns it back into ESC for INKEY$.
@@ki_esc:
        mov     ax, 0FF00h + 21
        jmp     @@ki_two
@@ki_ext:
        push    dx
        mov     ah, 6
        mov     dl, 0FFh
        int     21h                     ; ... the scan code itself
        pop     dx
        jz      @@ki_none               ; a prefix with nothing behind it
        cmp     al, 59                  ; F1 to F10 are scan codes 59 to 68
        jb      @@ki_look
        cmp     al, 68
        ja      @@ki_look
        sub     al, 59 - 32             ; ... and soft keys 32 upwards
        mov     ah, 128
        jmp     @@ki_two
@@ki_look:
        push    cx
        push    si
        mov     si, @GWOEM_KEYTAB
        mov     cx, @GWOEM_KEYTABN
@@ki_scan:
        cmp     al, [cs:si]
        je      @@ki_found
        add     si, 3
        loop    @@ki_scan
        pop     si
        pop     cx
        jmp     @@ki_none               ; a key this layer has no use for
@@ki_found:
        mov     ah, [cs:si+1]
        mov     al, [cs:si+2]
        pop     si
        pop     cx
@@ki_two:
        or      ax, ax                  ; ZF = 0 ...
        stc                             ; ... and CF = 1: two bytes
        ret
@@ki_none:
        xor     ax, ax
        or      ax, ax                  ; ZF = 1
        ret

; Scan code, prefix, code.  The editing functions are FUNTAB indices; the
; comment on each is SCNDRV's own name for the entry.
@GWOEM_KEYTAB:
        db      72, 255, 30             ; cursor up       WCSUP
        db      80, 255, 31             ; cursor down     WCSDWN
        db      75, 255, 29             ; cursor left     WCSREG
        db      77, 255, 28             ; cursor right    WCSADV
        db      71, 255, 11             ; home            WHOME
        db      79, 255, 14             ; end             LAPPND
        db      82, 255, 18             ; insert          LINSRT
        db      83, 255, 127            ; delete          CDELET, via CTLNDL
@GWOEM_KEYTABN = ($ - @GWOEM_KEYTAB) / 3

; INKMAP - GIOKYB's INKEY: "CALL INKMAP ;OEM map routine for INKEY$ / JZ INKGET
; ;OEM has no associated character / JAE INKEY1 ;branch if not 2-byte sequence".
; The flags mean what they do for KEYINP, and this is where the universal codes
; turn back into what a BASIC program expects to read.  That is the IBM
; convention -- CHR$(0) and the scan code -- because that is what every program
; written for this machine tests for.
@INKMAP:
        pushf
        cmp     ah, 255
        je      @@ik_ctl
        cmp     ah, 128
        je      @@ik_fun
        popf
        ret                             ; a character: pass it through unchanged
@@ik_fun:
        popf
        add     al, 59 - 32             ; soft key n back to its scan code
        xor     ah, ah
        or      ax, ax                  ; ZF = 0 ...
        stc                             ; ... CF = 1: still two bytes
        ret
@@ik_ctl:
        popf
        push    cx
        push    si
        mov     si, @GWOEM_KEYTAB
        mov     cx, @GWOEM_KEYTABN
@@ik_scan:
        cmp     al, [cs:si+2]
        je      @@ik_found
        add     si, 3
        loop    @@ik_scan
        pop     si
        pop     cx
        cmp     al, 21                  ; the ESC that became "delete line"
        jne     @@ik_drop
        mov     ax, 27
        or      ax, ax                  ; one byte, ZF = 0, CF = 0
        ret
@@ik_found:
        mov     al, [cs:si]             ; the scan code it was made from
        pop     si
        pop     cx
        xor     ah, ah
        or      ax, ax
        stc
        ret
@@ik_drop:
        xor     ax, ax                  ; ZF = 1: nothing for INKEY$ here
        ret

; INFMAP - GIOKYB's INCHRI: "CALL INFMAP ;OEM fixed length input map routine /
; JZ KEYGET ;OEM filtered out the key - get the next".  Fixed-length input
; wants characters, so a two-byte key is filtered out rather than split.
@INFMAP:
        cmp     ah, 0
        jne     @@if_drop
        or      al, al                  ; ZF = 0, CF = 0: a character
        ret
@@if_drop:
        xor     ax, ax                  ; ZF = 1: filtered out
        ret

; FKYFMT - GWSTS's GETFMT: "CALL FKYFMT ;OEM routine / MOV CX,word [BX+0]
; ;CH=key count, CL=Chrs/key" and then "MOV AL,byte [BX+2]" for the number of
; the first key to show.  So this returns BX pointing at those three bytes, and
; they have to sit in the data segment, because GETFMT reads them through DS.
;
; KEYDSP draws the line itself, through SCROUT; each key costs its digits plus
; FKCNUM characters plus a blank, so ten keys fill 80 columns and five fill 40.
@FKYFMT:
        push    ax
        mov     bx, @FKYFMB
        mov     byte [bx], 6            ; six characters of each definition
        mov     al, [cs:@GWOEM_WIDTH]
        cmp     al, 80
        mov     al, 10
        je      @@ff_keys
        mov     al, 5
@@ff_keys:
        mov     [bx+1], al
        mov     byte [bx+2], 1          ; always starting at key 1
        pop     ax
        ret

; FKYADV - GWSTS: called when KEYSW changes to ON, and SCNDRV: "If KEYSW was
; 0(ZF=0) then init PF start key".  The display here always starts at key 1, so
; there is no start key to move.  MAPSUP, the super-shift mapping, has no
; contract to take from the call site and does nothing.
@MAPSUP:
@FKYADV:
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
        ; the soft keys through FKYFMT.  That is left alone, so the key line
        ; comes up with the heading, as it does on the IBM machines.
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
; DONOTE - GWSTS states the contract itself: "DONOTE(AL: voice (0=forground,
; 1=back), CX:frequency, DX:duration (1=18.7ms)) queues note for execution,
; saves all regs", and the PLAY code pins the unit down -- "[DX]=400 will play
; 1 second", so a unit is 2.5ms.  BEEP asks for 800Hz for 100 of them, a
; quarter second.  A zero frequency is a rest, a zero duration stops the sound,
; and SNDRST calls in with AL=255 to silence everything.  Carry means the note
; was refused, which GWSTS turns into "Illegal function call".
;
; There is one speaker and no interrupt to drive a queue from, so a background
; note is played in the foreground too: the note is heard, but the program
; waits for it rather than running on.
@DONOTE:
        push    ax
        push    bx
        push    cx
        push    dx
        push    si
        mov     si, dx                  ; SI = duration, in 2.5ms units
        cmp     al, 255
        je      @@dn_hush
        or      si, si
        jz      @@dn_hush               ; "If Duration is 0, then just turn off"
        or      cx, cx
        jz      @@dn_wait               ; a rest: time passes, silently
        cmp     cx, 37                  ; "Frequency must be at least 37 Hz"
        jb      @@dn_bad
        mov     bx, cx
        mov     dx, 18                  ; 1193180, the timer's input in Hz
        mov     ax, 35B4h
        div     bx                      ; ... over the frequency: the divisor
        mov     bx, ax
        pushf
        cli
        mov     al, 0B6h                ; channel 2, both bytes, square wave
        out     43h, al
        mov     al, bl
        out     42h, al
        mov     al, bh
        out     42h, al
        popf
        in      al, 61h
        or      al, 3                   ; gate the timer, connect the speaker
        out     61h, al
@@dn_wait:
        call    @GWOEM_PAUSE
@@dn_hush:
        in      al, 61h
        and     al, 0FCh
        out     61h, al
        pop     si
        pop     dx
        pop     cx
        pop     bx
        pop     ax
        clc
        ret
@@dn_bad:
        pop     si
        pop     dx
        pop     cx
        pop     bx
        pop     ax
        stc
        ret

; Wait SI units of 2.5ms.  The BIOS tick is 55ms, far too coarse for a note, so
; this counts channel 0 of the same timer instead: it free-runs at 1.193MHz,
; which makes a unit 2983 of its counts.  Interrupts stay enabled, so keys are
; still queued while a note sounds.
@GWOEM_PAUSE:
        push    ax
        push    bx
        push    cx
        push    dx
        push    si
        push    di
        mov     ax, 2983
        mul     si
        mov     cx, dx
        mov     bx, ax                  ; CX:BX = counts still to wait
        call    @GWOEM_TICK0
        mov     di, ax
@@pa_loop:
        call    @GWOEM_TICK0
        mov     dx, di
        mov     di, ax
        sub     dx, ax                  ; the counter runs down, so this is
        sub     bx, dx                  ;  the elapsed count, wrap included
        sbb     cx, 0
        jnc     @@pa_loop
        pop     di
        pop     si
        pop     dx
        pop     cx
        pop     bx
        pop     ax
        ret

; AX = the current count of timer channel 0, latched so the two halves agree.
@GWOEM_TICK0:
        push    cx
        pushf
        cli
        xor     al, al
        out     43h, al
        in      al, 40h
        mov     cl, al
        in      al, 40h
        mov     ah, al
        mov     al, cl
        popf
        pop     cx
        ret

; ---------------------------------------------------------------------------
; The rest of the OEM layer, which this text-mode reconstruction does not
; implement.  SCRSTT refuses every screen mode, so the graphics primitives are
; unreachable; the sound, light pen, joystick and serial entry points return
; without doing anything.

; PIXSIZ - GENGRP: "CALL PIXSIZ ;Test for graphics capability / OR AL,AL /
; JNZ ... / JMP FCERR ;Graphics not available".  Zero is the answer here, and
; it has to be said explicitly: left to chance, whatever happened to be in AL
; let PSET and DRAW through while LINE, CIRCLE and PAINT were refused.
@PIXSIZ:
        xor     al, al
        ret

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
