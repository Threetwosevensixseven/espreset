; version.asm
;
; Auto-generated by ZXVersion.exe
; On 16 Feb 2020 at 20:07

BuildNo                 macro()
                        db "4"
mend

BuildNoValue            equ "4"
BuildNoWidth            equ 0 + FW4



BuildDate               macro()
                        db "16 Feb 2020"
mend

BuildDateValue          equ "16 Feb 2020"
BuildDateWidth          equ 0 + FW1 + FW6 + FWSpace + FWF + FWe + FWb + FWSpace + FW2 + FW0 + FW2 + FW0



BuildTime               macro()
                        db "20:07"
mend

BuildTimeValue          equ "20:07"
BuildTimeWidth          equ 0 + FW2 + FW0 + FWColon + FW0 + FW7



BuildTimeSecs           macro()
                        db "20:07:45"
mend

BuildTimeSecsValue      equ "20:07:45"
BuildTimeSecsWidth      equ 0 + FW2 + FW0 + FWColon + FW0 + FW7 + FWColon + FW4 + FW5
