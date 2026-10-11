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
        cmp     byte [cs:@GWOEM_GMODE], 0
        jne     @GWOEM_GSCROUT
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
        cmp     byte [cs:@GWOEM_GMODE], 0
        jne     @GWOEM_GSCRINP
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
        cmp     byte [cs:@GWOEM_GMODE], 0
        jne     @GWOEM_GCLREOL
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
        cmp     byte [cs:@GWOEM_GMODE], 0
        je      @@cl_text
        call    @GWOEM_GCLRSCN
        jmp     @@cl_tell
@@cl_text:
        mov     es, [cs:@GWOEM_VSEG]
        xor     di, di
        mov     al, [cs:@GWOEM_WIDTH]
        mul     byte [cs:@GWOEM_HEIGHT]
        mov     cx, ax
        mov     al, ' '
        mov     ah, [cs:@GWOEM_ATTR]
        cld
        rep     stosw
@@cl_tell:
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
        cmp     byte [cs:@GWOEM_GMODE], 0
        je      @@sl_text
        call    @GWOEM_GSCROLL
        jnc     @@sl_done
@@sl_text:
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
@@sl_done:
        ret

; One row of a block move: source (AL,AH), destination (BL,BH), CH columns.
; Within the row the two can overlap in either direction: SCNDRV's MVCH20 opens
; up space for an insert with "TO=CURPOS+COUNT" on the same line, and a copy
; that ran forward over that would smear the first character across the rest.
@GWOEM_SCROW:
        cmp     byte [cs:@GWOEM_GMODE], 0
        jne     @GWOEM_GSCROW
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
; low level routine", with BX pointing at the parameter list GTPRMS built.
; GWSTS describes it: "a list which is headed by a one word parameter count.
; The remaining list entries are two bytes long.  The first byte is 0 if the
; SCREEN parameter was null.  The second byte is the parameter value".
;
; SCREEN mode, burst, apage, vpage.  Modes 0, 1 and 2 are the text screen and
; the two the CGA offers; the burst is meaningless without composite output,
; and the pages must be 0, there being one of each.
@SCRSTT:
        MARK 22,'S'
        push    ax
        push    bx
        push    cx
        push    dx
        push    si
        mov     si, bx
        mov     cl, [si]
        xor     ch, ch
        inc     si
        mov     al, [cs:@GWOEM_GMODE]
        mov     [cs:@GWOEM_GREQ], al    ; a null mode leaves the screen alone
        jcxz    @@ss_apply
        cmp     byte [si], 0
        je      @@ss_burst
        mov     al, [si+1]
        cmp     al, 2
        ja      @@ss_bad
        mov     [cs:@GWOEM_GREQ], al
@@ss_burst:
        add     si, 2
        dec     cx
        jcxz    @@ss_apply
        add     si, 2                   ; the burst, which neither screen uses
        dec     cx
        jcxz    @@ss_apply
@@ss_page:
        cmp     byte [si], 0
        je      @@ss_pnext
        cmp     byte [si+1], 0
        jne     @@ss_bad
@@ss_pnext:
        add     si, 2
        dec     cx
        jcxz    @@ss_apply
        jmp     @@ss_page
@@ss_apply:
        mov     al, [cs:@GWOEM_GREQ]
        cmp     al, [cs:@GWOEM_GMODE]
        je      @@ss_ok                 ; already up: leave the screen alone
        call    @GWOEM_SETMODE
@@ss_ok:
        pop     si
        pop     dx
        pop     cx
        pop     bx
        pop     ax
        clc
        ret
@@ss_bad:
        pop     si
        pop     dx
        pop     cx
        pop     bx
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
; Graphics.  SCREEN 1 is 320x200 in four colours, two bits to a pixel; SCREEN 2
; is 640x200 in two, one bit each.  Both live in the same 16K at B800, the even
; rows from the start and the odd rows 2000h further on, 80 bytes to a row
; either way.
;
; GW-BASIC calls the pair that locates a pixel a "C" -- GENGRP's own words are
; "GET POSITION INTO BITMSK AND [H,L]", and FETCHC hands it back as BX and AL.
; Here that is the offset of the byte and the mask of the pixel within it,
; which is all the primitives below work from.  Nothing outside this file knows
; what either half means.

@GWOEM_PLANE  = 2000h                   ; the odd rows start here
@GWOEM_GROWB  = 80                      ; bytes to a row
@GWOEM_GPLANE = 100 * @GWOEM_GROWB      ; and a plane holds a hundred of them

@GWOEM_GMODE  db 0                      ; 0 text, or the SCREEN that is up
@GWOEM_GREQ   db 0                      ; the SCREEN being asked for
@GWOEM_GBPP   db 0                      ; bits to a pixel
@GWOEM_GSHIFT db 0                      ; ... as a shift: pixels to a byte
@GWOEM_GFIRST db 0                      ; mask of the leftmost pixel of a byte
@GWOEM_GREP   db 0                      ; spreads an attribute over a byte
@GWOEM_GAMSK  db 0                      ; the bits an attribute may use
@GWOEM_GMAXX  dw 0                      ; the largest coordinates
@GWOEM_GMAXY  dw 199
@GWOEM_GASP   dw 0                      ; aspect ratio, 256ths
@GWOEM_CADR   dw 0                      ; the current C: the byte ...
@GWOEM_CMSK   db 0                      ;  ... and the pixel inside it
@GWOEM_FORE   db 3                      ; graphics foreground
@GWOEM_BACK   db 0                      ;  and background
@GWOEM_GLASTM db 0
@GWOEM_GOK    db 0                      ; scratch for SCALXY's answer

; Put up a screen.  AL is 0 for text or the SCREEN number, and this is the pair
; GWINI does: set the hardware, then tell SCNDRV the geometry and clear.
@GWOEM_SETMODE:
        push    ax
        push    bx
        push    cx
        mov     [cs:@GWOEM_GMODE], al
        or      al, al
        jnz     @@sm_graph
        mov     byte [cs:@GWOEM_GBPP], 0
        mov     al, 3                   ; 80 columns of text, in colour
        cmp     word [cs:@GWOEM_VSEG], 0B000h
        jne     @@sm_set
        mov     al, 7                   ; ... or on the monochrome card
        jmp     @@sm_set
