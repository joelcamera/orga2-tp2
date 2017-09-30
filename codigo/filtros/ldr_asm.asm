
global ldr_asm

section .data
;float de precision doble
MAXSUMA: dq 4876875.0

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

%macro saturar 1
	cmp %1, 255
	jg %%mayor
	cmp %1, 0
	jl %%menor
	jmp %%fin
	%%mayor:
	mov %1, 255
	jmp %%fin
	%%menor:
	mov %1, 0
	%%fin:
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

ldr_asm:
    push rbp
    mov rbp, rsp
    push rbx
    push r12
    push r13
    push r14
    push r15

    ;limpiamos las partes altas de los registros edx, ecx, r8d, r9d aunque creo que no es necesario, al ser de 32 bits entran en el caso particular que limpian la parte alta del registro de 64
    xor r10, r10
    mov r10d, edx
    mov rdx, r10
    mov r10d, ecx
    mov rcx, r10
    mov r10d, r8d
    mov r8, r10
    mov r10d, r9d
    mov r9, r10


    mov r10, rdx ;guardo en r10 la cantidad de columnas, vamos a necesitar restablecer rdx en cada iteracion del ciclo de filas
    movsx r14, dword [VAR_ALPHA] ;guardo en r14 el alpha con signo extendido (alpha es entero con signo de 32bits), para no tener que levantarlo de memoria por cada pixel
    movsd xmm0, [MAXSUMA] ;guardo en xmm0 maxsuma

    ;ciclo
    sub rcx, P  ;rcx = filas y le restamos el pad del filtro -1
    dec rcx
    .cicloFilas: ;rcx = i, P<=i<filas-P
    
    mov rdx, r10
    sub rdx, P  ;rdx = cols y le restamos el pad del filtro -1
    dec rdx
    .cicloCols: ;rdx = j, P<=j<cols-P

    xor r15, r15 ;r15 = sumargb

    ;ciclo acumulador
    mov rax, P
    .cicloK: ;-P<=k<=P   

    mov rbx, P
    .cicloL: ;-P<=l<=P

    ;acumular
    mov r12, rcx;r12=i
    add r12, rax;r12=i+K
    mov r13, rdx;r13=j
    add r13, rbx;r13=j+L

    pixelIJ r11, r12, r13, rdi, r8 ;pixel del src
    
    movzx r12d, byte [r11]
    add r15d, r12d
    movzx r12d, byte [r11+1]
    add r15d, r12d
    movzx r12d, byte [r11+2]
    add r15d, r12d
    ;en r15d entra la suma de todos enteros positivos

    ;/acumular

    dec rbx
    cmp rbx, mP
    jge .cicloL

    dec rax
    cmp rax, mP
    jge .cicloK
    ;/ciclo acumulador

    ;registros libres para usar: rax, rbx, r11, r12, r13

    ;procesar pixel
    imul r15, r14 ;multiplico por el alpha, r15 = sumargb*alpha
    pixelIJ r11, rcx, rdx, rdi, r8 ;levanto el pixel src
    pixelIJ rax, rcx, rdx, rsi, r9 ;levanto el pixel dst

    ;canal R
    movzx r13, byte [r11];r13 = p_s->r
    mov r12, r15;r12=sumargb*alpha
    imul r12, r13 ;r12 = sumargb*alpha*p_s->r
    cvtsi2sd xmm1, r12 ;convertimos r12 qword entero signado -> punto flotante de precision doble
    divsd xmm1, xmm0 ;xmm1 = sumargb*alpha*p_s->r/MAXSUMA
    cvtsd2si r12, xmm1;r12 = sumargb*alpha*p_s->r/MAXSUMA
    add r12, r13 ;r12 = p_s->r+(sumargb*alpha*p_s->r/MAXSUMA)
    saturar r12
    mov [rax], r12b
    
    ;canal G
    movzx r13, byte [r11+1];r13 = p_s->g
    mov r12, r15;r12=sumargb*alpha
    imul r12, r13 ;r12 = sumargb*alpha*p_s->g
    cvtsi2sd xmm1, r12 ;convertimos r12 qword entero signado -> punto flotante de precision doble
    divsd xmm1, xmm0 ;xmm1 = sumargb*alpha*p_s->g/MAXSUMA
    cvtsd2si r12, xmm1;r12 = sumargb*alpha*p_s->g/MAXSUMA
    add r12, r13 ;r12 = p_s->g+(sumargb*alpha*p_s->g/MAXSUMA)
    saturar r12
    mov [rax+1], r12b

    ;canal B
    movzx r13, byte [r11+2];r13 = p_s->b
    mov r12, r15;r12=sumargb*alpha
    imul r12, r13 ;r12 = sumargb*alpha*p_s->b
    cvtsi2sd xmm1, r12 ;convertimos r12 qword entero signado -> punto flotante de precision doble
    divsd xmm1, xmm0 ;xmm1 = sumargb*alpha*p_s->b/MAXSUMA
    cvtsd2si r12, xmm1;r12 = sumargb*alpha*p_s->b/MAXSUMA
    add r12, r13 ;r12 = p_s->b+(sumargb*alpha*p_s->b/MAXSUMA)
    saturar r12
    mov [rax+2], r12b
   
    ;/procesar pixel

    dec rdx
    cmp rdx, P
    jge .cicloCols

    dec rcx
    cmp rcx, P
    jge .cicloFilas

    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    pop rbp
    ret
