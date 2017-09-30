GLOBAL sepia_asm2

section .data


section .rodata
maskB:  DB  0x00,0xFF,0xFF,0xFF,  0x04,0xFF,0xFF,0xFF,  0x08,0xFF,0xFF,0xFF,  0x0C,0xFF,0xFF,0xFF  
maskG:  DB  0x01,0xFF,0xFF,0xFF,  0x05,0xFF,0xFF,0xFF,  0x09,0xFF,0xFF,0xFF,  0x0D,0xFF,0xFF,0xFF
maskR:  DB  0x02,0xFF,0xFF,0xFF,  0x06,0xFF,0xFF,0xFF,  0x0A,0xFF,0xFF,0xFF,  0x0E,0xFF,0xFF,0xFF

maskA:  DB  0x00,0x00,0x00,0xFF,  0x00,0x00,0x00,0xFF,  0x00,0x00,0x00,0xFF,  0x00,0x00,0x00,0xFF

cinco:	DD  0.5, 0.5, 0.5, 0.5
tres:	DD  0.3, 0.3, 0.3, 0.3
dos:	DD  0.2, 0.2, 0.2, 0.2

reord:  DB  0x00,0x04,0x08,0xFF,  0x01,0x05,0x09,0xFF,  0x02,0x06,0x0A,0xFF,  0x03,0x07,0x0B,0xFF


section .text
;void sepia_c (unsigned char *src, unsigned char *dst, int cols, int filas, int src_row_size, int dst_row_size);

;rdi(src), rsi(dst), edx(cols), ecx(filas), r8d(src_row_size), r9d(dst_row_size)

sepia_asm2:

push rbp
mov rbp, rsp


;limpio la parte alta de los registros edx, ecx, r8d, r9d
mov edx, edx
mov ecx, ecx
shr rdx, 2				;divido por 4 porque levanto de a 4 pixeles

mov rax, 0
mov rax, rdx			;la cantidad de columnas la tenbo en rbx


movdqu xmm15, [maskB]	;xmm15 mascara para tener b3 | b2 | b1 | b0
movdqu xmm14, [maskG]	;xmm14 mascara para tener g3 | g2 | g1 | g0
movdqu xmm13, [maskR]	;xmm13 mascara para tener r3 | r2 | r1 | r0
movdqu xmm12, [maskA]	;xmm12 mascara para tener los alphas en su posicion

movups xmm11, [cinco]	;xmm11 = 0.5 | 0.5 | 0.5 | 0.5
movups xmm10, [tres]	;xmm10 = 0.3 | 0.3 | 0.3 | 0.3
movups xmm9, [dos]		;xmm9 = 0.2 | 0.2 | 0.2 | 0.2

movdqu xmm8, [reord]	;xmm8 mascara para tener el ultimo orden de los valores


.cicloFila:
	
	mov rdx, rax		;reseteo la cantidad de columnas

	.cicloColumna:

	movdqu xmm0, [rdi]		;xmm0 = argb3 | argb2 | argb1 | argb0
	movdqa xmm1, xmm0		;xmm1 = argb3 | argb2 | argb1 | argb0
	movdqa xmm2, xmm0		;xmm2 = argb3 | argb2 | argb1 | argb0
	movdqa xmm3, xmm0		;xmm3 = argb3 | argb2 | argb1 | argb0

	pshufb xmm1, xmm15		;xmm1 = 000b3 | 000b2 | 000b1 | 000b0
	pshufb xmm2, xmm14		;xmm2 = 000g3 | 000g2 | 000g1 | 000g0
	pshufb xmm3, xmm13		;xmm3 = 000r3 | 000r2 | 000r1 | 000r0

	pand xmm0, xmm12		;xmm0 = a000(3) | a000(2) | a000(1) | a000(0)

	paddd xmm1, xmm2		;xmm1 = b+g 3 | b+g 2 | b+g 1 | b+g 0
	paddd xmm1, xmm3		;xmm1 = b+g+r 3 | b+g+r 2 | b+g+r 1 | b+g+r 0

	cvtdq2ps xmm1, xmm1		;paso la suma a float

	movaps xmm2, xmm1		;xmm2 = suma
	movaps xmm3, xmm1		;xmm3 = suma

	mulps xmm1, xmm11		;xmm1 = suma*0.5 (red)
	mulps xmm2, xmm10		;xmm2 = suma*0.3 (green)
	mulps xmm3, xmm9		;xmm3 = suma*0.2 (blue)

	;los convierto a dword
	cvtps2dq xmm1, xmm1		;xmm1 = r3 | r2 | r1 | r0
	cvtps2dq xmm2, xmm2		;xmm2 = g3 | g2 | g1 | g0
	cvtps2dq xmm3, xmm3		;xmm3 = b3 | b2 | b1 | b0

	;los empaqueto para word y despues para byte
	packusdw xmm3, xmm2		;xmm3 = g3 | g2 | g1 | g0 | b3 | b2 | b1 | b0
	packusdw xmm1, xmm1		;xmm3 = r3 | r2 | r1 | r0 | r3 | r2 | r1 | r0
	
	packuswb xmm3, xmm1		;xmm1 = r3 | r2 | r1 | r0 | r3 | r2 | r1 | r0 | g3 | g2 | g1 | g0 | b3 | b2 | b1 | b0

	;reordeno los valores
	pshufb xmm3, xmm8		;xmm1 = 0 | r3 | g3 | b3 | 0 | r2 | g2 | b2 | 0 | r1 | g1 | b1 | 0 | r0 | g0 | b0

	;sumo al xmm0 que tengo los alpha en su posicion
	por xmm0, xmm3			;xmm1 = a3 | r3 | g3 | b3 | a2 | r2 | g2 | b2 | a1 | r1 | g1 | b1 | a0 | r0 | g0 | b0

 	movdqu [rsi], xmm0		;paso los valores al dst

 	add rdi, 16				;actualizo punteros
 	add rsi, 16

 	dec rdx
 	jne .cicloColumna


dec rcx				;decremento el contador de filas, si es igual a cero sale
jne .cicloFila


.fin:
pop rbp
ret