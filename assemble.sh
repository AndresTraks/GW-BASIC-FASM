#!/bin/sh
# Assemble GW-BASIC into bin/GWBASIC.COM.  Needs nothing but fasm, a copy of
# which is included in fasm-1.73.35/ for Linux (fasm.x64, fasm) and Windows
# (FASM.EXE).
#
# The sources here are fasm; GWBASIC.ASM includes every module in link order.
# See scripts/README.md for how they were converted from the original MASM,
# and for what of the resulting interpreter has been exercised.
#
# Set FASM to override, e.g. FASM=fasm or FASM="wine /path/to/FASM.EXE".
set -e
cd "$(dirname "$0")"

if [ -n "$FASM" ]; then
    :
elif [ "$(uname -m)" = "x86_64" ] && [ -x fasm-1.73.35/fasm.x64 ]; then
    FASM=./fasm-1.73.35/fasm.x64
elif [ -x fasm-1.73.35/fasm ] && { [ "$(uname -m)" = "i686" ] || [ "$(uname -m)" = "i386" ]; }; then
    FASM=./fasm-1.73.35/fasm
elif command -v fasm >/dev/null 2>&1; then
    FASM=fasm
elif command -v wine >/dev/null 2>&1 && [ -f fasm-1.73.35/FASM.EXE ]; then
    FASM="wine fasm-1.73.35/FASM.EXE"
    WINEDEBUG=${WINEDEBUG:--all}
    export WINEDEBUG
else
    echo "No usable fasm found. Install fasm and set FASM=fasm." >&2
    exit 1
fi

mkdir -p bin
$FASM GWBASIC.ASM bin/GWBASIC.COM
