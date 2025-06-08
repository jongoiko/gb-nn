INCLUDE "src/main/utils/hardware.inc"

SECTION "Header", ROM0[$100]

        jp      EntryPoint

        ds      $150 - @, 0     ; Make room for the header

DEF     WAIT_EVERY_N_FRAMES EQU 4

EntryPoint:
        ; Shut down audio circuitry
        xor     a, a
        ld      [rNR52], a

        call    WaitForVBlank
        ; Turn off LCD
        xor     a, a
        ld      [rLCDC], a

        call    DisplayMainScreen
        call    ClearOAM

        call    ResetPencilPosition
        call    ResetKeys

        ; Turn the LCD on
        ld      a, LCDCF_ON  | LCDCF_BGON | LCDCF_OBJON
        ld      [rLCDC], a

        ; During the first (blank) frame, initialize display registers
        ld      a, %11100100
        ld      [rBGP], a
        ld      [rOBP0], a

MainLoop:
        ld      d, WAIT_EVERY_N_FRAMES
.wait
        call    WaitForNotVBlank
        call    WaitForVBlank
        dec     d
        jr      nz, .wait

        call    UpdateKeys

        ld      a, [wCurrentKeys]
        and     a, PADF_LEFT
        call    nz, MovePencilLeft

        ld      a, [wCurrentKeys]
        and     a, PADF_RIGHT
        call    nz, MovePencilRight

        ld      a, [wCurrentKeys]
        and     a, PADF_UP
        call    nz, MovePencilUp

        ld      a, [wCurrentKeys]
        and     a, PADF_DOWN
        call    nz, MovePencilDown

        call    ShowDrawingPencil
        jr      MainLoop
