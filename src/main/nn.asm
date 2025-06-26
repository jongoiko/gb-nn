INCLUDE "src/main/utils/hardware.inc"
INCLUDE "src/main/utils/constants.inc"

SECTION "NeuralNetworkVariables", WRAM0

DEF     MAX_ACTIVATION_SIZE_BYTES EQU 1024

DEF     DRAWN_PIXEL_BYTE_VALUE EQU $7F
DEF     NOT_DRAWN_PIXEL_BYTE_VALUE EQU $80

DEF     FORWARD_PASS_FLICKER_EVERY_N_FRAMES EQU 6

DEF     OPCODE_FULLY_CONNECTED EQU 9

wNeuralNetworkForwardPassRunning:: db
wForwardPassFrameCounter: db
wForwardPassFlickerPalette: db
wPredictedDigit: db

wActivationIdx: db
wCurrentLayerAddr: dw
wActivationsA: ds MAX_ACTIVATION_SIZE_BYTES
wActivationsB: ds MAX_ACTIVATION_SIZE_BYTES

wFullyConnectedInputSize: dw
wFullyConnectedOutputSize: dw
wFullyConnectedOutputZ: db
wFullyConnectedM0: dw
wFullyConnectedMExponent: db
wFullyConnectedHasReLUActivation: db
wFullyConnectedInputSizeVar: dw
wFullyConnectedOutputSizeVar: dw
wFullyConnectedOutputComponentVar: dl
wFullyConnectedNextLayerAddrVar: dw

SECTION "NeuralNetwork", ROM0

nn:
INCBIN  "nn-training/model.bin"
nnEnd:

ResetNeuralNetwork::
        xor     a, a
        ld      [wNeuralNetworkForwardPassRunning], a
        ld      [wForwardPassFrameCounter], a
        ret

InitializeNeuralNetwork:
        xor     a, a
        ld      [wActivationIdx], a
        ld      a, %11100100
        ld      [wForwardPassFlickerPalette], a
        ld      hl, nn
        inc     hl
        ld      bc, wCurrentLayerAddr
        call    LoadHLtoAddressAtBC
        ret

VBlankDuringNeuralNetworkForwardPass::
        ld      a, [wForwardPassFrameCounter]
        inc     a
        cp      a, FORWARD_PASS_FLICKER_EVERY_N_FRAMES
        jr      nz, .updateCounter
        ld      a, [wForwardPassFlickerPalette]
        ld      [rBGP], a
        rrca
        rrca
        ld      [wForwardPassFlickerPalette], a
        xor     a, a
.updateCounter:
        ld      [wForwardPassFrameCounter], a
        ret

PredictDigit::
        call    InitializeNeuralNetwork

        ; Interrupts are enabled to flicker the screen while the NN forward pass
        ; is running
        ld      a, 1
        ld      [wNeuralNetworkForwardPassRunning], a
        ei

        call    LoadImagePixelsIntoInputActivations

        ; Read number of layers
        ld      a, [nn]
.nextLayer:
        push    af
        call    RunNextLayer

        ld      a, [wActivationIdx]
        xor     a, 1
        ld      [wActivationIdx], a

        pop     af
        dec     a
        jr      nz, .nextLayer

        ; The activations now contain 10 signed bytes with the logits for each
        ; class. We take the max and show the predicted digit
        ld      a, [wActivationIdx]
        xor     a, 1
        ld      [wActivationIdx], a
        call    LoadActivationsAddressToBCandHL

        ; E holds the greatest logit and D holds the argmax
        ld      d, 10
        ld      e, -128

        ld      c, 0
.nextDigit:
        ld      a, [hl]
        add     a, 128
        ld      b, a
        ld      a, e
        add     a, 128

        cp      a, b
        jr      nc, .notLarger

        ld      d, c
        ld      a, [hl]
        ld      e, a
.notLarger:
        inc     hl
        inc     c
        ld      a, c
        cp      a, 10
        jr      nz, .nextDigit

        ld      a, d
        ld      [wPredictedDigit], a
        call    ShowPredictedDigit

        xor     a, a
        ld      [wNeuralNetworkForwardPassRunning], a

        ret

; Store the input activation address to BC and the output activation address to
; HL
LoadActivationsAddressToBCandHL:
        ld      a, [wActivationIdx]
        or      a, a
        jr      nz, .activationBufferB
        ld      bc, wActivationsB
        ld      hl, wActivationsA
        ret
.activationBufferB:
        ld      bc, wActivationsA
        ld      hl, wActivationsB
        ret

LoadImagePixelsIntoInputActivations:
        call    LoadActivationsAddressToBCandHL
        ld      h, b
        ld      l, c
        ld      de, DIGIT_IMAGE_SIZE_BYTES
        ld      bc, wDigitPixels
