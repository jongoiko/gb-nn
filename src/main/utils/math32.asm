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
Math32RegC:: dl
StringSpace: ds 11

SECTION "Math32Utils", ROM0

ldir:
        ld      a, [hl+]
        ld      [de], a
        inc     de

        dec     bc
        ld      a, c
        or      a, b
        jr      nz, ldir
        ret

ld8A:
        call    ClearMath32RegA
        ld      [Math32RegA],a
        ret

ld8B:   ;Required for InString32
        call    ClearMath32RegB
        ld      [Math32RegB],a
        ret

ld8C:
        call    ClearMath32RegC
        ld      [Math32RegC],a
        ret

ld16A:
        ld      a, l
        ld      [Math32RegA], a
        ld      a, h
        ld      [Math32RegA+1], a
        xor     a, a
        ld      [Math32RegA+2], a
        ld      [Math32RegA+3], a
        ret

ld16B::
        ld      a, l
        ld      [Math32RegB], a
        ld      a, h
        ld      [Math32RegB+1], a
        xor     a, a
        ld      [Math32RegB+2], a
        ld      [Math32RegB+3], a
        ret

ld16C:
        ld      a, l
        ld      [Math32RegC], a
        ld      a, h
        ld      [Math32RegC+1], a
        xor     a, a
        ld      [Math32RegC+2], a
        ld      [Math32RegC+3], a
        ret

;63 bytes for all ld32 routins
ld32AB:
        ld      hl,Math32RegB
ld32A:  ;Total 9 bytes
        ld      de,Math32RegA   ;3
ld32:
        ld      bc,4            ;3
        call    ldir
        ret                     ;1

ld32AC: ;Required for IntString32
        ld      hl,Math32RegC
        jr      ld32A

ld32B:
        ld      de,Math32RegB
        jr      ld32

ld32BA:
        ld      hl,Math32RegA
        jr      ld32B

ld32BC:
        ld      hl,Math32RegC
        jr      ld32B


add32AB:                        ;Total 16 bytes
        ld      de,Math32RegB   ;3
add32A:
        ld      hl,Math32RegA   ;3
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
        ret                     ;1

add32C: ;Total 8 bytes
        ld      hl,Math32RegC   ;3
        jr      add32

add32CB:                        ;Required for mul32
        ld      de,Math32RegB   ;3
        jr      add32C


sub32AB:                        ;Required for div32
        ;IN  = Math32RegA, Math32RegB
        ;OUT = Math32RegA=Math32RegA-Math32RegB
        ld      hl,Math32RegB   ;3
sub32A:
        ld      de,Math32RegA   ;3
sub32:  ;Total 10 bytes
        or      a
sbc32:
        ld      b,4             ;2
sub32Loop:
        ld      a,[de]          ;1
        sbc     a,[hl]          ;1
        ld      [de],a          ;1
        inc     de              ;1
        inc     hl              ;1
        dec     b
        jr      nz, sub32Loop   ;2
        ret                     ;1

cp32AB: ;Required for div32
        ld      hl,Math32RegB+3
cp32A:
        ld      de,Math32RegA+3
cp32:
        ld      b,4
cp32Loop:
        ld      a,[de]
        cp      [hl]            ;[hl]-[de] c-hl<hl, nc-hl>=de, z-hl=de, nz-hl!=de
        ret     nz              ;[hl]!=[de] then done
        dec     hl
        dec     de              ;try next bytes
        dec     b
        jr      nz, cp32Loop
cp32Done:
        ret

cp32AC:
        ld      hl,Math32RegC+3
        jr      cp32A

cp32B:
        ld      de,Math32RegB+3
        jr      cp32

cp32BA:
        ld      hl,Math32RegA+3
        jr      cp32B

cp32BC: ;Required for div32
        ld      hl,Math32RegC+3
        jr      cp32B

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

sr32B:  ;5 110	Required for div32
        ld      hl,Math32RegB+3
        jr      sr32

sr32C::
        ld      hl,Math32RegC+3
        jr      sr32

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

sl32C:  ;Required for div32
        ld      hl,Math32RegC
        jr      sl32

ClearMath32RegA:                ;Total 11 bytes
        ld      hl,Math32RegA   ;3
ClearReg:                       ;Total 8 bytes
        ld      b,4             ;2
ClearRegLoop:
        ld      [hl],0          ;2
        inc     hl              ;1
        dec     b
        jr      nz, ClearRegLoop;2
        ret                     ;1

ClearMath32RegB:
        ld      hl,Math32RegB
        jr      ClearReg

ClearMath32RegC:                ;Required for mul32
        ld      hl,Math32RegC
        jr      ClearReg

mul32::
        call    ClearMath32RegC
        ld      b,32
mul32Loop:
        push    bc
        call    sr32A           ;3	push least sig bit of Math32RegA into carry
        jr      nc,mul32NoAdd   ;2	if carry=0 goto NoAdd
        call    add32CB         ;3	Math32RegC=Math32RegC+Math32RegB
mul32NoAdd:
        call    sl32B           ;3	Math32RegB=Math32RegB*2
        pop     bc
        dec     b
        jr      nz, mul32Loop
        ret

div32:  ;Total 38 bytes	Required for IntString32
        call    ClearMath32RegC
        call    cp32BC
        ret     z               ;check if b=0
        ld      c,1             ;2
        or      a               ;1	carry=0
div32Loop:
        ld      a,[Math32RegB+3];3 13
        bit     7,a             ;2 8	Test Most sig bit of Math32RegB
        jr      nz,div32Loop2   ;2 7	if it's 1 goto div32Ready else
        inc     c               ;1 4	inc c
        call    sl32B           ;3 127	shift Math32RegB left
        jr      div32Loop       ;2 12	loop time=171
div32Loop2:
        call    cp32AB          ;3
        jr      c,div32NoSub    ;2	if Math32RegA<Math32RegB goto div32NoSub else
        call    sub32AB         ;3	Math32RegA=Math32RegA-Math32RegB
div32NoSub:
        ccf                     ;1
        call    sl32C           ;3	left shift a 1 into Math32RegC
        call    sr32B           ;3	Math32RegB=Math32RegB/2			;1
        dec     c
        jr      nz,div32Loop2   ;2
        call    sl32B           ;Restore Math32RegB
        ret                     ;1

IntString32:
        ld      a,10
        call    ld8B            ;load 10 into Math32RegB
        ld      b,a             ;number of digits
        ld      hl,StringSpace+10
        ld      [hl],0          ;for 0 terminated string
IntString32Loop:
        push    bc              ;save b
        dec     hl              ;previous byte
        push    hl              ;save hl	BC:HL
        call    div32           ;divide Math32RegA by 10
        ld      a,[Math32RegA]  ;put answer in a
        add     a,48            ;add offset
        call    ld32AC          ;load Math32RegC into Math32RegA
        pop     hl
        pop     bc              ;get pointer & b
        ld      [hl],a          ;load char into pointer
        dec     b
        jr      nz, IntString32Loop
        ;get rid of preceding zeros
        ld      a,48
        ld      b,9             ;do at most 9 moves
IntStrnLoop2:
        cp      [hl]
        ret     nz
        inc     hl
        dec     b
        jr      nz, IntStrnLoop2
        ret

