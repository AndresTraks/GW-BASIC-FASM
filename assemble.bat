@echo off
rem Assemble GW-BASIC into bin\GWBASIC.COM.  Needs nothing but fasm, a copy of
rem which is included in fasm-1.73.35\ for Windows (FASM.EXE) and Linux.
rem
rem The sources here are fasm; GWBASIC.ASM includes every module in link order.
rem See scripts\README.md for how they were converted from the original MASM,
rem and for what of the resulting interpreter has been exercised.
rem
rem Set FASM to override, e.g. set FASM=C:\fasm\FASM.EXE
setlocal
cd /d "%~dp0"

if "%FASM%"=="" set FASM=fasm-1.73.35\FASM.EXE
if not exist bin mkdir bin
%FASM% GWBASIC.ASM bin\GWBASIC.COM
if errorlevel 1 exit /b 1
