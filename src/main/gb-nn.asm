INCLUDE "src/main/utils/hardware.inc"

SECTION "Header", ROM0[$100]

        jp      EntryPoint

        ds      $150 - @, 0     ; Make room for the header

EntryPoint:
        ; Shut down audio circuitry
        xor     a, a
        ld      [rNR52], a

        call    WaitForVBlank
        ; Turn off LCD
        xor     a, a
        ld      [rLCDC], a

        call    DisplayMainScreen

        ; Turn the LCD on
        ld      a, LCDCF_ON  | LCDCF_BGON
        ld      [rLCDC], a

        ; During the first (blank) frame, initialize display registers
        ld      a, %11100100
        ld      [rBGP], a

.loop:
        jr      .loop