@@sm_graph:
        mov     word [cs:@GWOEM_VSEG], 0B800h
        cmp     al, 2
        je      @@sm_two
        mov     byte [cs:@GWOEM_GBPP], 2
        mov     byte [cs:@GWOEM_GSHIFT], 2
        mov     byte [cs:@GWOEM_GFIRST], 0C0h
        mov     byte [cs:@GWOEM_GREP], 055h
        mov     byte [cs:@GWOEM_GAMSK], 3
        mov     byte [cs:@GWOEM_GLASTM], 3
        mov     byte [cs:@GWOEM_FORE], 3     ; the default a statement draws in
        mov     byte [cs:@GWOEM_BACK], 0
        mov     word [cs:@GWOEM_GMAXX], 319
        mov     word [cs:@GWOEM_GASP], 213      ; five sixths, in 256ths
        mov     byte [cs:@GWOEM_WIDTH], 40
        mov     al, 4
        jmp     @@sm_set
@@sm_two:
        mov     byte [cs:@GWOEM_GBPP], 1
        mov     byte [cs:@GWOEM_GSHIFT], 3
        mov     byte [cs:@GWOEM_GFIRST], 080h
        mov     byte [cs:@GWOEM_GREP], 0FFh
        mov     byte [cs:@GWOEM_GAMSK], 1
        mov     byte [cs:@GWOEM_GLASTM], 1
        mov     byte [cs:@GWOEM_FORE], 1     ; the default a statement draws in
        mov     byte [cs:@GWOEM_BACK], 0
        mov     word [cs:@GWOEM_GMAXX], 639
        mov     word [cs:@GWOEM_GASP], 107      ; five twelfths
        mov     byte [cs:@GWOEM_WIDTH], 80
        mov     al, 6
@@sm_set:
        cmp     byte [cs:@GWOEM_GMODE], 0
        jne     @@sm_int
        mov     byte [cs:@GWOEM_WIDTH], 80
@@sm_int:
        xor     ah, ah
        int     10h
        mov     al, [cs:@GWOEM_WIDTH]
        mov     cl, [cs:@GWOEM_HEIGHT]
        call    @SCNSWI
        call    @CLRSCN
        pop     cx
        pop     bx
        pop     ax
        ret

; MAPXYC - "MAP INTO A C".  The coordinate is in CX and DX, which is where
; SCAND leaves it -- "RETURN X IN BC ... RETURN Y IN [D,E]" -- and where the
; line code keeps it, swapping those registers with GXPOS and GYPOS as it goes.
; GRPACX and GRPACY are the accumulator SCAND also updates, and they do not
; follow those swaps, so they are not what this reads.
@MAPXYC:
        push    ax
        push    bx
        push    cx
        push    dx
        push    cx                      ; the column, for once the row is done
        mov     ax, dx
        push    ax                      ; MUL needs DX, so keep the row here
        shr     ax, 1
        mov     cx, @GWOEM_GROWB
        mul     cx                      ; the row pair, 80 bytes each
        mov     bx, ax
        pop     ax
        test    al, 1
        jz      @@mx_even
        add     bx, @GWOEM_PLANE        ; odd rows sit in the second plane
@@mx_even:
        pop     ax
        mov     dx, ax
        mov     cl, [cs:@GWOEM_GSHIFT]
        shr     ax, cl                  ; which byte of the row
        add     bx, ax
        mov     ax, 1
        shl     ax, cl
        dec     ax
        and     dx, ax                  ; and which pixel of the byte
        mov     cl, [cs:@GWOEM_GBPP]
        dec     cl
        mov     ax, dx
        shl     ax, cl                  ; times the bits each one takes
        mov     cl, al
        mov     al, [cs:@GWOEM_GFIRST]
        shr     al, cl
        mov     [cs:@GWOEM_CMSK], al
        mov     [cs:@GWOEM_CADR], bx
        pop     dx
        pop     cx
        pop     bx
        pop     ax
        ret

; SCALXY - "SCALE INTO BOUNDS", on the same CX and DX.  The caller reads the
; carry as GENGRP does, "JAE PSTNOT ;NO PSET IF NOT IN BOUNDS", so carry set
; means the point was on the screen.  Either way it is brought onto it, which
; is what the line code wants -- DOGRPH calls this "CHEATY SCALING - JUST
; TRUNCATE FOR NOW".
@SCALXY:
        push    ax
        mov     byte [cs:@GWOEM_GOK], 1
        mov     ax, cx
        or      ax, ax
        jns     @@sc_xhigh
        xor     ax, ax
        jmp     @@sc_xbad
@@sc_xhigh:
        cmp     ax, [cs:@GWOEM_GMAXX]
        jbe     @@sc_xdone
        mov     ax, [cs:@GWOEM_GMAXX]
@@sc_xbad:
        mov     byte [cs:@GWOEM_GOK], 0
@@sc_xdone:
        mov     cx, ax
        mov     ax, dx
        or      ax, ax
        jns     @@sc_yhigh
        xor     ax, ax
        jmp     @@sc_ybad
@@sc_yhigh:
        cmp     ax, [cs:@GWOEM_GMAXY]
        jbe     @@sc_ydone
        mov     ax, [cs:@GWOEM_GMAXY]
@@sc_ybad:
        mov     byte [cs:@GWOEM_GOK], 0
@@sc_ydone:
        mov     dx, ax
        pop     ax
        cmp     byte [cs:@GWOEM_GOK], 0
        je      @@sc_off
        stc
        ret
@@sc_off:
        clc
        ret

; SETC - put ATRBYT at the current C.  Spreading the attribute over the whole
; byte and keeping only the masked bits saves having to know where in the byte
; the pixel sits.
@SETC:
        push    ax
        push    bx
        push    es
        mov     es, [cs:@GWOEM_VSEG]
        mov     bx, [cs:@GWOEM_CADR]
        mov     al, byte [@ATRBYT]
        and     al, [cs:@GWOEM_GAMSK]
        mul     byte [cs:@GWOEM_GREP]
        mov     ah, [cs:@GWOEM_CMSK]
        and     al, ah
        not     ah
        and     ah, [es:bx]
        or      al, ah
        mov     [es:bx], al
        pop     es
        pop     bx
        pop     ax
        ret

