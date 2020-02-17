; main.asm

;  Copyright 2020 Robin Verhagen-Guest
;
; Licensed under the Apache License, Version 2.0 (the "License");
; you may not use this file except in compliance with the License.
; You may obtain a copy of the License at
;
;     http://www.apache.org/licenses/LICENSE-2.0
;
; Unless required by applicable law or agreed to in writing, software
; distributed under the License is distributed on an "AS IS" BASIS,
; WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
; See the License for the specific language governing permissions and
; limitations under the License.
                                                        ; Assembles with regular version of Zeus (not Next version),
zeusemulate             "Next", "RAW", "NOROM"          ; because that makes it easier to assemble dot commands
zxnextmap -1,DotCommand8KBank,-1,-1,-1,-1,-1,-1         ; Assemble into Next RAM bank but displace back down to $2000
zoSupportStringEscapes  = true;                         ; Download Zeus.exe from http://www.desdes.com/products/oldfiles/
optionsize 10
CSpect optionbool 15, -10, "CSpect", false              ; Option in Zeus GUI to launch CSpect
RealESP optionbool 80, -10, "Real ESP", false           ; Launch CSpect with physical ESP in USB adaptor
ErrDebug optionbool 160, -10, "Debug", false            ; Print errors onscreen and halt instead of returning to BASIC

org $2000
Main                    proc                            ; Dot commands always start at $2000
                        jr Begin
                        db "ESPRESETv1."                ; Put a signature and version in the file in case we ever
                        BuildNo()                       ; need to detect it programmatically
                        db 0
Begin:                  di                              ; We run with interrupts off apart from printing and halts
                        ld (Return.Stack1), sp          ; Save so we can always return without needing to balance stack
                        ld (Return.IY1), iy             ; Put IY safe, just in case
                        ld sp, $4000                    ; Put stack safe inside dot command

                        ld (SavedArgs), hl              ; Save args for later

                        call InstallErrorHandler        ; Handle scroll errors during printing and API calls
                        PrintMsg(Msg.Startup)           ; "ESP Update Tool v1.x"

                        ld a, %0000 0001                ; Test for Next courtesy of Simon N Goodwin, thanks :)
                        MirrorA()                       ; Z80N-only opcode. If standard Z80 or successors, this will
                        nop                             ; be executed as benign opcodes that don't affect the A register.
                        nop
                        cp %1000 0000                   ; Test that the bits of A were mirrored as expected
                        ld hl, Err.NotNext              ; If not a Spectrum Next,
                        jp nz, Return.WithCustomError   ; exit with an error.
                        ld a, 1
                        ld (IsNext), a

                        NextRegRead(Reg.MachineID)      ; If we passed that test we are safe to read machine ID.
                        and %0000 1111                  ; Only look at bottom four bits, to allow for Next clones
                        cp 10                           ; 10 = ZX Spectrum Next
                        jp z, IsANext                   ;  8 = Emulator
                        cp 8                            ; Exit with error if not a Next. HL still points to err message,
                        jp nz, Return.WithCustomError   ; be careful if adding code between the Next check and here!
IsANext:
                        NextRegRead(Reg.Peripheral2)    ; Read Peripheral 2 register.
                        ld (RestoreF8.Saved), a         ; Save current value so it can be restored on exit.
                        and %0111 1111                  ; Clear the F8 enable bit,
                        nextreg Reg.Peripheral2, a      ; And write the entire value back to the register.

                        NextRegRead(Reg.CPUSpeed)       ; Read CPU speed.
                        and %11                         ; Mask out everything but the current desired speed.
                        ld (RestoreSpeed.Saved), a      ; Save current speed so it can be restored on exit.
                        nextreg Reg.CPUSpeed, %11       ; Set current desired speed to 28MHz.

                        NextRegRead(Reg.CoreMSB)        ; Core Major/Minor version
                        ld h, a
                        NextRegRead(Reg.CoreLSB)        ; Core Sub version
                        ld l, a                         ; HL = version, should be >= $3007
                        ld de, CoreMinVersion
                        CpHL(de)
                        ErrorIfCarry(Err.CoreMin)       ; Raise minimum core error if < 3.00.07

                        ld hl, (SavedArgs)              ; Start at first arg
ArgLoop:                ld de, ArgBuffer                ; Parse remaining args in a loop
                        call GetSizedArgProc
                        jr nc, NoMoreArgs
                        call ParseHelp
                        jr ArgLoop
NoMoreArgs:
                        ld a, (WantsHelp)
                        or a
                        jr z, NoHelp
DoHelp:                 PrintMsg(Msg.Help)
                        if enabled ErrDebug
                          Freeze(1,2)
                        else
                          jp Return.ToBasic
                        endif
NoHelp:

Reset:                  PrintMsg(Msg.Resetting)                 ; "Resetting ESP..."
                        //call WaitKey
                        call ResetESP
                        PrintMsg(Msg.Flushing)                  ; "Flushing UART..."
                        call ESPFlush
                        PrintMsg(Msg.Done)

                        if enabled ErrDebug
                          ; This is a temporary testing point that indicates we have have reached
                          ; The "success" point, and does a red/blue border effect instead of
                          ; actually exiting cleanly to BASIC.
                          Freeze(1,2)
                        else
                          ; This is the official "success" exit point of the program which restores
                          ; all the settings and exits to BASIC cleanly.
                          jp Return.ToBasic
                        endif
pend
                        include "constants.asm"         ; Global constants
                        include "macros.asm"            ; Zeus macros
                        include "general.asm"           ; General routines
                        include "esp.asm"               ; ESP and SLIP routines
                        include "print.asm"             ; Messaging and error routines
                        include "vars.asm"              ; Global variables

Length       equ $-Main
zeusprinthex "Dot Cmd: ", zeusmmu(DotCommand8KBank), Length

zeusassert zeusver<=75, "Upgrade to Zeus v4.00 (TEST ONLY) or above, available at http://www.desdes.com/products/oldfiles/zeustest.exe"

if (Length > $2000)
  zeuserror "Dot command is too large to assemble!"
endif

output_bin "..\\..\\dot\\ESPRESET", zeusmmu(DotCommand8KBank), Length ; Binary for project, and for CSpect image.

BuildArgs = "";
if enabled CSpect
  BuildArgs = BuildArgs + "-c "
endif
if enabled RealESP
  BuildArgs = BuildArgs + "-e "
endif

zeusinvoke "..\\..\\build\\builddot.bat " + BuildArgs, "", false ; Run batch file with args

