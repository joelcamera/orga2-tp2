
global ldr_asm3
extern malloc
extern free

section .data

MAXSUMA: dd 4876875.0, 4876875.0, 4876875.0, 4876875.0 ;float de precision simple

maskB:  DB  0x00,0xFF,0xFF,0xFF,  0x04,0xFF,0xFF,0xFF,  0x08,0xFF,0xFF,0xFF,  0x0C,0xFF,0xFF,0xFF  
maskG:  DB  0x01,0xFF,0xFF,0xFF,  0x05,0xFF,0xFF,0xFF,  0x09,0xFF,0xFF,0xFF,  0x0D,0xFF,0xFF,0xFF
maskR:  DB  0x02,0xFF,0xFF,0xFF,  0x06,0xFF,0xFF,0xFF,  0x0A,0xFF,0xFF,0xFF,  0x0E,0xFF,0xFF,0xFF

;maskSOLO1f:  DB  0x00,0x00,0x00,0x00,  0x00,0x00,0x00,0x00,  0xFF,0xFF,0xFF,0xFF,  0x00,0x00,0x00,0x00
;maskSOLO2f:  DB  0x00,0x00,0x00,0x00,  0xFF,0xFF,0xFF,0xFF,  0x00,0x00,0x00,0x00,  0x00,0x00,0x00,0x00 
maskMedio:  DB  0x00,0x00,0x00,0x00,  0xFF,0xFF,0xFF,0xFF,  0xFF,0xFF,0xFF,0xFF,  0x00,0x00,0x00,0x00 


maskA:  DB  0x00,0x00,0x00,0xFF,  0x00,0x00,0x00,0xFF,  0x00,0x00,0x00,0xFF,  0x00,0x00,0x00,0xFF
reord:  DB  0x00,0x04,0x08,0xFF,  0x01,0x05,0x09,0xFF,  0x02,0x06,0x0A,0xFF,  0x03,0x07,0x0B,0xFF



section .text