; READC - the attribute at the current C, in AL.
@READC:
        push    bx
        push    cx
        push    es
        mov     es, [cs:@GWOEM_VSEG]
        mov     bx, [cs:@GWOEM_CADR]
        mov     ah, [cs:@GWOEM_CMSK]
        mov     al, [es:bx]
        and     al, ah
@@rc_down:
        test    ah, 1                   ; slide the pixel down to bit 0
        jnz     @@rc_done
        shr     al, 1
        shr     ah, 1
        jmp     @@rc_down
@@rc_done:
        xor     ah, ah
        pop     es
        pop     cx
        pop     bx
        ret

; STOREC, FETCHC - the current C out of and into BX and AL, which is how the
; paint and box code carries one around.
@STOREC:
        mov     [cs:@GWOEM_CADR], bx
        mov     [cs:@GWOEM_CMSK], al
        ret

@FETCHC:
        mov     bx, [cs:@GWOEM_CADR]
        mov     al, [cs:@GWOEM_CMSK]
        ret

; RIGHTC, LEFTC - one pixel across, into the next byte when the mask runs out.
@RIGHTC:
        push    ax
        push    cx
        mov     cl, [cs:@GWOEM_GBPP]
        mov     al, [cs:@GWOEM_CMSK]
        shr     al, cl
        jnz     @@rt_done
        mov     al, [cs:@GWOEM_GFIRST]
        inc     word [cs:@GWOEM_CADR]
@@rt_done:
        mov     [cs:@GWOEM_CMSK], al
        pop     cx
        pop     ax
        ret

@LEFTC:
        push    ax
        push    cx
        mov     cl, [cs:@GWOEM_GBPP]
        mov     al, [cs:@GWOEM_CMSK]
        shl     al, cl
        jnz     @@lf_done
        mov     al, [cs:@GWOEM_GFIRST]
        mov     cl, 8
        sub     cl, [cs:@GWOEM_GBPP]
        shr     al, cl                  ; the rightmost pixel of a byte
        dec     word [cs:@GWOEM_CADR]
@@lf_done:
        mov     [cs:@GWOEM_CMSK], al
        pop     cx
        pop     ax
        ret

; DOWNC, UPC - one row.  The planes alternate, so a row down from an even row
; is the same offset in the other plane, and from an odd row it is the next
; row of this one.
@DOWNC:
        push    ax
        mov     ax, [cs:@GWOEM_CADR]
        test    ah, @GWOEM_PLANE / 256
        jnz     @@dn_odd
        add     ax, @GWOEM_PLANE
        jmp     @@dn_done
@@dn_odd:
        sub     ax, @GWOEM_PLANE - @GWOEM_GROWB
@@dn_done:
        mov     [cs:@GWOEM_CADR], ax
        pop     ax
        ret

@UPC:
        push    ax
        mov     ax, [cs:@GWOEM_CADR]
        test    ah, @GWOEM_PLANE / 256
        jz      @@up_even
        sub     ax, @GWOEM_PLANE
        jmp     @@up_done
@@up_even:
        add     ax, @GWOEM_PLANE - @GWOEM_GROWB
@@up_done:
        mov     [cs:@GWOEM_CADR], ax
        pop     ax
        ret

; TUPC, TDOWNC - PAINT's "SEE IF AT BOTTOM & MOVE DOWN IF NOT", and the same
; upwards; carry set means the edge was reached and nothing moved.
@TDOWNC:
        push    ax
        mov     ax, [cs:@GWOEM_CADR]
        test    ah, @GWOEM_PLANE / 256
        jz      @@td_ok                 ; an even row always has one below it
        sub     ax, @GWOEM_PLANE - @GWOEM_GROWB
        cmp     ax, @GWOEM_GPLANE
        jb      @@td_ok
        pop     ax
        stc
        ret
@@td_ok:
        pop     ax
        call    @DOWNC
        clc
        ret

@TUPC:
        push    ax
        mov     ax, [cs:@GWOEM_CADR]
        test    ah, @GWOEM_PLANE / 256
        jnz     @@tu_ok                 ; an odd row always has one above it
        cmp     ax, @GWOEM_GROWB
        jae     @@tu_ok
        pop     ax
        stc
        ret
@@tu_ok:
        pop     ax
        call    @UPC
        clc
        ret

; NSETCX - "NSETCX WITH COUNT IN [H,L] OF POINTS TO SETC", rightwards.
@NSETCX:
        push    cx
        mov     cx, bx
        jcxz    @@nx_done
@@nx_loop:
        call    @SETC
        call    @RIGHTC
        loop    @@nx_loop
@@nx_done:
        pop     cx
        ret

; PIXSIZ - GENGRP: "CALL PIXSIZ ;Test for graphics capability / OR AL,AL /
; JNZ ... / JMP FCERR ;Graphics not available".  Zero while the text screen is
; up, which is what keeps the graphics statements out of it.
@PIXSIZ:
        mov     al, [cs:@GWOEM_GBPP]
        ret

; GRPSIZ - GRPINI halves what comes back to centre the graphics cursor, so
; these are the largest coordinates, not the counts.
@GRPSIZ:
        mov     cx, [cs:@GWOEM_GMAXX]
        mov     dx, [cs:@GWOEM_GMAXY]
        ret

; GTASPC - the aspect ratio for CIRCLE and DRAW, as a fraction of 256 in BX
; with its inverse in DX.  ADVGRP tests "IS ASPECT RATIO GREATER THAN ONE" by
; looking at BH, and both screens here are wider than they are tall.
@GTASPC:
        mov     bx, [cs:@GWOEM_GASP]
        mov     dx, 65535
        or      bx, bx
        jz      @@ga_done
        push    ax
        push    cx
        mov     dx, 1
        xor     ax, ax                  ; 65536 / aspect
        div     bx
        mov     dx, ax
        pop     cx
        pop     ax
