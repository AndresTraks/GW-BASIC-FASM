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

**The image links but does not run.** See [Status](#status).

Regenerating requires Python 3. It uses the same vendored fasm as
`assemble.sh`, and `objdump` (binutils) for the `INS86` check, which skips
itself if absent.

## Generated files

Two files in the repository root are generated and should not be edited by hand:

- **`GWBASIC.ASM`** — the master. Includes `GWSTUB.INC` and then every module in
  link order: `GWDATA` first, because it opens the code segment at offset 0 with
  `BEGCSG` and does the `ORG 400O` that leaves room for the OS control block,
  with `START` right after; `BIBOOT` last, because it is the entry point and its
  own comment says it "is included in the linker file list AFTER all others".
- **`GWSTUB.INC`** — the 66 OEM symbols stubbed to 0, and the assembly-time
  counters seeded to 0 because MASM allows a counter to be read before its first
  assignment.

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

### Three references that had to be rewritten

`convert.py` patches three things that cannot be expressed as LINK expressed
them. Each is checked for presence, so a source change cannot silently skip one.

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

Measured sizes confirm it all fits one segment:

```
CSEG  code+tables   0x0100 .. 0xADA0    44190 bytes
DSEG  variables     0x0000 .. 0x086D     2157 bytes
top of DSEG from CS:0 = 0xB60D           headroom in 64K: 18931 bytes
```

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

All 35 files convert and assemble, the whole program links as one unit, and
**every symbol now resolves — there are no stubs left**. The image loads under
MS-DOS 1.25 and starts executing. It does **not** yet reach the `Ok` prompt.

### The OEM layer

GW-BASIC is machine independent, and each OEM supplied the driver layer beneath
it. That layer is not in this repository: 66 symbols are imported but never made
`PUBLIC` by any module, and the sources label them as such (`EXTRN SCROUT:NEAR ;
OEM supplied character output`).

(An `EXTRN` counts as satisfied only by a `PUBLIC`; a private label of the same
name elsewhere does not satisfy it. `TRMCOM` is exactly that case — `GIOCOM`
imports the OEM routine while `GWSTS` has an unrelated private label — which is
why the count is 66 rather than 65.)

`GWOEM.ASM` is a reconstruction of the **text-mode part** of that layer for the
IBM PC, written against the BIOS and the video buffer. Every contract in it is
taken from a call site, which is cited with the routine — for example SCNDRV's
`CALL SCROUT ; Send char in AX to BIOS at DX posn`, and `MOV BYTE PTR CSRY,DL /
MOV BYTE PTR CSRX,DH` which is what establishes that DL is the row and DH the
column, both 1-based.

Implemented: `SCROUT` `SCRINP` `CLREOL` `CLRSCN` `SCROLL` `CSRDSP` `SWIDTH`
`PRTMAP` `EDTMAP` `KEYINP` `SNDLPT` `GWINI` `GETHED` `GWTERM` `SEGINI` `SETCBF`
`PEKFLT` `POKFLT`.

Deliberately not implemented, and returning harmlessly: the CGA pixel
primitives, colour and attribute handling, sound, the light pen, the joysticks
and the serial port. `SCRSTT` refuses every screen mode, so the graphics
primitives are unreachable. The keyboard map routines (`INKMAP`, `INFMAP`,
`MAPSUP`, `FKYADV`, `FKYFMT`) do nothing, because their contracts are not
established from the call sites — guessing them would be worse than leaving the
arrow keys and function keys out.

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

### Where it stops

Booted from an MS-DOS 1.25 floppy under QEMU, `GWBASIC` loads, initialises, and
prints its sign-on banner, correctly laid out on two lines:

```
GW-BASIC
(C) Copyright Microsoft 1982
```

So the whole startup path works, characters reach the screen through `OUTDO`,
the device dispatch, `SCNDRV` and `SCROUT`, and the control-character
dispatch through `FUNTAB` handles carriage return and linefeed.

It does not reach the `Ok` prompt: after the banner it hangs. The soft-key
display was ruled out — `SKEYON` walks the ten function keys through `FKYFMT`
and `FKYADV`, which are not implemented here, and the half-drawn `"LPT1:"` (F6's
default assignment) used to appear at the bottom of the screen. `GETHED` now
clears `KEYSW` to decline that display, which removes the artifact but not the
hang, so the remaining fault is after `KEYSOF`, on the way into or inside the
main loop at `INITSA`.

Setting `@GWOEM_TRACE` to 1 makes each entry point stamp a character into the
bottom screen line. It needs no part of GW-BASIC, so it works when nothing else
does.

### Four translator bugs the running image exposed

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

## Files

`fasm-1.73.35/` in the repository root holds the assembler itself for both
platforms, with the fasm licence, which permits redistribution as long as the
copyright notices stay.

| file | |
|---|---|
| `make.py` | runs everything below in order |
| `common.py` | paths, fasm invocation, extracting the originals from git |
| `units.py` | which files form one translation unit, and the link order |
| `masm2fasm.py` | the translator; per-module or single-unit mode |
| `headers.py` | hand-written fasm replacements for the untranslatable macros |
| `mksymtab.py` | classifies symbols as code/data/const from `EXTRN :NEAR` vs `:WORD` |
| `mkmacros.py` | every macro name defined in the sources |
| `mkglobals.py` | per-module `PUBLIC` ∪ `EXTRN` sets |
| `mkcsdata.py` | data labels living in CSEG, which need a `CS:` override |
| `convert.py` | translates the sources in place, writes `GWBASIC.ASM` and `GWSTUB.INC` |
| `build.py` | assembles each module separately (regression check) |
| `link.py` | assembles `GWBASIC.ASM` and reports sizes and invariants |
| `checktable.py` | verifies the reserved-word table against the originals |
| `checkins86.py` | verifies the INS86 encodings against their own comments |
| `checkdseg.py` | verifies where DSEG's initialisers landed in the image |
