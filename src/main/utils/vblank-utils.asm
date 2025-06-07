INCLUDE "src/main/utils/hardware.inc"

SECTION "VBlankFunctions", ROM0

WaitForVBlank::
        ld      a, [rLY]
        cp      144
        jr      c, WaitForVBlank
        ret