@@ga_done:
        ret

; ---------------------------------------------------------------------------
; Colours.

; SETATR - GENGRP: "CALL SETATR ;SET THE ATTRIBUTE AS THE CURRENT ONE / JAE ..
; / JMP FCERR ;ILLEGAL ATTRIBUTES GIVE FUNCTION CALL".
@SETATR:
        cmp     byte [cs:@GWOEM_GMODE], 0
        jne     @@sa_graph
        cmp     al, 16
        jae     @@sa_bad
        clc
        ret
@@sa_graph:
        push    bx
        mov     bl, [cs:@GWOEM_GAMSK]
        cmp     al, bl
        pop     bx
        ja      @@sa_bad
        clc
        ret
@@sa_bad:
        stc
        ret

; GETFBC, SETFBC - the foreground in AL and the background in BL.  Carry on
; entry to GETFBC asks for the graphics pair; GWSTS's XFGBG reverses the
; soft-key line with "CLC / CALL GETFBC / XCHG AX,BX / CALL SETFBC".
@GETFBC:
        jc      @@gf_graph
        cmp     byte [cs:@GWOEM_GMODE], 0
        jne     @@gf_graph
        push    cx
        mov     al, [cs:@GWOEM_ATTR]
        mov     bl, al
        and     al, 0Fh
        mov     cl, 4
        shr     bl, cl
        and     bl, 7
        pop     cx
        ret
; On a graphics screen these are attributes, not colours.  PRESET with no
; attribute of its own draws in the background one -- GENGRP: "STC ;Flag to get
; graphics colors / CALL GETFBC / MOV AL,BL ;Get background color" -- and that
; is palette entry 0, not whichever of the sixteen COLOR last asked the screen
; to show.  Handing back the latter is an attribute SETATR refuses, and DONKEY,
; which PRESETs the donkey's eyes, stops on it.
@@gf_graph:
        mov     al, [cs:@GWOEM_FORE]
        mov     bl, [cs:@GWOEM_BACK]
        ret

@SETFBC:
        cmp     byte [cs:@GWOEM_GMODE], 0
        jne     @@sf_graph
        push    ax
        push    cx
        and     al, 0Fh
        mov     ah, bl
        and     ah, 7
        mov     cl, 4
        shl     ah, cl
        or      al, ah
        mov     [cs:@GWOEM_ATTR], al
        pop     cx
        pop     ax
        ret
@@sf_graph:
        mov     [cs:@GWOEM_FORE], al
        mov     [cs:@GWOEM_BACK], bl
        ret

; SETCLR - the COLOR statement.  BX points at the list GTPRMS built, the same
; shape SCRSTT reads, and carry says the colours were refused.  On the text
; screen that is foreground, background and a border this layer has nowhere to
; put; on SCREEN 1 it is the background and the palette, both of which the BIOS
; sets; SCREEN 2 has two fixed colours and takes none of it.
;
; The background runs 0 to 15 here, not 0 to 7.  IBM's own COLORBAR sample asks
; for "COLOR I+8,I+8" to draw its second row of bars, the bright half of the
; sixteen, and refusing that is an Illegal function call in the middle of a
; program that shipped on this disk.  The attribute keeps three bits for it,
; so the light half lands on the dark one; the foreground carries the colour
; that the bar is actually drawn in.
@SETCLR:
        push    ax
        push    bx
        push    cx
        push    si
        mov     si, bx
        mov     cl, [si]
        xor     ch, ch
        inc     si
        or      cx, cx
        jnz     @@cl_n1
        jmp     @@cl_ok
@@cl_n1:
        cmp     byte [cs:@GWOEM_GMODE], 2
        je      @@cl_bad
        cmp     byte [cs:@GWOEM_GMODE], 1
        je      @@cl_graph
        cmp     byte [si], 0
        je      @@cl_back
        mov     al, [si+1]
        cmp     al, 32
        jae     @@cl_bad
        mov     ah, al                  ; 16 and up is the same colour, blinking
        and     ah, 10h
        push    cx
        mov     cl, 3
        shl     ah, cl
        pop     cx                      ; ... which is bit 7 of the attribute
        and     al, 0Fh
        or      al, ah
        mov     bl, [cs:@GWOEM_ATTR]
        and     bl, 70h
        or      al, bl
        mov     [cs:@GWOEM_ATTR], al
@@cl_back:
        add     si, 2
        dec     cx
        or      cx, cx
        jnz     @@cl_n2
        jmp     @@cl_ok
@@cl_n2:
        cmp     byte [si], 0
        je      @@cl_ok
        mov     al, [si+1]
        cmp     al, 16
        jae     @@cl_bad
        and     al, 7                   ; three bits is all the hardware has
        mov     cl, 4
        shl     al, cl
        mov     bl, [cs:@GWOEM_ATTR]
        and     bl, 8Fh
        or      al, bl
        mov     [cs:@GWOEM_ATTR], al
        jmp     @@cl_ok
@@cl_graph:
        cmp     byte [si], 0
        je      @@cl_pal
        mov     al, [si+1]
        cmp     al, 16
        jae     @@cl_bad
        mov     bl, al                  ; one of the sixteen the screen can show,
        xor     bh, bh                  ;  which is not an attribute to draw in
        mov     ah, 0Bh
        int     10h
@@cl_pal:
        add     si, 2
        dec     cx
        or      cx, cx
        jnz     @@cl_n3
        jmp     @@cl_ok
@@cl_n3:
        cmp     byte [si], 0
        je      @@cl_ok
        mov     al, [si+1]
        and     al, 1
        mov     bl, al
        mov     bh, 1                   ; which of the two palettes
        mov     ah, 0Bh
        int     10h
@@cl_ok:
        pop     si
        pop     cx
        pop     bx
        pop     ax
        clc
        ret
@@cl_bad:
        pop     si
        pop     cx
        pop     bx
        pop     ax
        stc
        ret

