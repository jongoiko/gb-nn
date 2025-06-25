INCLUDE "src/main/utils/hardware.inc"

SECTION "Interrupts", ROM0

SetupInterrupts::
        ; Enable VBlank interrupt
        ld      a, IEF_VBLANK
        ld      [rIE], a
        xor     a, a
        ld      [rIF], a
        ei
        ret

VBlankInterruptHandler:
        ld      a, [wNeuralNetworkForwardPassRunning]
        or      a, a
        jr      nz, .forwardPassRunning
        ld      a, %11100100
        ld      [rBGP], a
        call    HandleInputs
        jr      .restoreRegisters
.forwardPassRunning:
        call    VBlankDuringNeuralNetworkForwardPass
.restoreRegisters:
        pop     hl
        pop     de
        pop     bc
        pop     af
        reti

SECTION "VBlankInterrupt", ROM0[$0040]

VBlankInterrupt:
        push    af
        push    bc
        push    de
        push    hl
        jp      VBlankInterruptHandler
