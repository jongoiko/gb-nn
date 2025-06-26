; WARNING: This file was originally written by Humberto Yeverino Jr., but some
; routines have been modified to make mul32 work properly.
; In particular, the register C has been expanded to 8 bytes to be able to hold
; products of 4 byte integers. Also, mul32 has been modified to properly handle
; negative operands in two's complement.

;New 32-bit Math routines for the z80
;by Humberto Yeverino Jr.
;August 22, 1998

;*** Last updated August 27, 1998 ***

;Questions, bugs... complements,
;e-mail: humberto@engr.csufresno.edu
;TI WebPage: www.engr.csufresno.edu/~humberto/tex.html


;You are free to modify them and use them as you wish.
;be careful though, some routines rely on others.
;the shift routines could be smaller but mul32 and div32 use them
;a lot so I optimized for speed.
;If you find a way to optimize one of these routines e-mail me so I
;can update the file.  You will of course get credit.

;NOTE:
;To use these routines you must define 5 areas of memory
;three 4 byte chunks named Math32RegA, Math32RegB, and Math32RegC to be used as registers.
;one 11 byte chunk named StringSpace for creating strings from Math32RegA
;REMEMBER: you don't have to leave this space reserved.  Just remember that
;these areas will be written over when you use routines.
;For example, wherever you define StringSpace should be a place for all
;sort s of temorary data.


;Here are all the routines included and what they do.
;ld8A, ld8B, ld8C
;load a register into Math32RegA, Math32RegB, or Math32RegC
;destroys b and hl

