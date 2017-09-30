global cropflip_asm3

section .text
;void cropflip_asm(unsigned char *src,
;                  unsigned char *dst,
;		           int cols, int filas,
;                  int src_row_size,
;                  int dst_row_size,
;                  int tamx, int tamy,
;                  int offsetx, int offsety);

; rdi = *src
; rsi = *dst
; rdx = cols            
; rcx = filas           
; r8  = src_row_size	
; r9  = dst_row_size	
%define VAR_TAMX    rbp+16
%define VAR_TAMY    rbp+24
%define VAR_OFFSETX rbp+32
%define VAR_OFFSETY rbp+40

cropflip_asm3:
	push rbp		;stack frame
	mov rbp, rsp

	push r12		;preservo registros
	push r13
	push r14
	push r15

	;swap de rsi y rdi para que tengan sentido source dest
	mov rcx, rdi
	mov rdi, rsi
	mov rsi, rcx

	
	;limpio registros para usarlos enteros
	xor r12, r12
	xor r13, r13
	xor r14, r14
	xor r15, r15
	;copio las variables
	mov r12d, [VAR_TAMX]
	mov r13d, [VAR_TAMY]
	mov r14d, [VAR_OFFSETX]
	mov r15d, [VAR_OFFSETY]


	;casos en los que no aplico el filtro
	cmp r12, 0
	je .fin
	cmp r13, 0
	je .fin
	cmp ecx, 0
	je .fin
	cmp edx, 0
	je .fin


	
	mov r11, r12         ; r11 = cantidad de pixels a copiar (tamx)
	shl r11, 2           ; r11 = cantidad de bytes a copiar por fila
	
	imul r15, r8         ; r15 = offsety * src_row_size
	                     ; r15 = byte inicial para copiar

	shl r14, 2           ; multiplico r14 x 4 para tener
	                     ; la cantidad de bytes de offset 
	                     ; al inicio de la fila

	                     ; calculo en rdx el offset necesario
	                     ; para terminar la fila
	mov rdx, r8          ; rdx = bytes columna
	sub rdx, r14         ; rdx = columnas - offsetx
	sub rdx, r11         ; rdx = columnas - offsetx - tamx


	;divido tamx por 2, porque voy a copiar de a 2 pixels 
	;y voy a usarlo para el loop interno
	shr r12, 1	

	;apunto a la primera linea a copiar
	add rsi, r15


	;uso rcx para tamy que es el loop externo por las filas
	mov rcx, r13

	;guardo en r13 la cantidad de bytes totales a copiar
	imul r13, r11
	
	;apunto a la ultima fila a copiar
	add rdi, r13
	sub rdi, r11

	;en r11 dejo el size de 2 filas, que es lo que voy a volver
	;para atras cada vez que termine de copiar una fila
	add r11, r11 

	.ciclo:

		;copio el contador de fila a r9 en vez de pushear
		mov r9, rcx

		;salteo el offsetx de la fila
		add rsi, r14

		;cantidad de 8bytes a copiar
		mov rcx, r12

		;VERSION SIMD
		shr rcx, 1  	       ;esta version copia de a 16 asi que divido loop x 2
		.copiarColumna2:
		   	movdqu xmm0, [rsi]
		   	movdqu [rdi], xmm0
			add rsi, 16
			add rdi, 16
		loop .copiarColumna2


		;muevo 2 filas para atras
		sub rdi, r11

		;salteo el offset final de la fila
		add rsi, rdx

		;restauro contador loop externo
		mov rcx, r9


	loop .ciclo



	.fin:

	pop r15			;restore registros
	pop r14
	pop r13
	pop r12
	pop rbp			;restore stack frame
    ret
