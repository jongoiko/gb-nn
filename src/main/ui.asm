INCLUDE "src/main/utils/hardware.inc"

SECTION "Tiles", ROM0

tileData:
INCBIN  "src/generated/backgrounds/main_screen.2bpp"
INCBIN  "src/generated/backgrounds/numbers.2bpp"
tileDataEnd:

mainScreenTileMap: INCBIN "src/generated/backgrounds/main_screen.tilemap"
mainScreenTileMapEnd:

digitsTileMap: INCBIN "src/generated/backgrounds/numbers.tilemap"
digitsTileMapEnd:

SECTION "UI",   ROM0

DEF     NUMBERS_BASE_TILE EQU 11

DisplayMainScreen::
        ; Copy tile data and tilemap into VRAM
        ld      hl, $9000
        ld      bc, tileData
        ld      de, tileDataEnd - tileData
        call    CopyDEbytesFromBCtoHL

        ld      hl, $9800
        ld      bc, mainScreenTileMap
        ld      de, mainScreenTileMapEnd - mainScreenTileMap
        call    CopyDEbytesFromBCtoHL

        ; Display digits below drawing area
        ld      hl, $99E0
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