; rdi =  unsigned char *src,
; rsi =  unsigned char *dst,
; rdx =  int cols,
; rcx =  int filas,
; r8  =  int src_row_size,
; r9  =  int dst_row_size,
; [ALPA] = int alpha)
%define alpha rbp+16
%define saverdi rbp-8
ldr_asm3:
    push rbp
    mov rbp, rsp
    sub rsp, 8
    push rbx
    push r12
    push r13
    push r14
    push r15

    ;save pointers
    mov [saverdi], rdi
    mov rbx, rsi

    ;clean regs
    xor r12, r12
    xor r13, r13
    xor r14, r14
    xor r15, r15

    ;copy low regs
    mov r12d, edx   ;cols
    mov r13d, ecx   ;filas
    mov r14d, r8d   ;src_row_size
    ;mov r15d, r9d   ;dst_row_size

    shr r12, 2      ;divido por 4 la cantidad de pixels por col
    sub r12, 1      ;resto un ciclo porque se preprocesa al inicio

    ;alloco 5 filas de floats
    mov rdi, r14
    imul rdi, 5

    ;tengo en rax el puntero al buffer de ints
    call malloc
    cmp rax, 0
    je .fin

    ;restauro rsi
    mov rsi, rbx


    ;en r9 puntero al buffer
    mov r9, rax 


    ;restore rdi
    mov rdi, [saverdi]

    ;cargo marscaras
    movdqu xmm5, [maskB]
    movdqu xmm6, [maskG]
    movdqu xmm7, [maskR]
    movdqu xmm11, [maskMedio]
    movdqu xmm12, [maskA]    ;xmm12 mascara para tener los alphas en su posicion
    movdqu xmm13, [reord]    ;xmm13 mascara para tener el ultimo orden de los valores


    ;guardo alpha en rbx
    movss xmm15, [alpha]               ;xmm15 = 0 | 0 | 0 | alpha (segun el manual movss limpia la parte alta cuando src es un registro)
    shufps xmm15, xmm15, 0b00_00_00_00 ;xmm15 = alpha | alpha | alpha | alpha
    cvtdq2ps xmm15, xmm15              ;xmm15 = float(alpha) | float(alpha) | float(alpha) | float(alpha)

    movups xmm14, [MAXSUMA]            ;xmm14 = float(maxsuma) | float(maxsuma) | float(maxsuma) | float(maxsuma)


    mov r15, 0

    .cicloFila:


        

        ;calculo la suma de los primeros 4 pixels
        movdqu xmm0, [rdi]   ; xmm0 = argb 3| argb 2| argb 1| argb 0
        movdqa xmm2, xmm0    ; xmm2 = argb 3| argb 2| argb 1| argb 0
        movdqa xmm3, xmm0    ; xmm3 = argb 3| argb 2| argb 1| argb 0
        movdqa xmm4, xmm0    ; xmm4 = argb 3| argb 2| argb 1| argb 0

        pshufb xmm2, xmm5    ; xmm2 = 000b 3| 000b 2| 000b 1| 000b 0
        pshufb xmm3, xmm6    ; xmm3 = 000g 3| 000g 2| 000g 1| 000g 0
        pshufb xmm4, xmm7    ; xmm4 = 000r 3| 000r 2| 000r 1| 000r 0

        paddd  xmm2, xmm3    ;
        paddd  xmm2, xmm4    ; xmm2 = b+g+r 3| b+g+r 2| b+g+r 1| b+g+r 0

        cvtdq2ps xmm2, xmm2  ; xmm2 en floats

        movaps xmm8, xmm2    ; xmm8 = b+g+r 3| b+g+r 2| b+g+r 1| b+g+r 0
        haddps xmm2, xmm8    
        haddps xmm2, xmm2    ; horizontal add floats        
        movss  xmm9, xmm2    ; xmm9 = suma pixeles xmm8


        add rsi, 16
        add rdi, 16          ; paso primeros 4 pixels
        add r9, 8            ; paso primeros 2 floats del buffer
        mov r10, 2           ; uso r10 de contador de columnas

        mov rcx, r12
        .cicloColumna:


            movdqu xmm0, [rdi]   ; xmm0 = argb 3| argb 2| argb 1| argb 0
            movdqa xmm2, xmm0    ; xmm2 = argb 3| argb 2| argb 1| argb 0
            movdqa xmm3, xmm0    ; xmm3 = argb 3| argb 2| argb 1| argb 0
            movdqa xmm4, xmm0    ; xmm4 = argb 3| argb 2| argb 1| argb 0

            pshufb xmm2, xmm5    ; xmm2 = 000b 3| 000b 2| 000b 1| 000b 0
            pshufb xmm3, xmm6    ; xmm3 = 000g 3| 000g 2| 000g 1| 000g 0
            pshufb xmm4, xmm7    ; xmm4 = 000r 3| 000r 2| 000r 1| 000r 0

            paddd  xmm2, xmm3    ;
            paddd  xmm2, xmm4    ; xmm2 = b+g+r 3| b+g+r 2| b+g+r 1| b+g+r 0

            cvtdq2ps xmm2, xmm2  ; xmm2 en floats
                                 ; nuevas sumas
                                 ; f3 | f2 | f1 | f0
            
            movaps xmm10, xmm2    ; xmm10 = b+g+r 3| b+g+r 2| b+g+r 1| b+g+r 0
            haddps xmm2, xmm10    
            haddps xmm2, xmm2    ; horizontal add floats        
                                 ;  xx | xx | xx | sumanueva

            ;shufps xmm0, xmm8
            ;addss  xmm9, xmm2    ; sumaAnterior + nuevoPixel[0]
            ;movaps xmm8, 

                                  ; quiero poner en xmm9 que es la suma sumaAnterior
                                  ; sumaNueva | sumaNueva | sumaAnterior | sumaAnterior
                                  ; 00          00          00             00
            shufps xmm9, xmm2, 0


            movaps xmm1, xmm10    ; xmm1 =  nuevof3 | nuevof2 | nuevof1 | nuevof0
                                  ; quiero tener en xmm1 ant3 | ant3 | nuevo0 | nuevo0
                                  ;                        11 |  11  |   00   | 00
            
            shufps xmm1, xmm8, 0xF0   
            addps  xmm9, xmm1     ; xmm9 =  (7+6+5+4)+3 | (7+6+5+4)+3 | 4+(3+2+1+0) | 4+(3+2+1+0) 

            movaps xmm1, xmm10    ; xmm1 =  nuevof3    | nuevof2        |    nuevof1 |   nuevof0
                                  ; xmm8 =  antf3      | anftf2         |    antf1   |   antf0
                                  ; xmm1 =      X      | antf2          |    nuevof1 |   X
                                  ;      =      00     | 10             |    01      |   00
            shufps xmm1, xmm8,0x34; xmm1 =      X      | antf2          |    nuevof1 |   X

            andps  xmm1, xmm11    ; xmm1 =       0     | antf2          |    nuevof1 |   0

            addps  xmm9, xmm1     ; xmm9 =  (7+6+5+4)+3|  (7+6+5+4)+3+2 | 5+4+(3+2+1+0) | 4+(3+2+1+0) 

            movaps xmm1, xmm8     ; xmm1 =  antf3      | anftf2         |    antf1   |   antf0 
                                  ; xmm10=  nuevof3    | nuevof2        |    nuevof1 |   nuevof0
                                  ; xmm1 =      X      | nuevof3        |    antf0   |   X
                                  ;      =      00     | 11             |    00      |   00

            shufps xmm1, xmm10,0xF0
            andps  xmm1, xmm11    ; xmm1 =       0     | nuevof3        |    ant0    |   0

            subps  xmm9, xmm1     ; xmm9 =  (7+6+5+4)+3|  (6+5+4)+3+2   | 5+4+(3+2+1)| 4+(3+2+1+0) 

            movups [r9], xmm9     ; guardo en el buffer las sumas


            movaps xmm8, xmm10       ; guardo las partes nuevas para el proximo ciclio
            movaps xmm10, xmm2       ; guardo la suma actual en xmm10 hasta el final


            cmp r15, 3
            jle .sinOperar


            ; sumo verticalmente para tener sumaRGB en xmm9
            lea r11, [rax + r10 * 4]   ;r11 = buffer + columna * 4 
            movups xmm9, [r11]

            mov rdx, 4
            .sumaColumnas:
                add r11, r14           ;r11 += tamanio fila
                movups xmm3, [r11]
                addps xmm9, xmm3
            dec rdx
            jne .sumaColumnas

            
            mulps xmm9, xmm15     ;multiplico por alpha
            divps xmm9, xmm14     ;divido por max sum

            lea r11, [rdi-8]      ;r11 = puntero actual src - 2 columnas
            sub r11, r14          ;r11 -= una fila atras
            sub r11, r14          ;r11 -= una fila atras


            ;levanto los pixeles que ya puedo procesar
            movdqu xmm0, [r11]   ; xmm0 = argb 3| argb 2| argb 1| argb 0
            movdqa xmm2, xmm0    ; xmm2 = argb 3| argb 2| argb 1| argb 0
            movdqa xmm3, xmm0    ; xmm3 = argb 3| argb 2| argb 1| argb 0
            movdqa xmm4, xmm0    ; xmm4 = argb 3| argb 2| argb 1| argb 0

            pshufb xmm2, xmm5    ; xmm2 = 000b 3| 000b 2| 000b 1| 000b 0
            pshufb xmm3, xmm6    ; xmm3 = 000g 3| 000g 2| 000g 1| 000g 0
            pshufb xmm4, xmm7    ; xmm4 = 000r 3| 000r 2| 000r 1| 000r 0

            cvtdq2ps xmm2, xmm2  ; xmm2 en floats  blue  4 pixels
            cvtdq2ps xmm3, xmm3  ; xmm3 en floats  green 4 pixels
            cvtdq2ps xmm4, xmm4  ; xmm4 en floats  red   4 pixels

            movaps xmm1, xmm2    ; guardo componente
            mulps  xmm2, xmm9    ; multiplico por sumaRGB
            addps  xmm2, xmm1    ; summo componente

            movaps xmm1, xmm3    ; guardo componente
            mulps  xmm3, xmm9    ; multiplico por sumaRGB
            addps  xmm3, xmm1    ; summo componente

            movaps xmm1, xmm4    ; guardo componente
            mulps  xmm4, xmm9    ; multiplico por sumaRGB
            addps  xmm4, xmm1    ; summo componente



            ;muevo unos registros de mas para reutilizar codigo :)
            movaps xmm1, xmm4     ; xmm1 = r 
            movaps xmm4, xmm2     ; xmm4 = b
            movaps xmm2, xmm3     ; xmm2 = g
            movaps xmm3, xmm4     ; xmm3 = b

            ;los convierto a dword
            cvtps2dq xmm1, xmm1     ;xmm1 = r3 | r2 | r1 | r0
            cvtps2dq xmm2, xmm2     ;xmm2 = g3 | g2 | g1 | g0
            cvtps2dq xmm3, xmm3     ;xmm3 = b3 | b2 | b1 | b0

            ;los empaqueto para word y despues para byte
            packusdw xmm3, xmm2     ;xmm3 = g3 | g2 | g1 | g0 | b3 | b2 | b1 | b0
            packusdw xmm1, xmm1     ;xmm3 = r3 | r2 | r1 | r0 | r3 | r2 | r1 | r0
            
            packuswb xmm3, xmm1     ;xmm1 = r3 | r2 | r1 | r0 | r3 | r2 | r1 | r0 | g3 | g2 | g1 | g0 | b3 | b2 | b1 | b0

            ;reordeno los valores
            pshufb xmm3, xmm13       ;xmm1 = 0 | r3 | g3 | b3 | 0 | r2 | g2 | b2 | 0 | r1 | g1 | b1 | 0 | r0 | g0 | b0

            ;and de xmm0 para tener alphas
            pand xmm0, xmm12        ;xmm0 = a000(3) | a000(2) | a000(1) | a000(0)

            ;sumo al xmm0 que tengo los alpha en su posicion
            por xmm0, xmm3          ;xmm1 = a3 | r3 | g3 | b3 | a2 | r2 | g2 | b2 | a1 | r1 | g1 | b1 | a0 | r0 | g0 | b0


            lea r11, [rsi-8]      ;r11 = puntero actual dst - 2 columnas
            sub r11, r14          ;r11 -= una fila atras
            sub r11, r14          ;r11 -= una fila atras
            movdqu [r11], xmm0      ;paso los valores al dst


            .sinOperar:

            movaps xmm9, xmm10   ;muevo la suma nueva al lugar de la suma anterior


            add r10, 4           ;sumo 4 pixels 
            add r9, 16           ;avanzo en buffer
            add rdi, 16          ;avanzo en src
            add rsi, 16          ;avanzo en dst

        dec rcx
        jne .cicloColumna

        add r9, 8             ; salto los 2 ultimos floats de la fila del buffer no usados

        mov r11, r14          ; chequeo si hace falta volver al principio del buffer
        imul r11, 5
        add r11, rax
        cmp r9, r11
        jl .noResetBuffer
        mov r9, rax
        .noResetBuffer:


        add r15, 1            ; sumo una fila

    dec r13
    jne .cicloFila





    ;free buffer
    mov rdi, rax
    call free

   
    .fin:
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    add rsp, 8
    pop rbp
    ret
