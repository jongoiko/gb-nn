INCLUDE "src/main/utils/hardware.inc"
INCLUDE "src/main/utils/constants.inc"

Section "DrawingVariables", WRAM0

wPencilXPosition:: db
wPencilYPosition:: db

wDigitPixels:: ds DIGIT_IMAGE_SIZE_BYTES

SECTION "Drawing", ROM0

DEF     DRAWING_TILEMAP_ADDR EQU $9823
DEF     BLANK_TILE_ID EQU 0

ResetPencilPosition::
        xor     a, a
        ld      [wPencilXPosition], a
        ld      [wPencilYPosition], a
        ret

ResetDigitPixels::
        ld      hl, wDigitPixels
        ld      bc, DIGIT_IMAGE_SIZE_BYTES
.loop:
        xor     a, a
        ld      [hl+], a
        dec     bc
        ld      a, b
        or      a, c
        jr      nz, .loop
        ret

MovePencilLeft::
        ld      a, [wPencilXPosition]
        or      a
        ret     z
        dec     a
        ld      [wPencilXPosition], a
        ret

MovePencilRight::
        ld      a, [wPencilXPosition]
        cp      DIGIT_IMAGE_WIDTH - 1
        ret     nc
        inc     a
        ld      [wPencilXPosition], a
        ret

MovePencilUp::
        ld      a, [wPencilYPosition]
        or      a
        ret     z
        dec     a
        ld      [wPencilYPosition], a
        ret

MovePencilDown::
        ld      a, [wPencilYPosition]
        cp      DIGIT_IMAGE_HEIGHT - 1
        ret     nc
        inc     a
        ld      [wPencilYPosition], a
        ret

DrawOnPencil::
        scf
        ccf
        call    GetPixelAddressIntoHLFromPencilPosition
        ld      [hl], 1
        call    UpdateDisplayedDrawing
        ret

EraseOnPencil::
        scf
        ccf
        call    GetPixelAddressIntoHLFromPencilPosition
        ld      [hl], 0
        call    UpdateDisplayedDrawing
        ret

GetPixelAddressIntoHLFromPencilPosition:
        ld      a, [wPencilYPosition]
        push    af
        jr      nc, .noRoundTile
        and     a, %11111110
.noRoundTile:
        ld      h, a
        ld      e, DIGIT_IMAGE_WIDTH
        call    MultiplyHandEintoHL
        ld      bc, wDigitPixels
        add     hl, bc
        pop     af
        ld      a, [wPencilXPosition]
        jr      nc, .noRoundTile2
        and     a, %11111110
.noRoundTile2:
        ld      c, a
        ld      b, 0
        add     hl, bc
        ret

UpdateDisplayedDrawing:
        ld      a, [wPencilYPosition]
        and     a, %11111110
        ld      h, a
        ld      e, 16
        call    MultiplyHandEintoHL
        ld      bc, DRAWING_TILEMAP_ADDR
        add     hl, bc
        ld      a, [wPencilXPosition]
        and     a, %11111110
        sra     a
        ld      c, a
        ld      b, 0
        add     hl, bc
        ; HL now contains the address of the modified tile in the tilemap. We
        ; check the values of the 4 contained pixels to determine which tile to
        ; draw
        push    hl
        scf
        call    GetPixelAddressIntoHLFromPencilPosition
        pop     bc
        ; BC contains the tile address and HL contains the leftmost 2x2 pixel
        ; address
        ld      a, [hl+]
        sla     a
        ld      d, [hl]
        or      a, d
        sla     a
        ld      d, a

        ld      a, l
        add     a, DIGIT_IMAGE_WIDTH - 1
        ld      l, a
        ld      a, h
        adc     a, 0
        ld      h, a

        ld      a, [hl+]
        or      a, d
        sla     a
        ld      d, [hl]
        or      a, d
        ld      e, a
        ; E now contains the tile index to draw
        ld      hl, DrawingPixelTiles
        ld      d, 0
        add     hl, de
        ld      d, [hl]

        call    WaitForVBlank
        ld      a, d
        ld      [bc], a

        ret

DrawingPixelTiles:
        db      78, 82, 86, 90, 79, 83, 87, 91, 76, 80, 84, 88, 77, 81, 85, 89

ClearDrawing::
        call    ResetDigitPixels
        ld      a, BLANK_TILE_ID
        ld      hl, DRAWING_TILEMAP_ADDR
        ld      d, DIGIT_IMAGE_HEIGHT / 2
.nextRow:
        call    WaitForVBlank
        ld      e, DIGIT_IMAGE_WIDTH / 2
.nextTile:
        ld      [hl+], a
        dec     e
        jr      nz, .nextTile

        ld      bc, 32 - DIGIT_IMAGE_WIDTH / 2
        add     hl, bc

        dec     d
        jr      nz, .nextRow
        ret
