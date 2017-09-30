GLOBAL cropflip_asm

section .text
;void cropflip_asm( unsigned char *src, 
;					unsigned char *dst, 
;					int cols, 
;					int filas, 
;					int src_row_size, 
;					int dst_row_size, 
;					int tamx,
;					int tamy,
;					int offsetx,
;					int offsety);
;rdi(src) 
;rsi(dst) 
;edx(cols) 
;ecx(filas)
;r8d(src_row_size)
;r9d(dst_row_size)
%define TAMX rbp+16
%define TAMY rbp+24
%define OFFSETX rbp+32
%define OFFSETY rbp+40

cropflip_asm:

push rbp
mov rbp, rsp
push rbx				;tamx
push r12				;tamy
push r13				;offsetx
push r14				;offsety


;paso las variables que tengo en la pila a los registros pusheados
;los limpio primero
xor rbx, rbx
xor r12, r12
xor r13, r13
xor r14, r14
mov ebx, [TAMX]
mov r12d, [TAMY]
mov r13d, [OFFSETX]
mov r14d, [OFFSETY]

;casos en que no hace nada el programa:
;si recorto cero filas o cero columnas sale
cmp rbx, 0				;tamx = 0
jle .fin
cmp r12, 0				;tamy = 0
jle .fin
;si lo que tengo que recortar esta fuera de rango termina tambien
;uso rax para hacer las cuentas
xor rax, rax
cmp r13, 0				;offsetx < 0
jle .fin
cmp r14, 0				;offsety < 0
jle .fin
mov rax, r13			;rax = offsetx
add rax, rbx			;rax = offsetx + tamx
cmp eax, edx			;eax = offsetx + tamx > edx = #col
jg .fin
mov rax, r14			;rax = offsety
add rax, r12			;rax = offsety + tamy
cmp eax, ecx			;eax = offsety + tamy > edx = #filas
jg .fin


;en r10 guardo el valor que tengo que contar para .cicloCol
;en r11 para el .cicloFila
mov r10, rbx			;r10 = tamx
shr r10, 2				;r10 = tamx / 4

mov r11, r12			;r11 = tamy
						;r11 = tamy


;muevo los punteros
mov rax, rbx			;rax = tamx
shl rax, 2				;rax = tamx*4

imul r14d, r8d			;r14 = offsety * src_row_size
						;r14 = byte inicial para copiar

shl r13, 2				;r13 = offsetx * 4

;piso rdx que estaban las columnas de la matrix, no lo voy a usar al dato
xor rdx, rdx
mov edx, r8d			;rdx = src_raw_size
sub rdx, r13			;rdx = src_raw_size - (offsetx * 4)
sub rdx, rax			;rdx = src_raw_size - (offsetx * 4) - (tamx * 4)
						;rdx = cant de elementos que tiene la submatriz por fila

shr rbx, 2				;rbx = tamx / 4 (levanto de a 4 pixeles)

add rdi, r14			;me posiciono en el primer elemento a copiar

imul r12, rax			;r12 = tamx * tamy * 4
						;cantidad de bytes a copiar

add rsi, r12			;me posiciono en la ultima fila a copiar
sub rsi, rax

add rax, rax			;rax = tamx * 4 * 2 (dos filas)


.cicloFila:

	;actualizo el contador de .cicloCol
	mov r12, r10

	.cicloCol:
	movdqu xmm1, [rdi]
	movdqu [rsi], xmm1
	;actualizo punteros
	add rdi, 16
	add rsi, 16
	dec r12
	cmp r12, 0
	jne .cicloCol

;me muevo dos filas para atras
sub rsi, rax

;salteo el offset final de la fila
add rdi, rdx

dec r11
cmp r11, 0
jne .cicloFila



.fin:
pop r14
pop r13
pop r12
pop rbx
pop rbp
ret