; SCRATR - GWSTS: "MOV BX,CX ;Call SCRATR with AX=X,BX=Y / CALL SCRATR ;Get
; screen attributes", the answer going to MAKINT in BX.  A graphics screen
; keeps no attribute per cell, so it reports none.
@SCRATR:
        push    ax
        push    cx
        push    dx
        push    di
        push    es
        mov     dh, al
        mov     dl, bl
        xor     bx, bx
        cmp     byte [cs:@GWOEM_GMODE], 0
        jne     @@at_done
        call    @GWOEM_VIDPOS
        mov     al, [es:di+1]
        xor     ah, ah
        mov     bx, ax
@@at_done:
        pop     es
        pop     di
        pop     dx
        pop     cx
        pop     ax
        ret

; CSRATR - the cursor shape LOCATE may ask for.  The BIOS already gives this
; layer the shape it wants through CSRDSP, so the request is accepted and the
; shape left as it is.
@CSRATR:
        clc
        ret

; ---------------------------------------------------------------------------
; Text on a graphics screen.  The characters are drawn from the font the BIOS
; carries, so these hand them to it rather than writing cells of their own.

@GWOEM_BPOS:                            ; DH column, DL row, both 1-based
        push    ax
        push    bx
        push    cx
        push    dx
        mov     cl, dl
        mov     dl, dh
        mov     dh, cl
        dec     dh
        dec     dl
        xor     bh, bh
        mov     ah, 2
        int     10h
        pop     dx
        pop     cx
        pop     bx
        pop     ax
        ret

@GWOEM_GSCROUT:
        push    ax
        push    bx
        push    cx
        push    dx
        push    ax
        call    @GWOEM_BPOS
        pop     ax
        xor     bh, bh
        mov     bl, [cs:@GWOEM_FORE]
        mov     cx, 1
        mov     ah, 9
        int     10h
        pop     dx
        pop     cx
        pop     bx
        pop     ax
        clc
        ret

@GWOEM_GSCRINP:
        push    bx
        push    cx
        push    dx
        call    @GWOEM_BPOS
        xor     bh, bh
        mov     ah, 8
        int     10h
        xor     ah, ah
        pop     dx
        pop     cx
        pop     bx
        ret

@GWOEM_GCLREOL:
        push    ax
        push    bx
        push    cx
        push    dx
        call    @GWOEM_BPOS
        mov     cl, [cs:@GWOEM_WIDTH]
        sub     cl, dh
        inc     cl
        xor     ch, ch
        mov     al, " "
        xor     bh, bh
        mov     bl, [cs:@GWOEM_FORE]
        mov     ah, 9
        int     10h
        pop     dx
        pop     cx
        pop     bx
        pop     ax
        ret

@GWOEM_GCLRSCN:
        push    ax
        push    bx
        push    cx
        push    dx
        mov     ax, 0600h               ; blank the whole window
        xor     bh, bh
        xor     cx, cx
        mov     dh, [cs:@GWOEM_HEIGHT]
        dec     dh
        mov     dl, [cs:@GWOEM_WIDTH]
        dec     dl
        int     10h
        pop     dx
        pop     cx
        pop     bx
        pop     ax
        ret

; A scroll of the text window moves pixels, not characters: reading a cell back
; with the BIOS only returns a character when the pixels under it still form
; one, so copying a graphics screen cell by cell erases it.  A plain vertical
; move of a block is what the BIOS scroll does, so it does it; anything else
; falls back to the copy below, which is only ever reached while editing.
@GWOEM_GSCROLL:
        cmp     ah, bh                  ; the same columns ...
        jne     @@gl_no
        cmp     al, bl                  ; ... and a different row?
        je      @@gl_no
        or      cl, cl
        jz      @@gl_no
        or      ch, ch
        jz      @@gl_no
        push    ax
        push    bx
        push    cx
        push    dx
        mov     dl, ah
        dec     dl
        mov     [cs:@GWOEM_GLLFT], dl
        add     dl, ch
        dec     dl
        mov     [cs:@GWOEM_GLRGT], dl
        cmp     al, bl
        jb      @@gl_down
        mov     dl, al                  ; up: the destination is the top
        sub     dl, bl
        mov     [cs:@GWOEM_GLN], dl
        mov     byte [cs:@GWOEM_GLFN], 6
        mov     dl, bl
        mov     dh, al
        jmp     @@gl_rows
@@gl_down:
        mov     dl, bl                  ; down: the source is
        sub     dl, al
        mov     [cs:@GWOEM_GLN], dl
        mov     byte [cs:@GWOEM_GLFN], 7
        mov     dl, al
        mov     dh, bl
@@gl_rows:
        dec     dl
        mov     [cs:@GWOEM_GLTOP], dl
        add     dh, cl
        dec     dh
        dec     dh
        mov     [cs:@GWOEM_GLBOT], dh
        mov     ah, [cs:@GWOEM_GLFN]
        mov     al, [cs:@GWOEM_GLN]
        xor     bh, bh                  ; the uncovered lines go black
        mov     ch, [cs:@GWOEM_GLTOP]
        mov     cl, [cs:@GWOEM_GLLFT]
        mov     dh, [cs:@GWOEM_GLBOT]
        mov     dl, [cs:@GWOEM_GLRGT]
        int     10h
        pop     dx
        pop     cx
        pop     bx
        pop     ax
        clc
        ret
@@gl_no:
        stc
        ret

@GWOEM_GLTOP  db 0
@GWOEM_GLBOT  db 0
@GWOEM_GLLFT  db 0
@GWOEM_GLRGT  db 0
@GWOEM_GLN    db 0
@GWOEM_GLFN   db 0

; One row of a block move, cell by cell through the BIOS, in whichever
; direction keeps an overlap from eating itself.
@GWOEM_GSCROW:
        push    ax
        push    bx
        push    cx
        push    dx
        mov     [cs:@GWOEM_SROW], al
        mov     [cs:@GWOEM_SCOL], ah
        mov     [cs:@GWOEM_DROW], bl
        mov     [cs:@GWOEM_DCOL], bh
        mov     byte [cs:@GWOEM_STEP], 1
        mov     cl, ch
        xor     ch, ch
        jcxz    @@gw_done
        cmp     bh, ah
        jbe     @@gw_loop
        mov     byte [cs:@GWOEM_STEP], -1
        mov     al, cl
        dec     al
        add     [cs:@GWOEM_SCOL], al
        add     [cs:@GWOEM_DCOL], al
