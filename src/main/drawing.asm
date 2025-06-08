INCLUDE "src/main/utils/hardware.inc"

Section "DrawingVariables", WRAM0

wPencilXPosition:: db
wPencilYPosition:: db

SECTION "Drawing", ROM0

DEF     MAX_PENCIL_X_POSITION EQU 27
DEF     MAX_PENCIL_Y_POSITION EQU 27

ResetPencilPosition::
        xor     a, a
        ld      [wPencilXPosition], a
        ld      [wPencilYPosition], a
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
        cp      MAX_PENCIL_X_POSITION
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
        cp      MAX_PENCIL_Y_POSITION
        ret     nc
        inc     a
        ld      [wPencilYPosition], a
        ret
