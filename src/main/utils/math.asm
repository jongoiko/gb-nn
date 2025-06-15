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

; Routine from https://tutorials.eeems.ca/Z80ASM/part4.htm
MultiplyHandEintoHLNN::
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
