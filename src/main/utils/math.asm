SECTION "MathUtils", ROM0

MultiplyHandEintoHL::
        ld      d, 0
        ld      l, 0
        sla     h
        add     hl, hl
        jr      nc, @+3
        add     hl, de

        add     hl, hl
        jr      nc, @+3
        add     hl, de

        add     hl, hl
        jr      nc, @+3
        add     hl, de

        add     hl, hl
        jr      nc, @+3
        add     hl, de

        add     hl, hl
        jr      nc, @+3
        add     hl, de

        add     hl, hl
        jr      nc, @+3
        add     hl, de

        add     hl, hl
        jr      nc, @+3
        add     hl, de
        ret

; Routine adapted from https://tutorials.eeems.ca/Z80ASM/part4.htm
; Modified to handle signed operands.
MultiplyHandEintoHLNN::
        ld      a, h
        xor     a, e
        push    af
        bit     7, h
        jr      z, .hNonNegative
        ld      a, h
        cpl
        inc     a
        ld      h, a
.hNonNegative
        bit     7, e
        jr      z, .eNonNegative
        ld      a, e
        cpl
        inc     a
        ld      e, a
.eNonNegative
        ld      d, 0
        ld      l, d
        ld      b, 8
.loop:
        add     hl, hl
        jr      nc, .skip
        add     hl, de
.skip:
        dec     b
        jr      nz, .loop
        pop     af
        bit     7, a
        ret     z
        ; Exactly one of H or E were negative: negate the unsigned product
        ld      a, l
        cpl
        add     a, 1
        ld      l, a
        ld      a, h
        cpl
        adc     a, 0
        ld      h, a
        ret

; Routine from https://tutorials.eeems.ca/Z80ASM/part4.htm
MultiplyBCandDEintoDEHL::
        ld      hl, 0
        ld      a, 16
.loop:
        add     hl, hl
        rl      e
        rl      d
jp      nc,     .noMul16
        add     hl, bc
        jr      nc, .noMul16
        inc     de
.noMul16:
        dec     a
        jr      nz, .loop
        ret
