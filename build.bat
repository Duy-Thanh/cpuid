:: Build cpuid
:: MAKE SURE YOU HAVE INSTALLED NASM AND MINGW64 (YOU CAN GRAB MINGW64 FROM WINLIBS DOT COM)
::
:: cpuid.asm - Tools to read CPUID
:: Copyright (C) 2026 Nekkochan (ThanhDN). All right reserved
::
:: THIS PROGRAM RUN ON 64-BIT OPERATING SYSTEM ONLY!!!
::

@echo off

nasm -f win64 cpuid.asm -o cpuid.obj
gcc cpuid.obj -o cpuid.exe

echo cpuid.exe built!

@echo on