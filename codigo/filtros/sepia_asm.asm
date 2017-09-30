section .data
DEFAULT REL

section .rodata
maskB: DB 0x00,0xFF,0xFF,0xFF, 0x04,0xFF,0xFF,0xFF, 0x08,0xFF,0xFF,0xFF, 0x0C,0xFF,0xFF,0xFF
maskG: DB 0x01,0xFF,0xFF,0xFF, 0x05,0xFF,0xFF,0xFF, 0x09,0xFF,0xFF,0xFF, 0x0D,0xFF,0xFF,0xFF
maskR: DB 0x02,0xFF,0xFF,0xFF, 0x06,0xFF,0xFF,0xFF, 0x0A,0xFF,0xFF,0xFF, 0x0E,0xFF,0xFF,0xFF 

div10: DD 10.0, 10.0, 10.0, 10.0
; 16b| r3 r2 r1 r0 r3 r2 r1 r0 g3 g2 g1 g0 b3 b2 b1 b0
;       0  1  2  3  4  5  6  7  8  9 A   B  C  D  E  F         
;    | b0 b1 b2 b3 g0 g1 g2 g3 r0 r1 r2 r3 r0 r1 r2 r3
reord: DB 0x0,0x4,0x8,0xFF,    0x1,0x5,0x9,0xFF,    0x2,0x6,0xA,0xFF, 0x3,0x7,0xB,0xFF     
maskA: DB 0x00,0x00,0x00,0xFF, 0x00,0x00,0x00,0xFF, 0x0,0x0,0x0,0xFF, 0x0,0x0,0x0,0xFF

global sepia_asm
section .text

;unsigned char *src,
;    unsigned char *dst,
;    int cols,
;    int filas,
;    int src_row_size,
;    int dst_row_size,
;    int alfa
; rdi = src
; rsi = dst 
; rdx = cols
; rcx = filas
sepia_asm:

	push rbp
	mov rbp, rsp

	mov ecx, ecx			;limpio parte alta rcx
	mov edx, edx			;limpio parte alta rdx
	shr rdx, 2				;divido por 4 porque manejo de a 4 pixels

	movdqu xmm5, [maskB]
	movdqu xmm6, [maskG]
	movdqu xmm7, [maskR]
	
	movups xmm8, [div10]
	
	movdqu xmm9, [reord]
	movdqu xmm10,[maskA]



	.cicloFila:

		mov r8, rcx 		;copio contador rcx en r8
		mov rcx, rdx
		.cicloColumnas:

			movdqu xmm0, [rdi]   ; xmm0 = argb 3| argb 2| argb 1| argb 0
			movdqa xmm2, xmm0    ; xmm1 = argb 3| argb 2| argb 1| argb 0
			movdqa xmm3, xmm0    ; xmm2 = argb 3| argb 2| argb 1| argb 0
			movdqa xmm4, xmm0	 ; xmm3 = argb 3| argb 2| argb 1| argb 0



			pshufb xmm2, xmm5    ; xmm2 = 000b 3| 000b 2| 000b 1| 000b 0
			pshufb xmm3, xmm6    ; xmm3 = 000g 3| 000g 2| 000g 1| 000g 0
			pshufb xmm4, xmm7    ; xmm4 = 000r 3| 000r 2| 000r 1| 000r 0

			paddd  xmm2, xmm3    ;
			paddd  xmm2, xmm4    ; xmm2 = b+g+r 3| b+g+r 2| b+g+r 1| b+g+r 0

			cvtdq2ps xmm2, xmm2  ; xmm2 en floats
			divps  xmm2, xmm8	 ; xmm2 = sum * .1 (divido cada float por 10)

								 ;        sum3  |  sum2 | sum1 | sum0
			movdqa xmm3, xmm2    ; xmm3 = sum * .1
			addps  xmm2, xmm3    ; xmm2 = sum * .2
			addps  xmm3, xmm2    ; xmm3 = sum * .3

			movdqa xmm4, xmm3    ; xmm4 = sum * .3
			addps  xmm4, xmm2    ; xmm4 = sum * .5


			cvtps2dq xmm2, xmm2  ; 4 dw con componentes b3 b2 b1 b0
			cvtps2dq xmm3, xmm3  ; 4 dw con componentes g3 g2 g1 g0
			cvtps2dq xmm4, xmm4  ; 4 dw con componentes r3 r2 r1 r0 

			packusdw xmm2, xmm3  ; 8w | g3 g2 g1 g0 b3 b2 b1 b0
			;movdqa   xmm4, xmm2
			packusdw xmm4, xmm4  ; 8w | r3 r2 r1 r0 r3 r2 r1 r0 
			packuswb xmm2, xmm4  ; 16b| r3 r2 r1 r0 r3 r2 r1 r0 g3 g2 g1 g0 b3 b2 b1 b0
			;packsswb xmm4, xmm4  ; 16b| r3 r2 r1 r0 r3 r2 r1 r0 g3 g2 g1 g0 b3 b2 b1 b0

			pshufb   xmm2, xmm9  ; reordeno componentes
			pand     xmm0, xmm10 ; dejo solo las coordenadas alpha
			por      xmm0, xmm2  ; or de resultado con alphas
			
			movdqu   [rsi], xmm0

			add rsi, 16
			add rdi, 16

		loop .cicloColumnas

		mov rcx, r8			;restauro contador


	dec rcx
	jne .cicloFila


	.fin:

	pop rbp
	ret
