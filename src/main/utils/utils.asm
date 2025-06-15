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

LoadHLtoAddressAtBC::
        ld      a, h
        ld      [bc], a
        inc     bc
        ld      a, l
        ld      [bc], a
        ret

LoadAddressAtBCtoHL::
        ld      a, [bc]
        ld      h, a
        inc     bc
        ld      a, [bc]
        ld      l, a
        ret