@@gw_loop:
        mov     dh, [cs:@GWOEM_SCOL]
        mov     dl, [cs:@GWOEM_SROW]
        call    @GWOEM_GSCRINP
        mov     dh, [cs:@GWOEM_DCOL]
        mov     dl, [cs:@GWOEM_DROW]
        call    @GWOEM_GSCROUT
        mov     al, [cs:@GWOEM_STEP]
        add     [cs:@GWOEM_SCOL], al
        add     [cs:@GWOEM_DCOL], al
        loop    @@gw_loop
@@gw_done:
        pop     dx
        pop     cx
        pop     bx
        pop     ax
        ret

@GWOEM_SROW   db 0
@GWOEM_SCOL   db 0
@GWOEM_DROW   db 0
@GWOEM_DCOL   db 0
@GWOEM_STEP   db 0


; ---------------------------------------------------------------------------
; PAINT.  ADVGRP keeps a queue of runs still to be looked at and walks the
; region a scan line at a time; these three do the work on the line itself.

@GWOEM_PBORD  db 0                      ; the attribute the scan stops at
@GWOEM_PCNT   dw 0                      ; points painted by this scan
@GWOEM_PSKIP  dw 0                      ; how much of the run is left
@GWOEM_PNEW   db 0                      ; whether any of it was new ground

; The byte column of the current C, 0 to 79, which is how the edges of a row
; are recognised from an address that carries no coordinates.
@GWOEM_GCOL:
        mov     ax, [cs:@GWOEM_CADR]
        and     ax, 0FFFFh - @GWOEM_PLANE
        xor     dx, dx
        mov     bx, @GWOEM_GROWB
        div     bx
        mov     ax, dx
        ret

; Carry set when the current C is the last pixel of its row, or the first.
@GWOEM_GATRT:
        push    ax
        push    bx
        push    dx
        mov     al, [cs:@GWOEM_CMSK]
        cmp     al, [cs:@GWOEM_GLASTM]
        jne     @@rt_no
        call    @GWOEM_GCOL
        cmp     ax, @GWOEM_GROWB - 1
        jne     @@rt_no
        pop     dx
        pop     bx
        pop     ax
        stc
        ret
@@rt_no:
        pop     dx
        pop     bx
        pop     ax
        clc
        ret

@GWOEM_GATLF:
        push    ax
        push    bx
        push    dx
        mov     al, [cs:@GWOEM_CMSK]
        cmp     al, [cs:@GWOEM_GFIRST]
        jne     @@lf_no
        call    @GWOEM_GCOL
        or      ax, ax
        jnz     @@lf_no
        pop     dx
        pop     bx
        pop     ax
        stc
        ret
@@lf_no:
        pop     dx
        pop     bx
        pop     ax
        clc
        ret

; PNTINI - "INIT PAINT STUFF & CHECK BORDER ATTRIB", the border in AL, carry
; if it is not a colour this screen has.
@PNTINI:
        push    bx
        mov     bl, [cs:@GWOEM_GAMSK]
        cmp     al, bl
        pop     bx
        ja      @@pi_bad
        mov     [cs:@GWOEM_PBORD], al
        clc
        ret
@@pi_bad:
        stc
        ret

; SCANR - "PERFORM LOW LEVEL RIGHT SCAN".  DX arrives as SKPCNT, the run the
; line above or below painted, which is how much of this line is worth looking
; at.  The border may lie across the start of it -- scanning a circle upwards
; lands on the arc every time, because the line below ends where the arc
; begins -- so border is stepped over while the run lasts, and what is left of
; the run beyond it is painted, out to the next border or the edge.
;
; Two bounds keep the scan inside the shape, and both of them matter.  Running
; out of run while still on border means this line has nothing: the top of a
; circle, where the arc covers the whole of the line below.  And the scan is
; only allowed to paint once it has found something to paint within the run --
; stepping over the last of the border on the last of the count and painting
; whatever lies beyond it is how a fill escapes a closed shape and floods the
; screen.
;
; Back come DX as what is left of the run, BX as the number painted, CL as
; whether any of it was new, and CSAVEA/CSAVEM as the first point painted --
; not the point the scan started from.  SCANL1 puts the C back there before
; scanning the other way, and the other way from a border point is straight
; out of the shape.
@SCANR:
        push    ax
        mov     [cs:@GWOEM_PSKIP], dx
        mov     word [cs:@GWOEM_PCNT], 0
        mov     byte [cs:@GWOEM_PNEW], 0
@@rs_skip:
        cmp     word [cs:@GWOEM_PSKIP], 0
        jle     @@rs_done
        call    @READC
        cmp     al, [cs:@GWOEM_PBORD]
        jne     @@rs_mark
        call    @GWOEM_GATRT
        jc      @@rs_done
        call    @RIGHTC
        dec     word [cs:@GWOEM_PSKIP]
        jmp     @@rs_skip
@@rs_mark:
        call    @FETCHC                 ; where the painting will start
        mov     [@CSAVEA], bx
        mov     byte [@CSAVEM], al
@@rs_paint:
        call    @READC
        cmp     al, [cs:@GWOEM_PBORD]
        je      @@rs_done
        cmp     al, byte [@ATRBYT]
        je      @@rs_old
        mov     byte [cs:@GWOEM_PNEW], 1
@@rs_old:
        call    @SETC
        inc     word [cs:@GWOEM_PCNT]
        call    @GWOEM_GATRT
        jc      @@rs_done
        call    @RIGHTC
        jmp     @@rs_paint
@@rs_done:
        mov     bx, [cs:@GWOEM_PCNT]
        mov     dx, [cs:@GWOEM_PSKIP]
        mov     cl, [cs:@GWOEM_PNEW]
        pop     ax
        ret

