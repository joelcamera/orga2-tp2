
global ldr_asm2

section .data

MAXSUMA: dd 4876875.0, 4876875.0, 4876875.0, 4876875.0 ;float de precision simple
MASK: dw 0xFFFF, 0xFFFF, 0xFFFF, 0x0000, 0xFFFF, 0xFFFF, 0xFFFF, 0x0000

section .text

%define P 2
%define mP -2

;pixel(p,i,j, *base, row_size)
;p = base + i*row_size + j*4
%macro pixelIJ 5
    mov %1, %2   ; p = i
    imul %1, %5  ; p = i*row_size
    lea %1, [%1+%3*4] ; p = i*row_size+j*4
    add %1, %4    ; p = base+i*row_size+j*4
    ;p = pixel en fila i columna j
%endmacro

;void ldr_asm    (
	;unsigned char *src,
	;unsigned char *dst,
	;int cols,
	;int filas,
	;int src_row_size,
	;int dst_row_size,
	;int alpha)

; rdi = *src
; rsi = *dst
; edx = cols            
; ecx = filas           
; r8d  = src_row_size
; r9d  = dst_row_size
%define VAR_ALPHA rbp+16

ldr_asm2:
    push rbp
    mov rbp, rsp
    push r12
    push r13

    ;limpia parte alta de los registros
    mov edx, edx
    mov ecx, ecx
    mov r8d, r8d
    mov r9d, r9d

    sub rdx, P
    sub rcx, P

    movss xmm15, [VAR_ALPHA]           ;xmm15 = 0 | 0 | 0 | alpha (segun el manual movss limpia la parte alta cuando src es un registro)
    shufps xmm15, xmm15, 0b01_00_00_00 ;xmm15 = 0 | alpha | alpha | alpha
    cvtdq2ps xmm15, xmm15              ;xmm15 = 0 | float(alpha) | float(alpha) | float(alpha)

    movups xmm0, [MAXSUMA] ;xmm0 = float(maxsuma) | float(maxsuma) | float(maxsuma) | float(maxsuma)

    ;esta mascara es para limpiar el alpha de los pixeles
    movdqu xmm14, [MASK] ;xmm14 = 0000 | FFFF | FFFF | FFFF | 0000 | FFFF | FFFF | FFFF   

    ;guardamos este registro limpio, nos va a ser util para desempaquetar los pixeles
    pxor xmm9, xmm9

    ;ciclo
    xor r12, r12
    add r12, P
    .cicloFilas: ;r12 = i, P<=i<filas-P
    
    xor r13, r13
    add r13, P
    .cicloCols: ;r13 = j, P<=j<cols-P

    ;limpio los registros para acumular la suma de las columnas
    pxor xmm1, xmm1
    pxor xmm3, xmm3
    pxor xmm5, xmm5
    pxor xmm7, xmm7

    sub r13, P

    mov r10, P
    .cicloSuma:

    mov rax, r12  ;rax=fila i
    add rax, r10  ;rax=fila i+P

    pixelIJ r11, rax, r13, rdi, r8 ;pixel del src

    ;[r11] = pixel1 | pixel2 | pixel3 | pixel4 | pixel5 | pixel6 | pixel7 | pixel8 ...

    movdqu xmm4, [r11]   ;xmm4 = a4 r4 g4 b4 | a3 r3 g3 b3 | a2 r2 g2 b2 | a1 r1 g1 b1
    movdqa xmm2, xmm4    ;xmm2 = a4 r4 g4 b4 | a3 r3 g3 b3 | a2 r2 g2 b2 | a1 r1 g1 b1
    punpcklbw xmm2, xmm9 ;xmm2 = a2 r2 g2 b2 | a1 r1 g1 b1
    punpckhbw xmm4, xmm9 ;xmm4 = a4 r4 g4 b4 | a3 r3 g3 b3

    add r11, 16 ;levanto los 4 pixeles siguientes, 4 pixeles de 4bytes cada uno = 16bytes

    movdqu xmm8, [r11]   ;xmm8 = a8 r8 g8 b8 | a7 r7 g7 b7 | a6 r6 g6 b6 | a5 r5 g5 b5
    movdqa xmm6, xmm8    ;xmm6 = a8 r8 g8 b8 | a7 r7 g7 b7 | a6 r6 g6 b6 | a5 r5 g5 b5
    punpcklbw xmm6, xmm9 ;xmm6 = a6 r6 g6 b6 | a5 r5 g5 b5
    punpckhbw xmm8, xmm9 ;xmm8 = a8 r8 g8 b8 | a7 r7 g7 b7

    ;acumular en columnas
    paddw xmm1, xmm2
    paddw xmm3, xmm4
    paddw xmm5, xmm6
    paddw xmm7, xmm8

    dec r10
    cmp r10, mP
    jge .cicloSuma

    add r13, P

    ;xmm1 = suma col2 | suma col1
    ;xmm3 = suma col4 | suma col3
    ;xmm5 = suma col6 | suma col5
    ;xmm7 = suma col8 | suma col7

    ;limpiamos el alpha de las sumas de las columnas
    pand xmm1, xmm14 ;xmm1 = 0 r2 g2 b2 | 0 r1 g1 b1
    pand xmm3, xmm14 ;xmm3 = 0 r4 g4 b4 | 0 r3 g3 b3
    pand xmm5, xmm14 ;xmm5 = 0 r6 g6 b6 | 0 r5 g5 b5
    pand xmm7, xmm14 ;xmm7 = 0 r8 g8 b8 | 0 r7 g7 b7

    ;extendemos los componentes de la suma de cada columna a un dword en un registro individual
    movdqa xmm2, xmm1
    punpcklwd xmm1, xmm9 ;xmm1 = 0 | r1 | g1 | b1
    punpckhwd xmm2, xmm9 ;xmm2 = 0 | r2 | g2 | b2

    movdqa xmm4, xmm3
    punpcklwd xmm3, xmm9 ;xmm3 = 0 | r3 | g3 | b3
    punpckhwd xmm4, xmm9 ;xmm4 = 0 | r4 | g4 | b4

    movdqa xmm6, xmm5
    punpcklwd xmm5, xmm9 ;xmm5 = 0 | r5 | g5 | b5
    punpckhwd xmm6, xmm9 ;xmm6 = 0 | r6 | g6 | b6

    movdqa xmm8, xmm7
    punpcklwd xmm7, xmm9 ;xmm7 = 0 | r7 | g7 | b7
    punpckhwd xmm8, xmm9 ;xmm8 = 0 | r8 | g8 | b8

    ;sumamos verticalmente las primeras 5 columnas y luego horizontalmente, este sumrgb corresponde al primer pixel
    paddd xmm4, xmm1  ;xmm4 = 0 | r1+r4          | g1+g4          | b1+b4
    paddd xmm4, xmm2  ;xmm4 = 0 | r1+r2+r4       | g1+g2+g4       | b1+b2+b4
    paddd xmm4, xmm3  ;xmm4 = 0 | r1+r2+r3+r4    | g1+g2+g3+g4    | b1+b2+b3+b4
    paddd xmm4, xmm5  ;xmm4 = 0 | r1+r2+r3+r4+r5 | g1+g2+g3+g4+g5 | b1+b2+b3+b4+b5

    phaddd xmm4, xmm4 ; xmm4 = 0+r1+r2+r3+r4+r5 | g1+g2+g3+g4+g5+b1+b2+b3+b4+b5 | 0+r1+r2+r3+r4+r5 | g1+g2+g3+g4+g5+b1+b2+b3+b4+b5
    phaddd xmm4, xmm4 ; xmm4 = sumrgb_1 | sumrgb_1 | sumrgb_1 | sumrgb_1 (dword)

    ;preparamos la suma horizontal de otras columnas que vamos a necesitar para procesar los otros 3 pixeles siguientes
    phaddd xmm1, xmm1 ;xmm1 = 0+r1 | g1+b1 | 0+r1 | g1+b1
    phaddd xmm1, xmm1 ;xmm1 = 0+r1+g1+b1 | 0+r1+g1+b1 | 0+r1+g1+b1 | 0+r1+g1+b1

    phaddd xmm2, xmm2 ;
    phaddd xmm2, xmm2 ;xmm2 = 0+r2+g2+b2 | 0+r2+g2+b2 | 0+r2+g2+b2 | 0+r2+g2+b2

    phaddd xmm3, xmm3 ;
    phaddd xmm3, xmm3 ;xmm3 = 0+r3+g3+b3 | 0+r3+g3+b3 | 0+r3+g3+b3 | 0+r3+g3+b3

    phaddd xmm6, xmm6 ;
    phaddd xmm6, xmm6 ;xmm6 = 0+r6+g6+b6 | 0+r6+g6+b6 | 0+r6+g6+b6 | 0+r6+g6+b6

    phaddd xmm7, xmm7 ;
    phaddd xmm7, xmm7 ;xmm7 = 0+r7+g7+b7 | 0+r7+g7+b7 | 0+r7+g7+b7 | 0+r7+g7+b7

    phaddd xmm8, xmm8 ;
    phaddd xmm8, xmm8 ;xmm8 = 0+r8+g8+b8 | 0+r8+g8+b8 | 0+r8+g8+b8 | 0+r8+g8+b8

    ;---

    pixelIJ r11, r12, r13, rdi, r8 ;pixel src
    pixelIJ r10, r12, r13, rsi, r9 ;pixel dst

    ;levanto 4 pixeles de src
    movdqu xmm10, [r11] ;xmm10 = a4 r4 g4 b4 | a3 r3 g3 b3 | a2 r2 g2 b2 | a1 r1 g1 b1

    ;xmm4 = sumrgb_1 | sumrgb_1 | sumrgb_1 | sumrgb_1 (dword)
    ;xmm0 = maxsum | maxsum | maxsum | maxsum (float)
    ;xmm15 = 0 | alpha | alpha | alpha (float)

    ;---primer pixel---

    cvtdq2ps xmm5, xmm4  ;xmm5 = float(sumrgb_1) | float(sumrgb_1) | float(sumrgb_1) | float(sumrgb_1)
    mulps xmm5, xmm15    ;xmm5 = 0 | alpha*sumrgb_1 | alpha*sumrgb_1 | alpha*sumrgb_1
    divps xmm5, xmm0     ;xmm5 = 0 | alpha*sumrgb_1/maxsum | alpha*sumrgb_1/maxsum | alpha*sumrgb_1/maxsum

    ;copiamos los 4 pixeles que levantamos
    movdqa xmm11, xmm10   ;xmm11 = a4 r4 g4 b4 | a3 r3 g3 b3 | a2 r2 g2 b2 | a1 r1 g1 b1

    ;desempaquetamos los dos primeros de byte a word
    punpcklbw xmm11, xmm9 ;xmm11 = a2 r2 g2 b2 | a1 r1 g1 b1

    ;desempaquetamos de word a dword el primer pixel, ahora en xmm11 tenemos el primer pixel en dword signado
    punpcklwd xmm11, xmm9 ;xmm11 = a1 | r1 | g1 | b1

    ;convertimos a float
    cvtdq2ps xmm11, xmm11 ;xmm11 = float(a1) | float(r1) | float(g1) | float(b1)

    ;copiamos el pixel
    movaps xmm12, xmm11   ;xmm12 = float(a1) | float(r1) | float(g1) | float(b1)

    ;multiplicamos
    mulps xmm11, xmm5     ;xmm11 = 0 | r1*alpha*sumrgb_1/maxsum    | g1*alpha*sumrgb_1/maxsum    | b1*alpha*sumrgb_1/maxsum

    ;sumamos y tenemos el primer pixel resultante en float
    addps xmm11, xmm12    ;xmm11 = a1 | r1+r1*alpha*sumrgb_1/maxsum | g1+g1*alpha*sumrgb_1/maxsum | b1+b1*alpha*sumrgb_1/maxsum

    ;convertimos y empaquetamos
    cvtps2dq xmm11, xmm11 ;xmm11 = a1 | ldr_r1 | ldr_g1 | ldr_b1 (dword signado)
    packssdw xmm11, xmm9  ;xmm11 = 0 | 0 | 0 | 0 | a1 | ldr_r1 | ldr_g1 | ldr_b1 (word signado)
    packuswb xmm11, xmm9  ;xmm11 = 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | a1 | ldr_r1 | ldr_g1 | ldr_b1 (byte sin signo saturado)

    ;en xmm13 vamos a guardar el resultado
    movdqa xmm13, xmm11   ;xmm13 = 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | a1 | ldr_r1 | ldr_g1 | ldr_b1

    ;---segundo pixel---

    ;restamos en xmm4 la primer columna y sumamos la sexta, entonces en xmm4 tenemos sumrgb para el segundo pixel
    psubd xmm4, xmm1
    paddd xmm4, xmm6    ;xmm4 = sumrgb_2 | sumrgb_2 | sumrgb_2 | sumrgb_2 (dword)

    cvtdq2ps xmm5, xmm4 ;xmm5 = float(sumrgb_2) | float(sumrgb_2) | float(sumrgb_2) | float(sumrgb_2)
    mulps xmm5, xmm15   ;xmm5 = 0 | alpha*sumrgb_2 | alpha*sumrgb_2 | alpha*sumrgb_2
    divps xmm5, xmm0    ;xmm5 = 0 | alpha*sumrgb_2/maxsum | alpha*sumrgb_2/maxsum | alpha*sumrgb_2/maxsum

    movdqa xmm11, xmm10   ;xmm11 = a4 r4 g4 b4 | a3 r3 g3 b3 | a2 r2 g2 b2 | a1 r1 g1 b1 (bytes)
    punpcklbw xmm11, xmm9 ;xmm11 = a2 r2 g2 b2 | a1 r1 g1 b1 (words)
    punpckhwd xmm11, xmm9 ;xmm11 = a2 | r2 | g2 | b2 (dwords)
    cvtdq2ps xmm11, xmm11 ;xmm11 = float(a2) | float(r2) | float(g2) | float(b2)
    movaps xmm12, xmm11   ;xmm12 = float(a2) | float(r2) | float(g2) | float(b2)
    mulps xmm11, xmm5     ;xmm11 = 0 | r2*alpha*sumrgb_2/maxsum    | g2*alpha*sumrgb_2/maxsum    | b2*alpha*sumrgb_2/maxsum
    addps xmm11, xmm12    ;xmm11 = a2 | r2+r2*alpha*sumrgb_2/maxsum | g2+g2*alpha*sumrgb_2/maxsum | b2+b2*alpha*sumrgb_2/maxsum

    cvtps2dq xmm11, xmm11 ;xmm11 = a2 | ldr_r2 | ldr_g2 | ldr_b2 (dword signado)
    packssdw xmm11, xmm9  ;xmm11 = 0 | 0 | 0 | 0 | a2 | ldr_r2 | ldr_g1 | ldr_b2 (word signado)
    packuswb xmm11, xmm9  ;xmm11 = 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0  | 0      | 0      | 0      | a2 | ldr_r2 | ldr_g2 | ldr_b2 (byte sin signo saturado)
    pslldq xmm11, 4       ;xmm11 = 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | a2 | ldr_r2 | ldr_g2 | ldr_b2 | 0  | 0      | 0      | 0

    por xmm13, xmm11      ;xmm13 = 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | a2 | ldr_r2 | ldr_g2 | ldr_b2 | a1  | ldr_r1 | ldr_g1 | ldr_b1

    ;---tercer pixel---

    ;restamos en xmm4 la segunda columna y sumamos la septima, en xmm4 tenemos sumrgb para el tercer pixel
    psubd xmm4, xmm2
    paddd xmm4, xmm7

    cvtdq2ps xmm5, xmm4 ;xmm5 = float(sumrgb_3) | float(sumrgb_3) | float(sumrgb_3) | float(sumrgb_3)
    mulps xmm5, xmm15   ;xmm5 = 0 | alpha*sumrgb_3 | alpha*sumrgb_3 | alpha*sumrgb_3
    divps xmm5, xmm0    ;xmm5 = 0 | alpha*sumrgb_3/maxsum | alpha*sumrgb_3/maxsum | alpha*sumrgb_3/maxsum

    movdqa xmm11, xmm10   ;xmm11 = a4 r4 g4 b4 | a3 r3 g3 b3 | a2 r2 g2 b2 | a1 r1 g1 b1 (bytes)
    punpckhbw xmm11, xmm9 ;xmm11 = a4 r4 g4 b4 | a3 r3 g3 b3 (words)
    punpcklwd xmm11, xmm9 ;xmm11 = a3 | r3 | g3 | b3 (dwords)
    cvtdq2ps xmm11, xmm11 ;xmm11 = float(a3) | float(r3) | float(g3) | float(b3)
    movaps xmm12, xmm11   ;xmm12 = float(a3) | float(r3) | float(g3) | float(b3)
    mulps xmm11, xmm5     ;xmm11 = 0 | r3*alpha*sumrgb_3/maxsum    | g3*alpha*sumrgb_3/maxsum    | b3*alpha*sumrgb_3/maxsum
    addps xmm11, xmm12    ;xmm11 = a3 | r3+r3*alpha*sumrgb_3/maxsum | g3+g3*alpha*sumrgb_3/maxsum | b3+b3*alpha*sumrgb_3/maxsum

    cvtps2dq xmm11, xmm11 ;xmm11 = a3 | ldr_r3 | ldr_g3 | ldr_b3 (dword signado)
    packssdw xmm11, xmm9  ;xmm11 = 0 | 0 | 0 | 0 | a3 | ldr_r3 | ldr_g3 | ldr_b3 (word signado)
    packuswb xmm11, xmm9  ;xmm11 = 0 | 0 | 0 | 0 | 0  | 0      | 0      | 0      | 0 | 0 | 0 | 0 | a3 | ldr_r3 | ldr_g3 | ldr_b3 (byte sin signo saturado)
    pslldq xmm11, 8       ;xmm11 = 0 | 0 | 0 | 0 | a3 | ldr_r3 | ldr_g3 | ldr_b3 | 0 | 0 | 0 | 0 | 0  | 0      | 0      | 0

    por xmm13, xmm11      ;xmm13 = 0 | 0 | 0 | 0 | a3 | ldr_r3 | ldr_g3 | ldr_b3 | a2 | ldr_r2 | ldr_g2 | ldr_b2 | a1  | ldr_r1 | ldr_g1 | ldr_b1

    ;---cuarto pixel---

    ;restamos en xmm4 la tercer columna y sumamos la octava, en xmm4 tenemos sumrgb para el cuarto pixel
    psubd xmm4, xmm3
    paddd xmm4, xmm8

    cvtdq2ps xmm5, xmm4 ;xmm5 = float(sumrgb_4) | float(sumrgb_4) | float(sumrgb_4) | float(sumrgb_4)
    mulps xmm5, xmm15   ;xmm5 = 0 | alpha*sumrgb_4 | alpha*sumrgb_4 | alpha*sumrgb_4
    divps xmm5, xmm0    ;xmm5 = 0 | alpha*sumrgb_4/maxsum | alpha*sumrgb_4/maxsum | alpha*sumrgb_4/maxsum

    movdqa xmm11, xmm10   ;xmm11 = a4 r4 g4 b4 | a3 r3 g3 b3 | a2 r2 g2 b2 | a1 r1 g1 b1 (bytes)
    punpckhbw xmm11, xmm9 ;xmm11 = a4 r4 g4 b4 | a3 r3 g3 b3 (words)
    punpckhwd xmm11, xmm9 ;xmm11 = a4 | r4 | g4 | b4 (dwords)
    cvtdq2ps xmm11, xmm11 ;xmm11 = float(a4) | float(r4) | float(g4) | float(b4)
    movaps xmm12, xmm11   ;xmm12 = float(a4) | float(r4) | float(g4) | float(b4)
    mulps xmm11, xmm5     ;xmm11 = 0  | r4*alpha*sumrgb_4/maxsum    | g4*alpha*sumrgb_4/maxsum    | b4*alpha*sumrgb_4/maxsum
    addps xmm11, xmm12    ;xmm11 = a4 | r4+r4*alpha*sumrgb_4/maxsum | g4+g4*alpha*sumrgb_4/maxsum | b4+b4*alpha*sumrgb_4/maxsum

    cvtps2dq xmm11, xmm11 ;xmm11 = a4 | ldr_r4 | ldr_g4 | ldr_b4 (dword signado)
    packssdw xmm11, xmm9  ;xmm11 = 0 | 0 | 0 | 0 | a4 | ldr_r4 | ldr_g4 | ldr_b4 (word signado)
    packuswb xmm11, xmm9  ;xmm11 = 0  | 0      | 0      | 0      | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | a4 | ldr_r4 | ldr_g4 | ldr_b4 (byte sin signo saturado)
    pslldq xmm11, 12      ;xmm11 = a4 | ldr_r4 | ldr_g4 | ldr_b4 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0  | 0      | 0      | 0

    por xmm13, xmm11 ;xmm13 = a4 | ldr_r4 | ldr_g4 | ldr_b4 | a3 | ldr_r3 | ldr_g3 | ldr_b3 | a2 | ldr_r2 | ldr_g2 | ldr_b2 | a1  | ldr_r1 | ldr_g1 | ldr_b1

    ;guardo los 4 pixeles resultantes en dst
    movdqu [r10], xmm13

    add r13, 4
    cmp r13, rdx
    jl .cicloCols

    inc r12
    cmp r12, rcx
    jl .cicloFilas

    pop r13
    pop r12
    pop rbp
    ret
