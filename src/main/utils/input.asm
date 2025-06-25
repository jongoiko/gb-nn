INCLUDE "src/main/utils/hardware.inc"

SECTION "InputVariables", WRAM0

wCurrentKeys:: db
wNewKeys: db
wFramesToNextInput: db

SECTION "InputUtils", ROM0

DEF     NUM_FRAMES_BETWEEN_INPUTS EQU 4

ResetKeys::
        xor     a, a
        ld      [wCurrentKeys], a
        ld      [wNewKeys], a
        ld      [wFramesToNextInput], a
        ret

UpdateKeys::
        ; Poll half the controller
        ld      a, P1F_GET_BTN
        call    .onenibble
        ld      b, a            ; B7-4 = 1; B3-0 = unpressed buttons

        ; Poll the other half
        ld      a, P1F_GET_DPAD
        call    .onenibble
        swap    a               ; A7-4 = unpressed directions; A3-0 = 1
        xor     a, b            ; A = pressed buttons + directions
        ld      b, a            ; B = pressed buttons + directions

        ; And release the controller
        ld      a, P1F_GET_NONE
        ldh     [rP1], a

        ; Combine with previous wCurKeys to make wNewKeys
        ld      a, [wCurrentKeys]
        xor     a, b            ; A = keys that changed state
        and     a, b            ; A = keys that changed to pressed
        ld      [wNewKeys], a
        ld      a, b
        ld      [wCurrentKeys], a

        ; If any key was already held down, wait for NUM_FRAMES_BETWEEN_INPUTS
        ; frames
        or      a, a
        jr      z, .noKeysPressed

        ld      a, [wFramesToNextInput]
        or      a, a
        jr      z, .nextInput

        dec     a
        ld      [wFramesToNextInput], a
        xor     a, a
        ld      [wCurrentKeys], a
        ret

.nextInput:
        ld      a, NUM_FRAMES_BETWEEN_INPUTS
        ld      [wFramesToNextInput], a
        ret

.noKeysPressed:
        xor     a, a
        ld      [wFramesToNextInput], a
        ret

.onenibble
        ldh     [rP1], a        ; switch the key matrix
        call    .knownret       ; burn 10 cycles calling a known ret
        ldh     a, [rP1]        ; ignore value while waiting for the key matrix to settle
        ldh     a, [rP1]
        ldh     a, [rP1]        ; this read counts
        or      a, $F0          ; A7-4 = 1; A3-0 = unpressed keys
.knownret
        ret