; SCANL - the same leftwards, from the point the line started at.  That point
; has already been painted, so this steps first and stops on the border rather
; than at it, leaving the C on the last point it painted.
@SCANL:
        push    ax
        mov     word [cs:@GWOEM_PCNT], 0
        mov     byte [cs:@GWOEM_PNEW], 0
@@ls_loop:
        call    @GWOEM_GATLF
        jc      @@ls_done
        call    @LEFTC
        call    @READC
        cmp     al, [cs:@GWOEM_PBORD]
        je      @@ls_back
        cmp     al, byte [@ATRBYT]
        je      @@ls_old
        mov     byte [cs:@GWOEM_PNEW], 1
@@ls_old:
        call    @SETC
        inc     word [cs:@GWOEM_PCNT]
        jmp     @@ls_loop
@@ls_back:
        call    @RIGHTC
@@ls_done:
        mov     bx, [cs:@GWOEM_PCNT]
        mov     cl, [cs:@GWOEM_PNEW]
        pop     ax
        ret


; ---------------------------------------------------------------------------
; GET and PUT.  ADVGRP works out the rectangle and the array, writes the width
; in bits and the number of lines into the first four bytes, and then calls
; PGINIT once and NREAD or NWRITE for each line, moving down between them.  It
; rounds the width up to a byte -- "Round to byte boundry ... NOW CALC NO. OF
; BYTES PER SCAN LINE" -- so every line starts on one.

@GWOEM_PGBITS dw 0                      ; bits across a line of the image
@GWOEM_PGPTR  dw 0                      ; where the next byte goes or comes from
@GWOEM_PGACT  db 0                      ; 0 OR, 1 AND, 2 PRESET, 3 PSET, 4 XOR
@GWOEM_PGACC  db 0                      ; the byte being filled or emptied
@GWOEM_PGCNT  db 0                      ; how many of its bits are in hand
@GWOEM_PGSRC  db 0                      ; one pixel out of the image

; The value in AL at the current C, which is SETC without ATRBYT.
@GWOEM_PUTPX:
        push    ax
        push    bx
        push    es
        and     al, [cs:@GWOEM_GAMSK]
        mul     byte [cs:@GWOEM_GREP]
        mov     ah, [cs:@GWOEM_CMSK]
        and     al, ah
        not     ah
        mov     es, [cs:@GWOEM_VSEG]
        mov     bx, [cs:@GWOEM_CADR]
        and     ah, [es:bx]
        or      al, ah
        mov     [es:bx], al
        pop     es
        pop     bx
        pop     ax
        ret

; PGINIT - "[BC]=BIT COUNT,[HL]=ARRAY ADDR", AL the PUT option, and the carry
; telling a PUT from a GET.  Which of the two follows is in PUTFLG, so all this
; has to do is remember where and how wide.
@PGINIT:
        mov     [cs:@GWOEM_PGBITS], cx
        mov     [cs:@GWOEM_PGPTR], bx
        mov     [cs:@GWOEM_PGACT], al
        mov     byte [cs:@GWOEM_PGACC], 0
        mov     byte [cs:@GWOEM_PGCNT], 0
        ret

@GWOEM_PGSTO:                           ; the filled byte, into the array
        push    ax
        push    bx
        mov     bx, [cs:@GWOEM_PGPTR]
        mov     al, [cs:@GWOEM_PGACC]
        mov     [bx], al
        inc     word [cs:@GWOEM_PGPTR]
        mov     byte [cs:@GWOEM_PGACC], 0
        mov     byte [cs:@GWOEM_PGCNT], 0
        pop     bx
        pop     ax
        ret

@GWOEM_PGFET:                           ; and the next one out of it
        push    ax
        push    bx
        mov     bx, [cs:@GWOEM_PGPTR]
        mov     al, [bx]
        mov     [cs:@GWOEM_PGACC], al
        inc     word [cs:@GWOEM_PGPTR]
        mov     byte [cs:@GWOEM_PGCNT], 8
        pop     bx
        pop     ax
        ret

; One pixel of the image, in AL, against what is already on the screen.
@GWOEM_PGCOMB:
        push    ax
        push    bx
        mov     [cs:@GWOEM_PGSRC], al
        mov     bl, [cs:@GWOEM_PGACT]
        cmp     bl, 3
        je      @@pc_put                ; PSET takes the image as it is
        cmp     bl, 2
        jne     @@pc_read
        mov     al, [cs:@GWOEM_PGSRC]   ; PRESET takes it inverted
        not     al
        mov     [cs:@GWOEM_PGSRC], al
        jmp     @@pc_put
@@pc_read:
        call    @READC
        mov     bh, al
        mov     al, [cs:@GWOEM_PGSRC]
        or      bl, bl
        jnz     @@pc_and
        or      al, bh
        jmp     @@pc_save
@@pc_and:
        cmp     bl, 1
        jne     @@pc_xor
        and     al, bh
        jmp     @@pc_save
@@pc_xor:
        xor     al, bh
@@pc_save:
        mov     [cs:@GWOEM_PGSRC], al
@@pc_put:
        mov     al, [cs:@GWOEM_PGSRC]
        call    @GWOEM_PUTPX
        pop     bx
        pop     ax
        ret

; NREAD - one line of the screen into the array, the leftmost pixel in the top
; bits of the first byte.  The C goes back to where the line started, because
; the caller moves down from there.
@NREAD:
        push    ax
        push    bx
        push    cx
        push    dx
        call    @FETCHC
        push    bx
        push    ax
        mov     ax, [cs:@GWOEM_PGBITS]
        mov     cl, [cs:@GWOEM_GBPP]
        dec     cl
        shr     ax, cl                  ; bits across, over bits a pixel
        mov     cx, ax
        mov     byte [cs:@GWOEM_PGACC], 0
        mov     byte [cs:@GWOEM_PGCNT], 0
        jcxz    @@nr_flush