.next:
        ld      a, [bc]
        or      a, a
        jr      z, .zeroPixel
        ld      a, DRAWN_PIXEL_BYTE_VALUE
        jr      .writePixel
.zeroPixel:
        ld      a, NOT_DRAWN_PIXEL_BYTE_VALUE
.writePixel:
        ld      [hl+], a

        inc     bc
        dec     de
        ld      a, d
        or      a, e
        jr      nz, .next
        ret


RunNextLayer:
        ld      bc, wCurrentLayerAddr
        call    LoadAddressAtBCtoHL
        ; Read opcode
        ld      a, [hl]
        cp      a, OPCODE_FULLY_CONNECTED
        call    z, RunFullyConnectedLayer
        ret

RunFullyConnectedLayer:
        push    hl
        ld      b, h
        ld      c, l
        inc     bc
        inc     bc
        call    LoadAddressAtBCtoHL
        ld      bc, wFullyConnectedOutputSize
        call    LoadHLtoAddressAtBC
        ld      bc, wFullyConnectedOutputSizeVar
        call    LoadHLtoAddressAtBC
        pop     hl

        ld      bc, 4
        add     hl, bc
        push    hl
        ld      b, h
        ld      c, l
        call    LoadAddressAtBCtoHL
        ld      bc, wFullyConnectedInputSize
        call    LoadHLtoAddressAtBC
        pop     hl
        inc     hl
        inc     hl
        ld      a, [hl+]
        ld      [wFullyConnectedOutputZ], a

        push    hl
        ld      b, h
        ld      c, l
        call    LoadAddressAtBCtoHL
        ld      bc, wFullyConnectedM0
        call    LoadHLtoAddressAtBC
        pop     hl
        inc     hl
        inc     hl

        ld      a, [hl+]
        ld      [wFullyConnectedMExponent], a

        ld      a, [hl+]
        ld      [wFullyConnectedHasReLUActivation], a

        ld      d, h
        ld      e, l

        call    LoadActivationsAddressToBCandHL
.nextOutputComponent:
        ; Forward pass: BC points to the input tensor, HL points to the output
        ; component, DE points to the layer's weight matrix row
        push    bc
        push    hl
        call    .calculateDotProduct
        call    .addBias
        call    .requantize
        ; Now the result is stored in Math32RegC
        call    .applyReLU
        ; Add zero point of the layer output (Z_y)
        ld      a, [Math32RegC]
        ld      b, a
        ld      a, [wFullyConnectedOutputZ]
        add     a, b
        pop     hl
        ld      [hl], a

        inc     hl
        push    hl
        ld      bc, wFullyConnectedOutputSizeVar
        call    LoadAddressAtBCtoHL
        ld      a, l
        sub     a, 1
        ld      l, a
        ld      a, h
        sbc     a, 0
        ld      h, a
        ld      bc, wFullyConnectedOutputSizeVar
        call    LoadHLtoAddressAtBC
        or      a, l
        pop     hl
        pop     bc

        jr      nz, .nextOutputComponent

        ; Save address of next layer
        ld      bc, wFullyConnectedNextLayerAddrVar
        call    LoadAddressAtBCtoHL
        ld      bc, wCurrentLayerAddr
        call    LoadHLtoAddressAtBC

        ret

.calculateDotProduct:
        ; BC points to the input tensor, HL points to the output component, DE
        ; points to the layer's weight matrix row
        push    bc
        push    hl
        ld      bc, wFullyConnectedInputSize
        call    LoadAddressAtBCtoHL
        ld      bc, wFullyConnectedInputSizeVar
        call    LoadHLtoAddressAtBC
        pop     hl
        pop     bc

        xor     a, a
        ld      [wFullyConnectedOutputComponentVar], a
        ld      [wFullyConnectedOutputComponentVar + 1], a
        ld      [wFullyConnectedOutputComponentVar + 2], a
        ld      [wFullyConnectedOutputComponentVar + 3], a
.nextElement:
        push    hl
        push    de
        push    bc

        ld      a, [bc]
        ld      h, a

        ld      a, [de]
        ld      e, a

        call    MultiplyHandEintoHLNN

        ld      b, 0
        bit     7, h
        jr      z, .nonNegativeProduct
        ld      b, $FF
