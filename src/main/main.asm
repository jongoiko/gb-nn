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
        call    ClearOAM

        call    ResetPencilPosition
        call    ResetDigitPixels
        call    ResetKeys
        call    SetupInterrupts

        ; Turn the LCD on
        ld      a, LCDCF_ON  | LCDCF_BGON | LCDCF_OBJON
        ld      [rLCDC], a

        ; During the first (blank) frame, initialize display registers
        ld      a, %11100100
        ld      [rBGP], a
        ld      [rOBP0], a

.loop:
        halt
        jr      .loop

HandleInputs::
        ; This routine is called on each VBlank interrupt
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

        ld      a, [wCurrentKeys]
        and     a, PADF_A
        call    nz, DrawOnPencil

        ld      a, [wCurrentKeys]
        and     a, PADF_B
        call    nz, EraseOnPencil

        ld      a, [wCurrentKeys]
        and     a, PADF_SELECT
        call    nz, ClearDrawing

        ld      a, [wCurrentKeys]
        and     a, PADF_START
        call    nz, PredictDigit

        call    ShowDrawingPencil
        ret