@@nr_loop:
        call    @READC
        mov     ah, al
        mov     al, [cs:@GWOEM_PGACC]
        push    cx
        mov     cl, [cs:@GWOEM_GBPP]
        shl     al, cl
        pop     cx
        or      al, ah
        mov     [cs:@GWOEM_PGACC], al
        mov     al, [cs:@GWOEM_GBPP]
        add     [cs:@GWOEM_PGCNT], al
        cmp     byte [cs:@GWOEM_PGCNT], 8
        jb      @@nr_next
        call    @GWOEM_PGSTO
@@nr_next:
        call    @GWOEM_GATRT
        jc      @@nr_edge
        call    @RIGHTC
@@nr_edge:
        loop    @@nr_loop
@@nr_flush:
        cmp     byte [cs:@GWOEM_PGCNT], 0
        je      @@nr_done
        mov     al, [cs:@GWOEM_PGACC]   ; push the tail up to the top of a byte
        push    cx
        mov     cl, 8
        sub     cl, [cs:@GWOEM_PGCNT]
        shl     al, cl
        pop     cx
        mov     [cs:@GWOEM_PGACC], al
        call    @GWOEM_PGSTO
@@nr_done:
        pop     ax
        pop     bx
        call    @STOREC
        pop     dx
        pop     cx
        pop     bx
        pop     ax
        ret

; NWRITE - and one line back out of it.
@NWRITE:
        push    ax
        push    bx
        push    cx
        push    dx
        call    @FETCHC
        push    bx
        push    ax
        mov     ax, [cs:@GWOEM_PGBITS]
        mov     cl, [cs:@GWOEM_GBPP]
        dec     cl
        shr     ax, cl
        mov     cx, ax
        mov     byte [cs:@GWOEM_PGCNT], 0
        jcxz    @@nw_done
@@nw_loop:
        cmp     byte [cs:@GWOEM_PGCNT], 0
        jnz     @@nw_have
        call    @GWOEM_PGFET
@@nw_have:
        mov     al, [cs:@GWOEM_PGACC]
        push    cx
        mov     cl, 8
        sub     cl, [cs:@GWOEM_GBPP]
        mov     ah, al
        shr     ah, cl                  ; the pixel at the top of the byte
        mov     cl, [cs:@GWOEM_GBPP]
        shl     al, cl                  ; and the rest shifted up behind it
        pop     cx
        mov     [cs:@GWOEM_PGACC], al
        mov     al, [cs:@GWOEM_GBPP]
        sub     [cs:@GWOEM_PGCNT], al
        mov     al, ah
        and     al, [cs:@GWOEM_GAMSK]
        call    @GWOEM_PGCOMB
        call    @GWOEM_GATRT
        jc      @@nw_edge
        call    @RIGHTC
@@nw_edge:
        loop    @@nw_loop
@@nw_done:
        pop     ax
        pop     bx
        call    @STOREC
        pop     dx
        pop     cx
        pop     bx
        pop     ax
        ret

; ---------------------------------------------------------------------------
; The devices this machine does not have, and the screen dump.

; POLLEV - GWSTS's CHKINT, which runs between statements: "CALL POLLEV ;Test
; for occurance of trapable events / JZ CHKINX ;Exit - no trapable event".
; Nothing here raises one, but the answer has to be given: left to the flags
; the caller arrived with, this reports an event that never happened and sends
; the interpreter off into the trap path.
@POLLEV:
        push    ax
        xor     al, al
        or      al, al                  ; ZF = 1: nothing has happened
        pop     ax
        ret

; RDPEN - the PEN function, and PEN ON and OFF, which arrive as 254 and 255.
; There is no light pen, so every question about one is answered with zero.
@RDPEN:
        xor     bx, bx
        ret

; RDSTIK, RDTRIG - STICK and STRIG.  Two sticks with an X and a Y each, so
; 0 to 3 are the ones that may be asked for; GWSTS turns the carry into
; "Illegal function call".  Nothing is plugged in, so they read as centred and
; unpressed.
@RDSTIK:
        cmp     al, 4
        jae     @@st_bad
        xor     bx, bx
        clc
        ret
@@st_bad:
        stc
        ret

@RDTRIG:
        xor     al, al                  ; 0/1 for not-pressed/pressed
        ret

; LCPY - the LCOPY statement, the screen to the printer, through the same DOS
; call SNDLPT uses.  A graphics screen is refused: there are no characters on
; it to send, and a printer that takes pixels is not something this layer can
; find out about.
@LCPY:
        cmp     byte [cs:@GWOEM_GMODE], 0
        jne     @@lc_bad
        push    ax
        push    bx
        push    cx
        push    dx
        mov     dl, 1
@@lc_row:
        mov     dh, 1
@@lc_col:
        call    @SCRINP
        or      al, al
        jnz     @@lc_send
        mov     al, " "                 ; an empty cell goes out as a space
@@lc_send:
        call    @SNDLPT
        inc     dh
        mov     al, [cs:@GWOEM_WIDTH]
        cmp     dh, al
        jbe     @@lc_col
        mov     al, 13
        call    @SNDLPT
        mov     al, 10
        call    @SNDLPT
        inc     dl
        mov     al, [cs:@GWOEM_HEIGHT]
        cmp     dl, al
        jbe     @@lc_row
        pop     dx
        pop     cx
        pop     bx
        pop     ax
        clc
        ret
@@lc_bad:
        stc
        ret

; The serial entry points.  There is no RS232 support here, and GIOCOM reads
; the answer out of AH: 255 is "Illegal Filename", 0 is no error, and 1 to 5
; index CMERRT, where 3 is a device timeout.  OPEN "COM1:" is answered with
; that -- a port with nothing behind it does time out -- so the statement is
; refused the same way every time.  Left to return on the flags it was called
; with, which error came back depended on what the caller had been doing.
;
; SETCBF above has already told GIOCOM that no buffer was reserved, and
; nothing gets past the open, but the rest answer for themselves rather than
; leave it to chance.
@INICOM:
        mov     ah, 3
        ret

@SNDCOM:
@TRMCOM:
        xor     ah, ah
        ret

@RECCOM:
        xor     ax, ax                  ; no error, and nothing to read
        ret

@STACOM:
        xor     ah, ah
        xor     cx, cx                  ; nothing queued, and no room for more
        xor     dx, dx
        ret

end if
