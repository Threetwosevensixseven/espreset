:: Set current directory
@echo off
C:
CD %~dp0

:: Write date, time and git version into asm file for next build
ZXVersion.exe

:: Arguments passed from Zeus or command line:
::   -c   Launch CSpect
::   -e   Real ESP (add -com arg to CSpect)
set cspect=0
set realesp=0
for %%a in (%*) do (
  if "%%a"=="-c" set cspect=1
  if "%%a"=="-e" set realesp=1
) 

:: User real ESP if option was set
set serarg=""
if %realesp% equ 0 goto NoRealESP
set serarg="-com=\"COM5:115200\" "
:NoRealESP

:: Launch CSpect if option was set
if %cspect% equ 0 goto NoCSpect
pskill.exe -t cspect.exe
hdfmonkey.exe put C:\spec\cspect-next-2gb.img ..\dot\espreset dot
hdfmonkey.exe put C:\spec\cspect-next-2gb.img ..\dot\espreset dot\extra
hdfmonkey.exe put C:\spec\cspect-next-2gb.img autoexec.bas nextzxos\autoexec.bas
hdfmonkey.exe put C:\spec\cspect-next-2gb.img terminal-a.bas demos\uart\terminal-a.bas
cd C:\spec\CSpect2_12_1
CSpect.exe -w2 -zxnext -nextrom -basickeys -exit -brk -tv %serarg%-mmc=..\cspect-next-2gb.img
:NoCSpect

::pause
