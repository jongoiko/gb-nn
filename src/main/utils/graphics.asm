INCLUDE "src/main/utils/hardware.inc"

SECTION "GraphicsUtils", ROM0

WaitForVBlank::
        ld      a, [rLY]
        cp      144
        jr      c, WaitForVBlank
        ret

WaitForNotVBlank::
        ld      a, [rLY]
        cp      144
        jr      nc, WaitForNotVBlank
        ret

ClearOAM::
        xor     a, a
        ld      b, 160
        ld      hl, _OAMRAM
.loop:
        ld      [hl+], a
        dec     b
        jr      nz, .loop
        ret