.nonNegativeProduct:
        ld      a, [wFullyConnectedOutputComponentVar + 3]
        add     a, l
        ld      [wFullyConnectedOutputComponentVar + 3], a
        ld      a, [wFullyConnectedOutputComponentVar + 2]
        adc     a, h
        ld      [wFullyConnectedOutputComponentVar + 2], a
        ld      a, [wFullyConnectedOutputComponentVar + 1]
        adc     a, b
        ld      [wFullyConnectedOutputComponentVar + 1], a
        ld      a, [wFullyConnectedOutputComponentVar]
        adc     a, b
        ld      [wFullyConnectedOutputComponentVar], a

        pop     bc
        pop     de
        pop     hl
        inc     bc
        inc     de

        ld      a, [wFullyConnectedInputSizeVar + 1]
        sub     a, 1
        ld      [wFullyConnectedInputSizeVar + 1], a
        ld      a, [wFullyConnectedInputSizeVar]
        sbc     a, 0
        ld      [wFullyConnectedInputSizeVar], a

        jr      nz, .nextElement
        ld      a, [wFullyConnectedInputSizeVar + 1]
        or      a, a
        jr      nz, .nextElement

        ret

.addBias:
        ld      bc, wCurrentLayerAddr
        call    LoadAddressAtBCtoHL
        ld      bc, 11
        add     hl, bc
        push    de
        push    hl

        ld      a, [wFullyConnectedInputSize + 1]
        ld      e, a
        ld      a, [wFullyConnectedInputSize]
        ld      d, a

        ld      a, [wFullyConnectedOutputSize + 1]
        ld      c, a
        ld      a, [wFullyConnectedOutputSize]
        ld      b, a

        call    MultiplyBCandDEintoDEHL
        ; We assume that the total size of the weight matrix fits in 16 bits
        ld      b, h
        ld      c, l
        pop     hl
        add     hl, bc

        ; Take bias element corresponding to current output component:
        ; HL <- HL + 4 * (10 - [wFullyConnectedOutputSize])
        ld      a, [wFullyConnectedOutputSizeVar + 1]
        cpl
        add     a, 1
        ld      c, a
        ld      a, [wFullyConnectedOutputSizeVar]
        cpl
        adc     a, 0
        ld      b, a

        ld      a, c
        add     a, 10
        ld      c, a
        ld      a, b
        adc     a, 0
        ld      b, a

        ; Multiply by 4: two shifts
        sla     c
        push    af
        ld      a, b
        sla     a
        ld      d, a
        pop     af
        ld      a, d
        adc     a, 0
        ld      b, a

        sla     c
        push    af
        ld      a, b
        sla     a
        ld      d, a
        pop     af
        ld      a, d
        adc     a, 0
        ld      b, a

        add     hl, bc

        ; HL now points to the bias element to add
        ld      bc, 4
        add     hl, bc

        ; Since the next layer starts right after the bias vector, we
        ; pre-calculate the next layer's address
        ld      bc, wFullyConnectedNextLayerAddrVar
        call    LoadHLtoAddressAtBC

        dec     hl
        ld      a, [wFullyConnectedOutputComponentVar + 3]
        add     a, [hl]
        dec     hl
        ld      [wFullyConnectedOutputComponentVar + 3], a
        ld      a, [wFullyConnectedOutputComponentVar + 2]
        adc     a, [hl]
        dec     hl
        ld      [wFullyConnectedOutputComponentVar + 2], a
        ld      a, [wFullyConnectedOutputComponentVar + 1]
        adc     a, [hl]
        dec     hl
        ld      [wFullyConnectedOutputComponentVar + 1], a
        ld      a, [wFullyConnectedOutputComponentVar]
        adc     a, [hl]
        dec     hl
        ld      [wFullyConnectedOutputComponentVar], a

        pop     de
        ret

.requantize:
        ; Multiply dot product + bias by M = 2^(-n) M_0
        push    de
        ; First, multiply the 32-bit result by M_0
        ; Load the dot product + bias result to Math32RegA
        ld      a, [wFullyConnectedOutputComponentVar]
        ld      [Math32RegA + 3], a
        ld      a, [wFullyConnectedOutputComponentVar + 1]
        ld      [Math32RegA + 2], a
        ld      a, [wFullyConnectedOutputComponentVar + 2]
        ld      [Math32RegA + 1], a
        ld      a, [wFullyConnectedOutputComponentVar + 3]
        ld      [Math32RegA], a
        ; Load M_0 to Math32RegB
        ld      bc, wFullyConnectedM0
        call    LoadAddressAtBCtoHL
        call    ld16B
        scf
        ccf
        ; Perform multiplication
        call    mul32
        ; Right shift result by n + 15 positions
        ld      a, [wFullyConnectedMExponent]
        add     a, 15
        ld      b, a
.rightShift:
        ld      a, [Math32RegC + 7]
        bit     7, a
        scf
        jr      nz, .noSignExtend
        ccf
.noSignExtend:
        call    sr32C
        dec     b
        jr      nz, .rightShift
        pop     de
        ret

.applyReLU:
        ld      a, [wFullyConnectedHasReLUActivation]
        or      a, a
        ret     z
        ld      a, [Math32RegC + 3]
        bit     7, a
        ret     z
        xor     a, a
        ld      [Math32RegC], a
        ret
