:: Set current directory and paths
::@echo off
C:
CD %~dp0
CD ..\

copy .\dot\ESPRESET. ..\tbblue\dot\ESPRESET
copy .\build\readme.txt  ..\tbblue\src\asm\espreset\*.*
copy .\build\get*.??t  ..\tbblue\src\asm\espreset\build\*.*
copy .\build\*.config  ..\tbblue\src\asm\espreset\build\*.*
copy .\build\cspect*.bat  ..\tbblue\src\asm\espreset\build\*.*
copy .\build\builddot.bat  ..\tbblue\src\asm\espreset\build\*.*
copy .\build\*.bas  ..\tbblue\src\asm\espreset\build\*.*
copy .\src\asm\*.asm  ..\tbblue\src\asm\espreset\src\asm\*.*

pause