; general.asm

InstallErrorHandler     proc                            ; Our error handler gets called by the OS if SCROLL? N happens
                        ld hl, ErrorHandler             ; during printing, or any other ROM errors get thrown. We trap
                        Rst8(M_ERRH)                    ; the error in our ErrorHandler routine to give us a chance to
                        ret                             ; clean up the dot cmd before exiting to BASIC.
pend

ErrorHandler            proc                            ; If we trap any errors thrown by the ROM, we currently just
                        ld hl, Err.Break                ; exit the dot cmd with a  "D BREAK - CONT repeats" custom
                        jp Return.WithCustomError       ; error.
pend

ErrorProc               proc
                        if enabled ErrDebug
                          call PrintRst16Error
Stop:                     Border(2)
                          jr Stop
                        else                            ; The normal (non-debug) error routine shows the error in both
                          push hl                       ; If we want to print the error at the top of the screen,
                          call PrintRst16Error          ; as well as letting BASIC print it in the lower screen,
                          pop hl                        ; then uncomment this code.
                          jp Return.WithCustomError     ; Straight to the error handing exit routine
                        endif
pend

RestoreF8               proc
Saved equ $+1:          ld a, SMC                       ; This was saved here when we entered the dot command
                        and %1000 0000                  ; Mask out everything but the F8 enable bit
                        ld d, a
                        NextRegRead(Reg.Peripheral2)    ; Read the current value of Peripheral 2 register
                        and %0111 1111                  ; Clear the F8 enable bit
                        or d                            ; Mask back in the saved bit
                        nextreg Reg.Peripheral2, a      ; Save back to Peripheral 2 register
                        ret
pend

RestoreSpeed            proc
Saved equ $+3:          nextreg Reg.CPUSpeed, SMC       ; Restore speed to what it originally was at dot cmd entry
                        ret
pend

Return                  proc                            ; This routine restores everything preserved at the start of
ToBasic:                                                ; the dot cmd, for success and errors, then returns to BASIC.                        call RestoreSpeed               ; Restore original CPU speed
                        call RestoreF8                  ; Restore original F8 enable/disable state
Stack                   ld sp, SMC                      ; Unwind stack to original point
Stack1                  equ Stack+1
IY1 equ $+1:            ld iy, SMC                      ; Restore IY
                        ld a, 0
                        ei
                        ret                             ; Return to BASIC
WithCustomError:
                        push hl
                        call RestoreSpeed               ; Restore original CPU speed
                        call RestoreF8                  ; Restore original F8 enable/disable state
                        xor a
                        scf                             ; Signal error, hl = custom error message
                        pop hl
                        jp Stack                        ; (NextZXOS is not currently displaying standard error messages,
pend                                                    ;  with a>0 and carry cleared, so we use a custom message.)

Wait5Frames             proc                            ; Convenience routines for different lengths of wait.
                        WaitFrames(5)                   ; Each frame is 1/50th of a second.
                        ret
pend

Wait30Frames            proc                            ; Convenience routines for different lengths of wait.
                        WaitFrames(30)                  ; Each frame is 1/50th of a second.
                        ret
pend

Wait80Frames            proc                            ; Convenience routines for different lengths of wait.
                        WaitFrames(80)                  ; Each frame is 1/50th of a second.
                        ret
pend

Wait100Frames           proc                            ; Convenience routines for different lengths of wait.
                        WaitFrames(100)                 ; Each frame is 1/50th of a second.
                        ret
pend

WaitFramesProc          proc
                        di
                        ld (SavedStack), sp             ; Save stack
                        ld sp, $8000                    ; Put stack in upper 48K so FRAMES gets updated (this is a
                        ei                              ; peculiarity of mode 1 interrupts inside dot commands).
Loop:                   halt                            ; Note that we already have a bank allocated by IDE_BANK
                        dec bc                          ; at $8000, so we're not corrupting BASIC by doing this.
                        ld a, b
                        or c
                        jr nz, Loop                     ; Wait for BC frames
                        di                              ; In this dot cmd interrupts are off unless waiting or printing
SavedStack equ $+1:     ld sp, SMC                      ; Restore stack
                        ret
pend

; ***************************************************************************
; * Parse an argument from the command tail                                 *
; ***************************************************************************
; Entry: HL=command tail
;        DE=destination for argument
; Exit:  Fc=0 if no argument
;        Fc=1: parsed argument has been copied to DE and null-terminated
;        HL=command tail after this argument
;        BC=length of argument
; NOTE: BC is validated to be 1..255; if not, it does not return but instead
;       exits via show_usage.
;
; Routine provided by Garry Lancaster, with thanks :) Original is here:
; https://gitlab.com/thesmog358/tbblue/blob/master/src/asm/dot_commands/defrag.asm#L599
GetSizedArgProc         proc
                        ld a, h
                        or l
                        ret z                           ; exit with Fc=0 if hl is $0000 (no args)
                        ld bc, 0                        ; initialise size to zero
Loop:                   ld a, (hl)
                        inc hl
                        and a
                        ret z                           ; exit with Fc=0 if $00
                        cp CR
                        ret z                           ; or if CR
                        cp ':'
                        ret z                           ; or if ':'
                        cp ' '
                        jr z, Loop                      ; skip any spaces
                        cp '"'
                        jr z, Quoted                    ; on for a quoted arg
Unquoted:               ld (de), a                      ; store next char into dest
                        inc de
                        inc c                           ; increment length
                        jr z, BadSize                   ; don't allow >255
                        ld  a, (hl)
                        and a
                        jr z, Complete                  ; finished if found $00
                        cp CR
                        jr z, Complete                  ; or CR
                        cp ':'
                        jr z, Complete                  ; or ':'
                        cp '"'
                        jr z, Complete                  ; or '"' indicating start of next arg
                        inc hl
                        cp ' '
                        jr nz, Unquoted                 ; continue until space
Complete:               xor a
                        ld (de), a                      ; terminate argument with NULL
                        ld a, b
                        or c
                        jr z, BadSize                   ; don't allow zero-length args
                        scf                             ; Fc=1, argument found
                        ret
Quoted:                 ld a, (hl)
                        and a
                        jr z, Complete                  ; finished if found $00
                        cp CR
                        jr z, Complete                  ; or CR
                        inc hl
                        cp '"'
                        jr z, Complete                  ; finished when next quote consumed
                        ld (de), a                      ; store next char into dest
                        inc de
                        inc c                           ; increment length
                        jr z, BadSize                   ; don't allow >255
                        jr Quoted
BadSize:                pop af                          ; discard return address
                        ErrorAlways(Err.ArgsBad)
pend

ParseHelp               proc
                        ret nc                          ; Return immediately if no arg found
                        ld a, b
                        or c
                        cp 2
                        ret nz
                        push hl
                        ld hl, ArgBuffer
                        ld a, (hl)
                        cp '-'
                        jr nz, Return
                        inc hl
                        ld a, (hl)
                        cp 'h'
                        jr nz, Return
                        ld a, 1
                        ld (WantsHelp), a
Return:                 pop hl
                        ret
pend
