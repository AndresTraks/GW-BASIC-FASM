# Building GW-BASIC with fasm

The `.ASM` files and headers in the repository root have been converted from
their original MASM form to [fasm](https://flatassembler.net/) syntax. The
scripts here did that conversion.

**Building needs nothing but fasm, and a copy is included.** From the
repository root:

```sh
./assemble.sh                # or assemble.bat on Windows
```

That writes `bin/GWBASIC.COM`. `GWBASIC.ASM` is the master file: it `INCLUDE`s
every module in link order, so fasm assembles the whole interpreter in one pass
with no linker and no Python.

fasm 1.73.35 is vendored for both platforms in `fasm-1.73.35/`, so nothing
needs installing: `fasm.x64` and 32-bit `fasm` for Linux, `FASM.EXE` for
Windows, with the fasm licence alongside. `assemble.sh` picks the Linux binary
matching `uname -m`, falling back to a `fasm` on `PATH` and then to `FASM.EXE`
under wine; `FASM=...` overrides. All three produce the same image.

The scripts here are only needed to redo the conversion from the original MASM:

```sh
cd scripts
python3 make.py              # convert in place, assemble, verify
python3 make.py --check      # also assemble every module separately first
```

That regenerates the converted sources and the two generated files,
`GWBASIC.ASM` and `GWSTUB.INC`, then runs every check.

**The image runs.** See [Status](#status).

Regenerating requires Python 3. It uses the same vendored fasm as
`assemble.sh`, and `objdump` (binutils) for the `INS86` check, which skips
itself if absent.

## Generated files

Two files in the repository root are generated and should not be edited by hand:

- **`GWBASIC.ASM`** — the master. Includes `GWSTUB.INC` and then every module in
  link order: `GWDATA` first, because it opens the code segment at offset 0 with
  `BEGCSG` and does the `ORG 400O` that leaves room for the OS control block,
  with `START` right after; then `ITSA86`, `GWINIT` and `BIBOOT` last, in that
  order, because everything after `ITSA86`'s `CSEND` is overlaid at run time —
  see [The discardable tail](#the-discardable-tail).
- **`GWSTUB.INC`** — now only the nine self-referential assembly-time counters,
  seeded because MASM allows a counter to be read before its first assignment.
  There are no OEM stubs left: `GWOEM.ASM` defines them all.

Each converted module is `INCLUDE`d **twice**, and its code and data regions are
guarded by `if @GW_PASS = 1` and `if @GW_PASS = 2`. The reason is that fasm
writes its binary output in emission order — `org` only changes label values —
so every CSEG byte has to be emitted before any DSEG byte, while the modules
still have to be processed in document order for their `=` assignments to
resolve the way MASM resolved them. Two passes give both: pass 1 emits the code,
pass 2 emits the data at `org 0` so its labels are segment-relative while its
bytes land after the code. Macro definitions and calls are preprocessor-level in
fasm, so they happen in both passes regardless of which branch the assembler
takes.

DSEG's first 0x100 bytes are the program segment prefix that `GWINIT` has DOS
copy there (`INT 21h`, `AH=26h`); nothing is assembled into them, but they are
reserved explicitly because fasm does not pad for an `org` jump.

Each translation unit ends by purging its own macros, since MASM scopes macros
per file. All of that is in the files, which is what lets fasm build unaided.

### Four things `convert.py` patches

Three references cannot be expressed as LINK expressed them, and one storage
cell the OEM layer needs has no original to translate. Each is checked for
presence, so a source change cannot silently skip one.

- **`BEGDSG`.** `GWINIT` declares it `EXTRN :NEAR` although it lives in the data
  segment, so that `OFFSET BEGDSG` yields the distance from the start of CSEG to
  the start of DSEG — one symbol with two values, which LINK's separate frames
  allowed and a single flat address space cannot. It is pointed at the real
  distance instead.
- **The `DERMAK` chain terminator.** The chain works because each entry ends in
  `271o` (`0B9h`, `MOV CX,imm16`), which swallows the next entry's two-byte
  `MOV DL,imm8` — so entering anywhere runs that entry's `MOV DL` and skips the
  rest of the table. After the last entry MASM writes `ORG $-1` to overwrite the
  final, useless skip byte with the `JMP` that follows. fasm cannot rewind its
  output; it would emit both, leaving a stray `0B9h` and shifting every later
  byte. The last entry uses a variant macro that never emits the byte.
- **`GWRAM`'s `R1`.** It defines its label one byte *before* the storage it
  reserves, via `ORG $-1 / LABEL / ORG $+1`. The translator drops `ORG` from
  macro bodies, which left `R1` textually identical to `R` and put `MAXUPD` and
  `MINUPD` one byte too high — both are read by other modules. The offset is now
  stated directly as `NAME = $ - 1`.
- **`FKYFMB`, three bytes added to `GWRAM`.** `FKYFMT` has to hand `GETFMT` a
  pointer that `GETFMT` reads through `DS`, so the soft-key display format
  belongs in the data segment beside the rest of the key line's state. Nothing
  in the original reserved it. Patching it in rather than editing `GWRAM.ASM`
  keeps the hand edit from being lost the next time `convert.py` runs.

## Converting in place

`convert.py` overwrites the `.ASM` files and the five headers. It reads the
originals out of git rather than from the working tree — the revision in
`common.BASELINE`, which is the last commit before the conversion — so it is
re-runnable and does not depend on the tree's state. Re-running it reproduces
byte-identical sources and a byte-identical image.

That also means the analysis steps (`mksymtab`, `mkmacros`, `mkglobals`, and the
OEM scan in `link.py`) read the originals from git, since the converted files no
longer carry MASM's `PUBLIC`/`EXTRN`/`SEGMENT` syntax.

Conversion keeps everything that documents the code: the `COMMENT` blocks with
their copyright notices, `TITLE`/`SUBTTL`, and the `PUBLIC`/`EXTRN` interface of
each module, all as comments. Segment boundaries become `;;;SEG CSEG` /
`;;;SEG DSEG` markers, which is how `link.py` tells code from data.

To get the originals back:

```sh
git checkout edf82c2 -- '*.ASM' OEM.H BINTRP.H IBMRES.H GIO86U MSDOSU
```

## The build model

The repository ships no build scripts, but the sources document the intended
layout well enough to reconstruct it.

`BIBOOT.ASM` holds the entry point and says it "is included in the linker file
list AFTER all others, but is executed first since it is defined as the entry
point". `GWDATA.ASM` links first: it opens the code segment at offset 0 with
`BEGCSG`, puts the CP/M-style entry at `ORG 5O`, and then does `ORG 400O`
(octal, so 0x100) — "leave room in the CS for OS control block" — with `START:`
immediately after.

`GWINIT.ASM` spells out how the data segment is found:

```
MOV DX, OFFSET BEGDSG   ; BEGDSG is EXTRN :NEAR, so this is an offset from CS
MOV CL, 4
SHR DX, CL              ; -> paragraphs
MOV CX, CS
ADD DX, CX              ; DS base = CS + offset(DSEG)/16
MOV AH, 26h             ; "Create PSP" - copies the control block to DS:0
INT 21h
MOV DS, DX / MOV ES, DX / MOV SS, DX
```

So the program is **one flat image, CSEG followed by DSEG**, with `DS` derived
from `CS` at run time. The comment there warns that "the beginning of DATASG
MUST be within 64K of the beginning of CODESG ... No error will be generated, so
be careful." The trick is that `BEGDSG` is deliberately declared `EXTRN :NEAR`
in `GWINIT` although it lives in the data segment, so the same symbol resolves
to 0 in DSEG's frame and to the CSEG→DSEG distance in CSEG's.

It all fits one segment with room to spare — roughly 44.7K of code and tables
plus 2157 bytes (`0x086D`) of variables, leaving about 18K of the 64K segment
free. `link.py` prints the exact figures for the current sources.

### The discardable tail

The link order is not free, and getting it wrong destroys the program at run
time. `ITSA86` carries the label `CSEND`, with the comment "All code loaded
after this label is resident only until routine `MAPINI` initializes the new
memory map". `MAPCLC` computes

```
NEWDS = CS + paragraphs(CSEND) + COM buffer paragraphs
```

and `MAPINI` then moves the data segment there, **deliberately overlaying
everything linked after `CSEND`** so that the memory the initialisation code
occupied is reclaimed. Only initialisation code may follow it.

Three units qualify, and nothing else does. `ITSA86`'s own tail past `CSEND` is
`MAPCLC` and `SEGOFF`, both called only from `GWINIT`. `GWINIT`'s only entry
points are `INIT` and `CMDERR`, both startup-only; it also ends with
`$LAST=$ / LASTWR=$`, which is a link-map marker for the end of the image, so
this is the original order too. `BIBOOT` is the `.EXE` entry point, which a
`.COM` image never uses — its own comment says it "is included in the linker
file list AFTER all others" — and it stays last of the three because `LSTVAR`,
which BASIC reads as the end of its data segment, is the last label in its
DSEG. `GWOEM` goes *before* `ITSA86`, because the drivers are resident.

With the modules in plain alphabetical order, `CSEND` fell in the middle of the
image and `MAPINI` wrote the data segment over 14K of live code — `MATH1`,
`MATH2`, `SCNDRV` and `GWOEM` among it. That was the hang after the sign-on
banner: the "Bytes free" message is printed from `MAPINI` itself, so the number
formatting ran through bytes that had just been overwritten.

`MATH1` and `MATH2` are one translation unit, not two: `MATH2` has no `EXTRN`,
no segment header and no `.RADIX`, starts mid-routine, references `$DP06` which
`MATH1` defines, and `MATH1` declares `PUBLIC DMULT` for a label `MATH2`
defines. The original was `MASM MATH1+MATH2;`. `convert.py` translates the two
as one stream and cuts the result apart again, so the second file is translated
in the context the first establishes.

## Why a single translation unit

fasm has no linker and emits a flat binary directly, so all 34 units are
concatenated and fasm resolves every cross-reference itself. That means MASM's
file scoping has to be reimplemented, because concatenation makes everything
global:

- **Symbols.** A name is global *for module M* only if M itself declares it
  `PUBLIC` or `EXTRN` — LINK's rule, applied per module. Everything else is
  tagged `@MODULE@_name`. A global union would be wrong: 29 names are `PUBLIC`
  in one module and a private label in another. The dangerous one is `TRMCOM`,
  which `GIOCOM` imports as an OEM routine while `GWSTS` uses it as a private
  label for comma handling — merged naively, that call binds to the wrong
  routine and still assembles.
- **Macros** are file-scoped too, so each unit ends with `purge` lines.
  Otherwise `GENGRP`'s `NEGHL` label collides with another module's `NEGHL`
  macro.
- **`??Lnnn` labels** restart at 000 in each of 14 files. They are emitted by
  Microsoft's own 8080→8086 translator, the tool named in every file's first
  line (`[ This translation created 12-Jan-83 by Version 4.3 ]`).
- **Module-local `=` names** are scoped as well: `SCNEDT`'s `STPTRP=0` feature
  switch shadows `BIMISC`'s `PUBLIC STPTRP` label. Names the headers define stay
  shared, since every module re-`INCLUDE`s them.

## Naming

Every MASM symbol is renamed by one context-free function:

```
ESC(n)   = n.replace("@","@@").replace("$","@S").replace("?","@Q")
FNAME(n) = "@" + ESC(n)
```

`@` occurs in no GW-BASIC identifier, so the map is injective, and every result
starts with `@`, so no symbol can collide with a fasm keyword. Module-local
names get `@MODULE@_` instead: `ESC` only ever emits `@@`, `@S` or `@Q` after an
`@`, so `@_` cannot occur in its output and a tagged local can never collide
with a global.

Macro arguments split by role: a parameter used to *build* a name (`$&RESWRD`)
is passed escaped but unprefixed and the macro supplies the prefix, while a
parameter used as a *value* (`DW RESDSP`) is passed fully renamed.

A few header macros rely on MASM text machinery (`IRPC`, `IFB`/`IFNB`, `&`
concatenation) with no mechanical fasm equivalent — `INS86`, `DC`, `CALLOS` and
the `T`/`Q`/`QF`/`R`/`R2` reserved-word table macros. `headers.py` holds
hand-written fasm replacements, which `convert.py` substitutes.

## Verification

Assembling cleanly proves little, so `checktable.py` checks the one part of the
output that is self-describing: the reserved-word table. Each entry is the
keyword with its first character dropped (the table is indexed by initial
letter — MASM does the same via an `IF $F` that is false on the first `IRPC`
iteration) and the high bit set on the last, followed by a token byte. The
expected token for every word is derived by simulating MASM's `QQ` counter over
the `R`/`R2`/`T` sequence, independently of the translator.

126 of 143 entries verify exactly, 0 wrong; the other 17 are hand-written `DB`
entries in the source (`GO TO`, `SPC(`, `TAB(` and the operators). `link.py` also
checks six layout invariants against what the sources document, including
`LSTVAR` — defined in `BIBOOT`, which links last — landing exactly at the DSEG
size, which validates the DSEG chain's ordering across all 34 units.

`checkins86.py` checks the other high-risk piece. `INS86` is hand-encoded
machine code — the 8080→8086 translator emitted raw opcode bytes where it could
not express something — and 112 of its 127 sites carry a comment naming the
instruction those bytes are meant to be. `@INS86` is one of the four
hand-written macros, and a wrong encoding there still assembles, so each site's
emitted bytes are disassembled (`objdump -m i8086`) and compared against a
disassembly of what fasm produces from the commented mnemonic. Comparing
disassembly rather than bytes is necessary: x86's direction bit gives two valid
encodings for a reg,reg operation, and the hand-written opcodes consistently
pick the opposite one from fasm.

36 sites verify, 0 mismatch, and 2 are recorded exceptions checked by hand —
one where the immediate arrives in the following `DB` lines, and one where the
1983 comment reads `OR BX,BX` for bytes that are `OR BX,DX` (the surrounding
`AND BX,DX` and `XOR BX,DX` confirm the bytes, not the comment). The rest of
the comments are prose like "FETCH FROM CODE SEGMENT" and name intent rather
than a mnemonic.

`checkdseg.py` checks where the data segment landed. Mapping a DSEG label to a
file offset is indirect — `file offset = (DSEG base - 100h) + label` — and
getting it wrong shifts the whole data segment without affecting whether the
image assembles. Four initialisers with distinctive values are read back out of
the image and compared with the sources. This is the check that caught both the
`DERMAK` and `R1` defects above: each shifted the image by one byte, which
showed up as a one-byte skew in every DSEG probe.

`make.py --check` additionally assembles every module on its own, which gives
per-module attribution when a change breaks something.

## Status

All 35 files convert and assemble, the whole program links as one unit, every
symbol resolves with no stubs left, and **the interpreter runs**. Booted from an
MS-DOS 1.25 floppy under QEMU:

```
GW-BASIC
(C) Copyright Microsoft 1982
62842 Bytes free
Ok
RUN
 1  3  4  5  9  7  16  9  25  11
SUB
Ok
```

Exercised and correct: integer and floating-point arithmetic, `SQR` `ATN` `^`,
`LEFT$` `MID$` `LEN` `ASC` `CHR$` `STR$` `VAL` `INSTR` `STRING$` and
concatenation, `MID$` assignment, `PRINT` with both separators, `PRINT USING`,
`DIM` and arrays, `SWAP`, `FOR`/`NEXT`/`STEP`, `WHILE`/`WEND`,
`IF`/`THEN`/`ELSE` nested and chained, `READ`/`DATA`/`RESTORE`, `ON GOTO` and
`ON GOSUB`, `DEF FN`, `ON ERROR`/`RESUME` with `ERR` and `ERL`, `&H` and `&O`,
`LIST`, `RUN`, `END`, `SYSTEM`, multi-statement lines, the screen editor and
scrolling, and disk `SAVE`/`LOAD`/`OPEN`/`PRINT #`/`CLOSE` — the whole of
`GIODSK` and the FCB-based DOS calls.

All twelve BASIC programs on the MS-DOS 1.25 sample disk run: ART, BALL,
CALENDAR, CIRCLE, COLORBAR, COMM, DONKEY, MORTGAGE, MUSIC, PIECHART, SAMPLES
and SPACE. COMM gets as far as its menu; dialling a service needs the serial
port, which is not implemented.

One number cannot be confirmed here. `PRINT 1/3` gives `.3333334`.
`PRINT .3333333` round-trips exactly, and `PRINT 1/3-.3333333` is
`2.980232E-08` — exactly one ulp — so `FOUT` is rendering faithfully what the
divide produced; whether the retail binary's single-precision divide lands on
the other side of that boundary is not something this repository can answer.

### The OEM layer

GW-BASIC is machine independent, and each OEM supplied the driver layer beneath
it. That layer is not in this repository: 66 symbols are imported but never made
`PUBLIC` by any module, and the sources label them as such (`EXTRN SCROUT:NEAR ;
OEM supplied character output`).

(An `EXTRN` counts as satisfied only by a `PUBLIC`; a private label of the same
name elsewhere does not satisfy it. `TRMCOM` is exactly that case — `GIOCOM`
imports the OEM routine while `GWSTS` has an unrelated private label — which is
why the count is 66 rather than 65.)

`GWOEM.ASM` is a reconstruction of that layer for the IBM PC, written against
the BIOS and the video buffer. Every contract in it is taken from a call site,
which is cited with the routine — for example SCNDRV's
`CALL SCROUT ; Send char in AX to BIOS at DX posn`, and `MOV BYTE PTR CSRY,DL /
MOV BYTE PTR CSRX,DH` which is what establishes that DL is the row and DH the
column, both 1-based.

It covers:

- **Screen.** `SCROUT` `SCRINP` `CLREOL` `CLRSCN` `SCROLL` `CSRDSP` `SWIDTH`
  `SCRSTT` `PRTMAP` `EDTMAP`, in text mode and on both CGA graphics screens.
- **Graphics.** `MAPXYC` `SCALXY` `SETC` `READC` `STOREC` `FETCHC` `NSETCX`
  `UPC` `DOWNC` `LEFTC` `RIGHTC` `TUPC` `TDOWNC` `PIXSIZ` `GRPSIZ` `GTASPC`,
  `PNTINI` `SCANR` `SCANL` for `PAINT`, and `PGINIT` `NREAD` `NWRITE` for
  `GET`/`PUT`. SCREEN 1 is 320×200 in four colours, SCREEN 2 640×200 in two.
- **Colour.** `SETATR` `GETFBC` `SETFBC` `SETCLR` `SCRATR` `CSRATR`, over the
  full 0–15 text range with the blink bit.
- **Keyboard.** `KEYINP` `INKMAP` `INFMAP` `MAPSUP` `FKYADV` `FKYFMT`: the
  arrow and editing keys, F1–F10 as soft keys, Ctrl+Left/Right/Home/End as the
  word and line functions, and Alt+letter as the super-shift keyword expansion,
  which `MAPSUP` resolves to the first reserved word for the letter -- Alt-A to
  `AUTO`, as the IBM keyboard does.
- **Sound.** `DONOTE`, through channel 2 of the timer. A background note --
  `PLAY "MB"` -- is queued and drained by the timer tick, INT 1Ch, so the
  program runs on while it sounds.
- **Serial.** `INICOM` `SNDCOM` `RECCOM` `STACOM` `TRMCOM`, on the 8250.
  Reception is interrupt driven, IRQ4 for COM1 and IRQ3 for COM2, into a ring
  of 256 bytes per channel, which is what `LOC`, `INPUT$` and `ON COM(n)` read.
- **The rest.** `SNDLPT` `LCPY` `POLLEV` `GWINI` `GETHED` `GWTERM` `SEGINI`
  `SETCBF` `PEKFLT` `POKFLT`.

Three of those contracts took finding, and all three are cases where the
sources say what is needed if you look in the right place.

- **The keyboard has to come from DOS, not from `INT 16h`.** MS-DOS 1.25's
  IO.SYS takes over `INT 9` and queues scan codes itself, so the BIOS buffer at
  `40:1A` stays permanently empty and `INT 16h` never reports a key — the
  interpreter polled forever and nothing could be typed. `MSDOSU` declares
  exactly two console/printer calls, `C_DCIO=6 ;Direct console I/O` and
  `C_PRTO=5 ;Printer output`, which is why they are declared: `KEYINP` uses
  `INT 21h AH=06` with `DL=0FFh`, and `SNDLPT` uses `AH=05`. `POLKEY`'s own test
  of `MSDCCF`, "MSDOS Ctl-C Interrupt flag", says the same thing.
- **`GWINI` must call `SCNSWI`, and `CLRSCN` must call `SCNCLR`.** Both are
  `PUBLIC` in `SCNDRV` and called from nowhere in GW-BASIC, so the OEM layer is
  the only thing that can call them. `SCNSWI` ("Set CRT physical line width ...
  on entry: AL=width, CL=height") sets `LINLEN` as well as `CRTWID` and reserves
  the last line for the function-key display with `DEC CL ; Reserve status
  line`. `SCNCLR` runs `TTBINI` over the line terminator table, homes both
  cursors and refreshes the soft-key line. That one matters: `LINTTB` is
  uninitialised storage and a zero entry reads as a `TRMWRP` terminator, so
  until `TTBINI` has run every physical line looks like a continuation of the
  one above it, and the first ENTER sent the cursor to the bottom of the screen.
- **`CHR$(255)` is a function, not a character.** `GWMAIN` prints it after the
  `Ok` prompt — `MOV AL,LOW 377O / CALL OUTDO ;FLAG AS NOT USER INPUT` — and
  `BIMISC` after a listed line; `CTLNMK` answers it by setting `TRMNUL` on that
  line's terminator so ENTER on it does not resubmit it. `PRTMAP` therefore
  reports 255 with `AH=255` alongside the control codes and DEL. The byte still
  reaches the screen, because the 1983 source has the suppressing `STC`
  commented out — but glyph 255 in the IBM character ROM is blank, so on real
  hardware nothing shows.

`POLLEV` is worth singling out, because CHKINT runs it between statements and
everything else there is behind it -- "CALL POLLEV ;Test for occurance of
trapable events / JZ CHKINX ;Exit - no trapable event". Answering "nothing"
unconditionally switches off every trap in the language, `ON KEY` and `ON COM`
alike. There is no single BIOS flag to read here, so it asks the two sources
that exist: a byte sitting in a COM ring, and MS-DOS call 11, "console input
status", which reports a waiting key without taking it.

Not implemented, and answering as absent hardware: the light pen (`RDPEN`) and
the joysticks (`RDSTIK`, `RDTRIG`). One routine is partial: `LCPY` prints the
text screen but refuses a graphics one.

### Does it need a later MS-DOS?

The retail GW-BASIC 3.2x binaries do require a later DOS, but **this 1983 source
does not**. Every DOS call it makes is declared in `MSDOSU`, and the highest is
41 (`0x29`, Parse Filename); they are all FCB-based DOS 1.x calls, with no
handle I/O, no subdirectories and nothing from DOS 2. `GWINIT` additionally uses
`INT 21h AH=26h`. MS-DOS 1.25's dispatch table has 47 entries, 0 through `0x2E`,
and entry 38 is `NEWBASE` — so every call this source makes is available.

One version difference does matter. MS-DOS 1.25's `NEWBASE` documents its
outputs as "DS = DX, ES = DX ... DX,BP unchanged. All other registers
destroyed", so it sets `DS` itself. `GWINIT` follows the call with
`MOV AX,DS` to keep the *old* `DS` for the exit vector, which on 1.25 therefore
captures the new segment instead of the program segment prefix. That corrupts
the exit vector, not the startup.

`GETHED` leaves `KEYSW` alone. `GWINIT` sets it to 255 just before calling
`GETHED` — "if heading is printed, display Fn keys also" — and then calls
`SKEYON`, which walks the ten soft keys through `FKYFMT`, so the key line comes
up with the heading as it does on the IBM machines.

### Debugging it

Setting `@GWOEM_TRACE` to 1 makes each entry point stamp a character into the
bottom screen line — a fixed cell per routine, plus a wrapping chronological
trace on the line above. It needs no part of GW-BASIC, so it works when nothing
else does, and reading the order of calls out of video memory is what located
every fault below. The second tool is QEMU's `-d in_asm,cpu` log: run-length
encoding the `CS:EIP` it reports per translation block gives an execution path
to walk backwards from.

### Six translator bugs the running image exposed

Each of these assembled cleanly and would never have been found statically.

- **Counter seeding destroyed forward references.** `GWSTUB.INC` used to seed
  every assembly-time counter to 0 — 768 of them. fasm's `=` is positional, so
  defining a name as 0 up front means an earlier reference reads the 0 instead
  of resolving forward to the real value on a later pass. `GWDATA` computes
  `CNSLEN = ENDCNS - CONSTR` before either exists, so the constants block came
  out zero-length and `GWINIT` copied 3 bytes instead of 104. Only
  self-referential counters (`X = X + n`) actually need a seed; there are 9.
- **`JMP`/`CALL WORD PTR <mem>` became direct jumps.** Jump operands are
  normally labels, so bracketing was suppressed for them — but an explicit size
  override always denotes memory in MASM. `JMP WORD PTR IOJUMP`, the final
  instruction of `TBLDSP` and the dispatch through which *every* device I/O
  call passes, was assembling as a direct jump to the variable's address. That
  is what the earlier hang at `CS:0182` was: a jump into the middle of the
  error-message text. Six sites were affected.
- **Data in the code segment was read from the data segment.** MASM resolves a
  symbol's segment and, under `ASSUME CS:CSEG / DS:DSEG`, emits a `CS:` override
  automatically when code reads data that lives in CSEG. fasm has no `ASSUME`,
  so those reads went to the data segment and returned whatever was at that
  offset. `SCNDRV`'s `MOV AX,WORD PTR FUNTAB[BX]` — the control-function
  dispatch, which decides what a carriage return does — is one of six such
  sites; `mkcsdata.py` now identifies CSEG data labels and the translator
  restores the override. This is what made the banner lay out properly instead
  of printing CR and LF as glyphs.
- **Device ids were stubbed to zero.** `$_KYBD`, `$_LPT1` and `$_COM1` are not
  routines but numbers, defined by `GIOTBL`'s `DEV` macro counting down from
  `377o`; and the prefix of a concatenated name was being module-tagged, so
  `GIOTBL` defined `@GIOTBL@_@S_LPT1` while `GIO86` read `@@S_LPT1`.
- **A listing directive hid a table from the CSEG scan.** `mkcsdata.py` treats a
  label alone on its line as data if storage follows, but `$FOTB:` is followed by
  `.RADIX 10` and only then by the table, so it was classified as code and read
  from DSEG. It is `$FOTNV`'s bracket control table, which decides how many
  powers of ten to apply to get the printable digits into the integer part.
- **`XLAT` and the string instructions take an operand only to name a
  segment.** The address is fixed — `BX`, or `SI` and `DI` — and MASM emits the
  override that the operand's segment implies. All twelve sites name `?CSLAB`,
  which `GWSTS` and `MATH1` define in CSEG as "Code segment dummy label", and
  the comments say it outright: `FETCH FROM CS`, `MUST FETCH FROM CODE SEGMENT`.
  The translator was dropping the operand and emitting bare `xlatb`, `lodsw` and
  `movsw`, so the **entire floating-point library read its constants out of
  DSEG** — the bracket control table, the powers of ten, the polynomial
  coefficients for `LOG`, `EXP`, `SIN` and `ATN`. Every float printed as seven
  zero-padded digits with no decimal point, and dividing by a power of ten
  divided by zero. `mkcsdata.py` now collects these operands too, and the
  translator writes the address out — `lods word [cs:si]` — which is how fasm
  spells the same two bytes.

## Files

`fasm-1.73.35/` in the repository root holds the assembler itself for both
platforms, with the fasm licence, which permits redistribution as long as the
copyright notices stay.

| file | |
|---|---|
| `make.py` | runs everything below in order |
| `common.py` | paths, fasm invocation, extracting the originals from git |
| `units.py` | which files form one translation unit, and the link order, including the forced tail |
| `masm2fasm.py` | the translator; per-module or single-unit mode |
| `headers.py` | hand-written fasm replacements for the untranslatable macros |
| `mksymtab.py` | classifies symbols as code/data/const from `EXTRN :NEAR` vs `:WORD` |
| `mkmacros.py` | every macro name defined in the sources |
| `mkglobals.py` | per-module `PUBLIC` ∪ `EXTRN` sets |
| `mkcsdata.py` | labels living in CSEG whose reads need a `CS:` override |
| `convert.py` | translates the sources in place, writes `GWBASIC.ASM` and `GWSTUB.INC` |
| `build.py` | assembles each module separately (regression check) |
| `link.py` | assembles `GWBASIC.ASM` and reports sizes and invariants |
| `checktable.py` | verifies the reserved-word table against the originals |
| `checkins86.py` | verifies the INS86 encodings against their own comments |
| `checkdseg.py` | verifies where DSEG's initialisers landed in the image |