;There are a lot of ld instructions but they are cheap on space.
;NOT ALL INSTRUCTIONS ARE IN THIS FILE.
;If you want to add another (ld32C for instance) you'll have to write it
;yourself. (but it's really easy)
;Just make sure you add it to this file, that way it will be faster & smaller

;But if you want to rewrite the IntString routine so that it creates a
;differnt format of string you might want to e-mail me.
;Later I will probably post different IntString routines on my z80 rouine
;page.

;LOAD---------------------------------------------------
;ld8A, ld8B, ld8C
;load register a into Math32RegA/Math32RegB/Math32RegC
;destroys hl and b

;ld16A, ld16B, ld16C
;load register hl into Math32RegA, Math32RegB, or Math32RegC
;detroys hl and b

;ld32
;copies memory from hl to de
;detroys b

;ld32A, ld32B
;copies memory from hl to Math32RegA, Math32RegB
;destroys bc, de and hl

;ld32AB, ld32AC, ld32BA, ld32BC
;load Math32RegA with Math32RegB/Math32RegC, load Math32RegB with Math32RegA/Math32RegC
;destroys bc, de and hl

;ADD---------------------------------------------------
;add32
;(hl):=(hl)+(de)
;destroys a, b, de and hl

;adc32
;same as add32 only adds carry flag also
;no register routines are supported for this one because it's likely you
;will never use it.  But it takes up no space so..

;add32A, add32C (you get the idea)
;Math32RegA=Math32RegA+(de)
;destroys a, b, de and hl

;add32AB, add32CB
;Math32RegA=Math32RegA+Math32RegB
;destroys a, b, de and hl

;SUB---------------------------------------------------
;sub32
;(hl):=(hl)-(de)
;destroys a, b, de and hl

;sbc32
;same as sub32 accept with carry

;sub32A
;Math32RegA=Math32RegA-(de)
;destroys a, b, de and hl

;sub32AB
;Math32RegA=Math32RegA-Math32RegB
;destroys a, b, de and hl

;CP----------------------------------------------------
;cp32
;compares (hl) to (de)
;destroys a, b, de and hl

;cp32A, cp32B
;compares Math32RegA to (de)
;destroys a, b, de and hl

;cp32AB, cp32AC, cp32BA, cp32BC
;compare Math32RegA to Math32RegB ect.
;destroys a, b, de and hl

;ALL of the shift instructions shift in the carry flag.
;SR----------------------------------------------------
;sr32
;shift (hl) right
;destroys hl

;sr32A, sr32B sr32C
;shift Math32RegA right ect.
;destroys hl

;SL----------------------------------------------------
;sl32
;shift (hl) left
;destroys hl

;sl32A, sl32B, sl32C
;shift Math32RegA left ect.
;destroys hl

;CLEARREG----------------------------------------------
;ClearReg
;sets (hl) to 0
;destroys b and hl

;ClearMath32RegA, ClearMath32RegB, ClearMath32RegC
;sets Math32RegA to 0 ect.
;destroys b and hl

;MUL & DIV---------------------------------------------
;mul32
;Math32RegC=Math32RegA*Math32RegB
;destroys a, b, de and hl

;div32
;Math32RegC=Math32RegA/Math32RegB, Math32RegA=Remainder, Math32RegB preserved
;destroys a, bc, de and hl

;INT TO STRING-----------------------------------------
;IntString32
;convert 32-bit int in Math32RegA to a string.
;hl->string
;Math32RegC=0, Math32RegA destroyed, Math32RegB preserved.
;destroys a, bc and de

SECTION "Math32Vars", WRAM0

Math32RegA:: dl
Math32RegB:: dl
Math32RegC:: ds 8
StringSpace: ds 11

multiplicationBShiftCarry: db

SECTION "Math32Utils", ROM0

ld16B::
        ld      a, l
        ld      [Math32RegB], a
        ld      a, h
        ld      [Math32RegB+1], a
        xor     a, a
        ld      [Math32RegB+2], a
        ld      [Math32RegB+3], a
        ret

add32:
        or      a
adc32:
        ld      b,4             ;2
add32Loop:
        ld      a,[de]          ;1
        adc     a,[hl]          ;1
        ld      [hl],a          ;1
        inc     hl              ;1
        inc     de              ;1
        dec     b
        jr      nz, add32Loop   ;2
        ; Second loop (remaining 4 bytes)
        ld      b,4             ;2
        ld      a, [multiplicationBShiftCarry]
add32Loop2:
        adc     a,[hl]          ;1
        ld      [hl],a          ;1
        inc     hl              ;1
        ld      a, 0
        dec     b
        jr      nz, add32Loop2
        ret                     ;1

add32C: ;Total 8 bytes
        ld      hl,Math32RegC   ;3
        jr      add32

add32CB:                        ;Required for mul32
        ld      de,Math32RegB   ;3
        jr      add32C

sr32A:  ;15 98 Required for mul32
        ld      hl,Math32RegA+3 ;3 10
sr32:   ;12 88
        rr      [hl]            ;2 15
        dec     hl              ;1 6
        rr      [hl]            ;2 15
        dec     hl              ;1 6
        rr      [hl]            ;2 15
        dec     hl              ;1 6
        rr      [hl]            ;2 15
        ret                     ;1 10

sr32C::
        ld      hl, Math32RegC + 7
        rr      [hl]            ;2 15
        dec     hl              ;1 6
        rr      [hl]            ;2 15
        dec     hl              ;1 6
        rr      [hl]            ;2 15
        dec     hl              ;1 6
        rr      [hl]            ;2 15
        dec     hl
        rr      [hl]            ;2 15
        dec     hl              ;1 6
        rr      [hl]            ;2 15
        dec     hl              ;1 6
        rr      [hl]            ;2 15
        dec     hl              ;1 6
        rr      [hl]            ;2 15
        ret

sl32A:  ;15 98	[hl]:=[hl]*2
        ld      hl,Math32RegA
sl32:   ;12 88
        rl      [hl]            ;2 15	rotate
        inc     hl              ;1 6	next byte
        rl      [hl]
        inc     hl
        rl      [hl]
        inc     hl
        rl      [hl]
        ret

sl32B:  ;5 110	Required for mul32 and div32
        ld      hl,Math32RegB   ;3 10
        jr      sl32            ;2 12

ClearRegLoop:
        ld      [hl],0          ;2
        inc     hl              ;1
        dec     b
        jr      nz, ClearRegLoop;2
        ret                     ;1

; Negate C-byte register pointed to by HL. Destroys HL and C
negateRegister:
        ld      a, [hl]
        cpl
        add     a, 1
        ld      [hl+], a
        dec     c
.loop:
        ld      a, [hl]
        cpl
        adc     a, 0
        ld      [hl+], a
        dec     c
        jr      nz, .loop
        ret

mul32::
        ld      hl, Math32RegC
        ld      b, 8
        call    ClearRegLoop
        xor     a, a
        ld      [multiplicationBShiftCarry], a
        ; Negate operands if they are negative
        ld      a, [Math32RegA + 3]
        ld      b, a
        bit     7, a
        jr      z, .operandANonNegative
        ; Negate Math32RegA
        ld      hl, Math32RegA
        ld      c, 4
        call    negateRegister
.operandANonNegative:
        ld      a, [Math32RegB + 3]
        bit     7, a
        push    bc
        push    af
        jr      z, .operandBNonNegative
        ; Negate Math32RegB
        ld      hl, Math32RegB
        ld      c, 4
        call    negateRegister
.operandBNonNegative:
        ld      b,32
mul32Loop:
        push    bc
        call    sr32A           ;3	push least sig bit of Math32RegA into carry
        jr      nc,mul32NoAdd   ;2	if carry=0 goto NoAdd
        call    add32CB         ;3	Math32RegC=Math32RegC+Math32RegB
mul32NoAdd:
        call    sl32B           ;3	Math32RegB=Math32RegB*2
        jr      nc, .noShiftCarry
        ld      a, 1
        ld      [multiplicationBShiftCarry], a
.noShiftCarry:
        pop     bc
        dec     b
        jr      nz, mul32Loop
        ; Negate the product if exactly one operand was negative
        pop     af
        pop     bc
        xor     a, b
        bit     7, a
        ret     z
        ld      hl, Math32RegC
        ld      c, 8
        call    negateRegister
        ret
