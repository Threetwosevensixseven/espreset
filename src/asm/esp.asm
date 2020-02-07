; esp.asm

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

Baud                    proc Table:
b115200:                dw $8173, $8178, $817F, $8204, $820D, $8215, $821E, $816A
//b1152000:               dw $8018, $8019, $801A, $801A, $801B, $801C, $801D, $8017
pend

Timings:                proc Table:
  ;   Text   Index  Notes
  db "VGA0", 0 ; 0  Timing 0
  db "VGA1", 0 ; 1  Timing 1
  db "VGA2", 0 ; 2  Timing 2
  db "VGA3", 0 ; 3  Timing 3
  db "VGA4", 0 ; 4  Timing 4
  db "VGA5", 0 ; 5  Timing 5
  db "VGA6", 0 ; 6  Timing 6
  db "HDMI", 0 ; 7  Timing 7
pend
/*
ESPFlush                proc
                        ld bc, UART_GetStatus
ReadLoop:               ld a, high UART_GetStatus       ; Are there any characters waiting?
                        in a, (c)                       ; This inputs from the 16-bit address UART_GetStatus
                        rrca                            ; Check UART_mRX_DATA_READY flag in bit 0
                        ret nc                          ; Return immmediately if no data ready to be read
                        inc b                           ; Otherwise Read the byte
                        in a, (c)                       ; from the UART Rx port
                        dec b
                        jr ReadLoop                     ; then check if there are more data bytes ready to read
pend

ESPReadPrint            proc
                        ld a, (FRAMES)
                        add a, 5
                        ld (TimeoutFrame), a
                        ld bc, UART_GetStatus
                        ei
WaitNotBusy:            ld a, high UART_GetStatus       ; Are there any characters waiting?
                        in a, (c)                       ; This inputs from the 16-bit address UART_GetStatus
                        rrca                            ; Check UART_mRX_DATA_READY flag in bit 0
                        jp c, HasData                   ; Read Data if Available
                        ld a, (FRAMES)
TimeoutFrame equ $+1:   cp SMC
                        jp nz, WaitNotBusy              ; Try again for at least another N frames (5)
                        di
                        ret                             ; Return if N frames (5) has elapsed with no data
HasData:                inc b                           ; Otherwise Read the byte
                        in a, (c)                       ; from the UART Rx port
                        push bc
                        call PrintChar
                        pop bc
                        dec b
                        jr WaitNotBusy                  ; then check if there are more data bytes ready to read
pend

ESPClearBuffer:         proc
                        FillLDIR(Buffer, BufferLen, 0)
                        ret
pend

ESPReadIntoBuffer       proc
                        di
                        ld (SavedStack), sp             ; Save stack
                        ld sp, $8000                    ; Put stack in upper 16K so FRAMES gets update
                        ei
                        call ESPClearBuffer
                        ld a, (FRAMES)
WaitNFrames equ $+1:    add a, 5
                        ld (TimeoutFrame), a
                        ld bc, UART_GetStatus
                        ld hl, Buffer
                        ld de, BufferLen
WaitNotBusy:            in a, (c)                       ; This inputs from the 16-bit address UART_GetStatus
                        rrca                            ; Check UART_mRX_DATA_READY flag in bit 0
                        jp c, HasData                   ; Read Data if available
                        ld a, (FRAMES)
TimeoutFrame equ $+1:   cp SMC
                        jp nz, WaitNotBusy              ; Try again for at least another N frames (5)
                        di
                        scf                             ; Set carry to signal error if N frames with no data,
                        jr Return                       ; and return
HasData:                inc b                           ; Otherwise Read the byte,
                        in a, (c)                       ; from the UART Rx port,
                        dec b
                        ld (hl), a                      ; and write into buffer
                        inc hl
                        dec de                          ; See if any more buffer left
                        ld a, d
                        or e
                        jr nz, WaitNotBusy              ; If so, check if there are more data bytes ready to read,
                        or a                            ; otherwise clear carry to signal success,
Return:                 di
SavedStack equ $+1:     ld sp, SMC
                        ret                             ; and return
pend

ESPWaitFlushWait        proc
                        call Wait5Frames
                        call ESPFlush                   ; Clear UART buffer
                        call Wait5Frames
                        ret
pend

ResetESP                proc                            ; Reset ESP with a normal (non-programming) reset
                        nextreg 2, 128                  ; Set RST low
                        call Wait5Frames                ; Hold in reset
                        nextreg 2, 0                    ; Set RST high
                        ret
pend
*/
