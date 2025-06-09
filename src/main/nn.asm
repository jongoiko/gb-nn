INCLUDE "src/main/utils/hardware.inc"

SECTION "NeuralNetworkVariables", WRAM0

wDigit: db

SECTION "NeuralNetwork", ROM0

InitializeNeuralNetwork::
        xor     a, a
        ld      [wDigit], a
        ret

PredictDigit::
        ld      a, [wDigit]
        call    ShowPredictedDigit
        ld      a, [wDigit]
        cp      a, 9
        jr      c, .nextDigit
        ld      a, -1
.nextDigit:
        inc     a
        ld      [wDigit], a
        ret
