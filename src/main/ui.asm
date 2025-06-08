INCLUDE "src/main/utils/hardware.inc"

SECTION "Tiles", ROM0

tileData:
INCBIN  "src/generated/backgrounds/main_screen.2bpp"
INCBIN  "src/generated/backgrounds/numbers.2bpp"
tileDataEnd:

spriteData:
INCBIN  "src/generated/sprites/pencil.2bpp"
spriteDataEnd:

mainScreenTileMap: INCBIN "src/generated/backgrounds/main_screen.tilemap"
mainScreenTileMapEnd:

digitsTileMap: INCBIN "src/generated/backgrounds/numbers.tilemap"
digitsTileMapEnd:

Section "UIVariables", WRAM0

wPredictedDigit: db

SECTION "UI",   ROM0

DEF     NUMBERS_BASE_TILE EQU 9
DEF     NUMBERS_TILEMAP_ADDR EQU $9A00
DEF     PENCIL_TILE_ID EQU 0

DisplayMainScreen::
        ld      a, 10
        ld      [wPredictedDigit], a

        ; Copy tile data and tilemap into VRAM
        ld      hl, $9000
        ld      bc, tileData
        ld      de, tileDataEnd - tileData
        call    CopyDEbytesFromBCtoHL

        ld      hl, $8000
        ld      bc, spriteData
        ld      de, spriteDataEnd - spriteData
        call    CopyDEbytesFromBCtoHL

        ld      hl, $9800
        ld      bc, mainScreenTileMap
        ld      de, mainScreenTileMapEnd - mainScreenTileMap
        call    CopyDEbytesFromBCtoHL

        ; Display digits below drawing area
        ld      hl, NUMBERS_TILEMAP_ADDR
        ld      bc, digitsTileMap
        ld      de, (digitsTileMapEnd - digitsTileMap) / 2
.copy:
        ld      a, [bc]
        add     a, NUMBERS_BASE_TILE
        ld      [hl+], a
        inc     bc
        dec     de
        ld      a, e
        or      a, d
        jr      nz, .copy

        ret

; Show predicted digit (in A, from 0 to 9)
ShowPredictedDigit::
        cp      a, 10
        jr      nc, .noClear

        push    af
        ld      a, [wPredictedDigit]
        ld      hl, digitsTileMap
        call    .showDigit
        pop     af

.noClear:
        push    af
        ld      hl, (digitsTileMap + digitsTileMapEnd) / 2
        call    .showDigit
        pop     af

        ld      [wPredictedDigit], a

        ret

.showDigit:
        sla     a
        ld      c, a
        ld      b, 0
        add     hl, bc
        ld      bc, NUMBERS_TILEMAP_ADDR

        add     a, c
        ld      c, a
        ld      a, b
        adc     a, 0
        ld      b, a

        call    WaitForVBlank
        ld      e, 2
.nextRow:
        ld      d, 2
.nextColumn:
        ld      a, [hl+]
        add     a, NUMBERS_BASE_TILE
        ld      [bc], a
        inc     c
        ld      a, b
        adc     a, 0
        ld      b, a
        dec     d
        jr      nz, .nextColumn

        ld      a, l
        add     a, 30
        ld      l, a
        ld      a, h
        adc     a, 0
        ld      h, a

        ld      a, c
        add     a, 30
        ld      c, a
        ld      a, b
        adc     a, 0
        ld      b, a

        dec     e
        jr      nz, .nextRow

        ret

ShowDrawingPencil::
        ld      a, [wPencilYPosition]
        sla     a
        sla     a
        add     a, 8 + 8
        ld      b, a

        ld      a, [wPencilXPosition]
        sla     a
        sla     a
        add     a, 28 + 8
        ld      c, a

        call    WaitForVBlank
        ld      hl, _OAMRAM
        ld      a, b
        ld      [hl+], a
        ld      a, c
        ld      [hl+], a
        ld      a, PENCIL_TILE_ID
        ld      [hl+], a
        xor     a, a
        ld      [hl], a
        ret
