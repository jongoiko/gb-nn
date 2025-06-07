INCLUDE "src/main/utils/hardware.inc"

SECTION "MiscellaneousUtils", ROM0

CopyDEbytesFromBCtoHL::
        ld      a, [bc]
        ld      [hl+], a
        inc     bc
        dec     de
        ld      a, e
        or      a, d
        jr      nz, CopyDEbytesFromBCtoHL
        ret
