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
