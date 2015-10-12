global equalizer


section .data
align 16	;Alineo
cuatros: dd 4.0, 4.0, 4.0, 4.0
medios: dd 0.5, 0.5, 0.5, 0.5
sumadorCounter: dd 0.0, 1.0, 2.0, 3.0
medioMedios: dd 0.25, 0.25, 0.25, 0.25
menosUnos: dd -1.0, -1.0, -1.0, -1.0
unos: dd 1.0, 1.0, 1.0, 1.0
dos: dd 2.0, 2.0, 2.0, 2.0
puntoDos: dd 0.2, 0.2, 0.2, 0.2
ceros: dd 0.0, 0.0, 0.0, 0.0

unDos: dd 2.0



section .text

; byte = 8b = char
; word = 2B = short
; dw = 4B = int = float
; qw = 8B = r = double
; dqw = 16B = xmm


  ; float lpf_a0 = 1 + alpha;
  ; float lpf_a1 = - 2 * cosw0 / lpf_a0;
  ; float lpf_a2 = (1 - alpha) / lpf_a0;
  ; float lpf_b1 = (1 - cosw0) / lpf_a0;
  ; float lpf_b0 = lpf_b1 / 2;

;equ_asm(buffer, prev, primersuma0, primersuma1, primersuma2, primersuma3,
;		segundasuma0, segundasuma1, segundasuma2, segundasuma3, factorSuma2);

;void equ_asm
	;float* buffer 			rdi
	;float* prev 			rsi
	;int sample_count		edx
  	;equ_asm(buffer, prev, sample_count, lpf_b0, lpf_b1 (este en realidad no lo paso), - lpf_a2, - lpf_a1, peak_b2, peak_b1, -peak_a2, -peak_a1, peak_b0);

	;float primersuma0		xmm0 - tambien factorsuma1
	;float primersuma1 		xmm1
	;float primersuma2		xmm2
	;float primersuma3		xmm3
	;float segundasuma0		xmm4
	;float segundasuma1		xmm5
	;float segundasuma2		xmm6
	;float segundasuma3		xmm7
	;float factorSuma2		xmm8

	;xmm11 = 0 | 0 |*(prev_vals+1) | *(prev_vals)
	;xmm12 = 0 | 0 |*(prev_vals+3) | *(prev_vals+2)
	;xmm13 = 0 | 0 |*(prev_vals+5) | *(prev_vals+4)


;------------------------------------------------------------------------------------------
;---------------------------------- VERSIONES UN ACCESO UN DATO  --------------------------
;------------------------------------------------------------------------------------------

;versión con sumas horizontales -  (la mas eficiente de todas)
equalizer:
	push rbp
	mov rbp, rsp
	push rbx		;rbx es i
	push r12		;r12 es aux
	push r13		;r13d es temp
	push r14		;r14d es la posicion del buffer


	;---------- seteo constantes------------

	;------ limpio bits superiores ---
	pxor xmm10, xmm10	; xmm10 es 0
	mov r12d, 0xFFFFFFFF
	movd xmm10, r12d		; xmm10 tiene un dw de unos, el resto 0

	;desplazo todos un xmm a la derecha - pequeño parche porque estaba mal la calling convention
	movdqu xmm8, xmm7
	movdqu xmm7, xmm6
	movdqu xmm6, xmm5
	movdqu xmm5, xmm4
	movdqu xmm4, xmm3
	movdqu xmm3, xmm2
	movdqu xmm2, xmm1
	
	movdqu xmm1, xmm0		;en xmm0 tendré lo mismo que en el 1
	mulss xmm1, [rel unDos]	;lo multiplico por dos, porque float psuma1 = psuma0 *2;

	; pand xmm0, xmm10	; filtro todo lo que no sea el primer float - todo sacar, no hace falta
	; pand xmm1, xmm10	; filtro todo lo que no sea el primer float
	; pand xmm2, xmm10	; filtro todo lo que no sea el primer float
	; pand xmm3, xmm10	; filtro todo lo que no sea el primer float
	; pand xmm4, xmm10	; filtro todo lo que no sea el primer float
	; pand xmm5, xmm10	; filtro todo lo que no sea el primer float
	; pand xmm6, xmm10	; filtro todo lo que no sea el primer float
	; pand xmm7, xmm10	; filtro todo lo que no sea el primer float
	; pand xmm8, xmm10	; filtro todo lo que no sea el primer float
	;----------------.
	;-----------------


	movdqu xmm9, xmm0		;xmm9 = factorsuma1

	;primersuma
						;xmm0	= 0 | 0 | 0 | primersuma0
	pslldq xmm1, 4		;xmm1	= 0 | 0 | primersuma1 | 0
	pslldq xmm2, 8		;xmm2	= 0 | primersuma2 | 0 | 0
	pslldq xmm3, 12		;xmm3	= primersuma3 | 0 | 0 | 0

	orps xmm0, xmm1
	orps xmm2, xmm3
	orps xmm0, xmm2		;xmm0 = primersuma3 | primersuma2 | primersuma1 | primersuma0
	;acá tengo las constantes de la primer suma en horizontal


	;segundasuma
						;xmm4	= 0 | 0 | 0 | segundasuma0
	pslldq xmm5, 4		;xmm5	= 0 | 0 | segundasuma1 | 0
	pslldq xmm6, 8		;xmm6	= 0 | segundasuma2 | 0 | 0
	pslldq xmm7, 12		;xmm7	= segundasuma3 | 0 | 0 | 0

	orps xmm4, xmm5
	orps xmm6, xmm7
	orps xmm4, xmm6		;xmm4 = segundasuma3 | segundasuma2 | segundasuma1 | segundasuma0

	;acá tengo las constantes de la segunda suma en horizontal
	
	movdqu xmm1, xmm9
	movdqu xmm3, xmm8
	movdqu xmm2, xmm4

	
	movdqu xmm7, xmm10	;xmm7 tiene un dw de unos
	movdqu xmm15, xmm10 ;xmm15 = 0 | 0 | 0 | unos
	pslldq xmm15, 4		;xmm15 = 0 | 0 | unos | 0
	por xmm10, xmm15	;xmm10 tiene un qw de unos

	;ctes:
	; xmm0: primersuma
	; xmm1: factorsuma1
	; xmm2: segundasuma
	; xmm3: factorsuma2	
	; xmm10: un qw de unos
	; xmm7: un dw de unos

	;------- fin constantes ------------------ 

	;------- levanto prev_vals
	movdqu xmm11, [rsi] ; xmm11 = *(prev_vals+3) |*(prev_vals+2) |*(prev_vals+1) | *(prev_vals)
	movdqu xmm12, xmm11	; xmm12 = *(prev_vals+3) |*(prev_vals+2) |*(prev_vals+1) | *(prev_vals)
	psrldq xmm12, 8		; xmm12 = 0 | 0 | *(prev_vals+3) | *(prev_vals+2)

	pand xmm11, xmm10 	; xmm11 = 0 | 0 |*(prev_vals+1) | *(prev_vals)



	movq xmm13, [rsi + 16]	;xmm13 = basura | basura | *(prev_vals+5) |*(prev_vals+4)
	pand xmm13, xmm10	; xmm13 = 0 | 0 | *(prev_vals+5) |*(prev_vals+4)


	;------- arranca el ciclo grande ----------------
	xor rbx, rbx		; i empieza en 0
	.cicloGrande:
	cmp edx, ebx		;si i es sample_count, termino
	jae .finGrande

	mov r14, rbx
	sal r14, 2		;multiplico por 4
	add r14, rdi	;r14d es la posicion a escribir del buffer

	movd xmm4, [r14]		;copio una entrada a xmm4

	;---------- low-pass filter-------------------

	;------float temp = p(m_output)[i];
	movd r13d, xmm4

	;------p(m_output)[i] *= lpf_b0;
	mulss xmm4, xmm1

	;------p(m_output)[i] +=  lpf_b0 * *(prev_vals) + lpf_b1 * *(prev_vals+1) - lpf_a2 * *(prev_vals+2) - lpf_a1 * *(prev_vals+3);
	;movdqu xmm5, [esi]	;xmm5 = *(prev_vals+3) |*(prev_vals+2) |*(prev_vals+1) | *(prev_vals)
	movdqu xmm5, xmm12	;xmm5 = 0 | 0 | *(prev_vals+3) |*(prev_vals+2)
	pslldq xmm5, 8		;xmm5 =  *(prev_vals+3) |*(prev_vals+2) | 0 | 0
	por xmm5, xmm11		;xmm5 = *(prev_vals+3) |*(prev_vals+2) |*(prev_vals+1) | *(prev_vals)

	mulps xmm5, xmm0	;xmm5 = *(pv+3)*ps3	   |*(pv+2)*ps2	   |*(pv+1)*ps1	   |*(pv)*ps0

	; haddps xmm5, xmm5	;xmm5 = basura      | basura      |psuma3+psuma2|psuma1+psuma0
	; haddps xmm5, xmm5	;xmm5 = basura      | basura      | basura		|ps3+ps2+ps1+ps0

	addss xmm4, xmm5		;xmm4 = xmm4 * lpf_b0 + lpf_b0 * *(prev_vals) + lpf_b1 * *(prev_vals+1) - lpf_a2 * *(prev_vals+2) - lpf_a1 * *(prev_vals+3)

	;-------------fin operaciones sobre el output

	;----- vieja forma
	;------*prev_vals = *(prev_vals+1);
	; mov r12d, [esi+4]		;r12d = *(prev_vals + 1)
	; mov [esi], r12d		;*prev_vals = r12d

	; xmm11 = 0 | 0 |*(prev_vals+1) | *(prev_vals)
	;------*(prev_vals+1) = temp;
	; mov [esi+4], r13d		;*(prev_vals + 1) = r13d
	;----- vieja forma

	;----- todo de una
	pxor xmm15, xmm15		;xmm15 = 0
	movd xmm15, r13d		;xmm15 = 0 | 0 | 0 | r13d
	pslldq xmm15, 8			;xmm15 = 0 | r13d | 0 | 0
	por xmm11, xmm15		;xmm11 = 0 | r13d | *(prev_vals+1) | *(prev_vals) 
	psrldq xmm11, 4			;xmm11 = 0 | 0 | r13d | *(prev_vals+1)


	;----------------- peaking EQ (resonance) ----------------
	;-------float temp2 = p(m_output)[i];
	movd r13d, xmm4

    ;-------p(m_output)[i] *= peak_b0;
    mulss xmm4, xmm3	;xmm4 = xmm4 * factorsuma2

    ;-------p(m_output)[i] += peak_b2 * *(prev_vals+2) + peak_b1 * *(prev_vals+3) - peak_a2 * *(prev_vals+4) - peak_a1 * *(prev_vals+5);
    ;movdqu xmm5, [esi+8]	;xmm5 = *(prev_vals+5) |*(prev_vals+4) |*(prev_vals+3) | *(prev_vals2)
    movdqu xmm5, xmm13		;xmm5 = 0 | 0 | *(prev_vals+5) |*(prev_vals+4)
    pslldq xmm5, 8			;xmm5 = *(prev_vals+5) |*(prev_vals+4) | 0 | 0
    por xmm5, xmm12			;xmm5 = *(prev_vals+5) |*(prev_vals+4) |*(prev_vals+3) | *(prev_vals2)

    mulps xmm5, xmm2		;xmm5 = *(pv+5)*ss3	   |*(pv+4)*ss2	   |*(pv+3)*ss1	   |*(pv+2)*ss0

	; haddps xmm5, xmm5	;xmm5 = basura      | basura      |ssuma3+ssuma2|ssuma1+ssuma0
	; haddps xmm5, xmm5	;xmm5 = basura      | basura      | basura		|ss3+ss2+ss1+ss0

	addss xmm4, xmm5		;xmm4 = xmm4 * peak_b0 + peak_b2 * *(prev_vals+2) + peak_b1 * *(prev_vals+3) - peak_a2 * *(prev_vals+4) - peak_a1 * *(prev_vals+5);

	;------------------ fin operaciones sobre el output

	;----- vieja forma
    ;-------*(prev_vals+2) = *(prev_vals+3);
    ; mov r12d, [esi+12]		;r12d = *(prev_vals+3)
    ; mov [esi+8], r12d		;*(prev_vals+2) = r12d

    ;-------*(prev_vals+3) = temp2;
	; mov [esi+12], r13d		;*(prev_vals+3) = r13d
	;----- vieja forma

	;-------todo de una
	pxor xmm15, xmm15		;xmm15 = 0
	movd xmm15, r13d		;xmm15 = 0 | 0 | 0 | r13d
	pslldq xmm15, 8			;xmm15 = 0 | r13d | 0 | 0
	por xmm12, xmm15		;xmm12 = 0 | r13d | *(prev_vals+3) | *(prev_vals+2)
	psrldq xmm12, 4			;xmm12 = 0 | 0 | r13d | *(prev_vals+3)


	;-------vieja forma
    ;-------*(prev_vals+4) = *(prev_vals+5);
    ; mov r12d, [esi+20]		;r12d = *(prev_vals+5)
    ; mov [esi+16], r12d		;*(prev_vals+4) = r12d

    ;-------*(prev_vals+5) = p(m_output)[i];
    ; movd [esi+20], xmm4
    ;-------vieja forma

    ;-------todo de una
    pxor xmm15, xmm15		;xmm15 = 0
    movd r12d, xmm4
    movd xmm15, r12d		;xmm15 = 0 | 0 | 0 | output
    pslldq xmm15, 8			;xmm15 = 0 | output | 0 | 0
    por xmm13, xmm15		;xmm13 = 0 | output | *(prev_vals+5) | *(prev_vals+4)
    psrldq xmm13, 4			;xmm13 = 0 | 0 | output| *(prev_vals+5) 


    movdqu xmm15, xmm4		;meto xmm4 en el dw mas alto de xmm15
    pslldq xmm15, 12		;xmm15 = res | 0 | 0 | 0
    orps xmm8, xmm15

    psrldq xmm9, 4			;shifteo 1 dw a la derecha, para usar el siguiente dato. la segunda entrada pasa a ser la primera
    movdqu xmm4, xmm9		;copio toda la entrada a xmm4
	pand xmm4, xmm7		;limpio la parte superior. solo queda la primer entrada



    ;----- copio xmm4 a la direccion del buffer
    movd [r14], xmm4


	;---incrementaciones
	inc ebx					;incremento el contador i, en 1
	jmp .cicloGrande
	.finGrande:

	;-----guardo el prev_vals modificado
	pslldq xmm12, 8
	por xmm12, xmm11
	movdqu [rsi], xmm12
	movq [rsi+16], xmm13
	;---

	pop r14
	pop r13
	pop r12
	pop rbx
	pop rbp
ret

;versión con sumas verticales
equalizerb:
	push rbp
	mov rbp, rsp
	push rbx		;rbx es i
	push r12		;r12 es aux
	push r13		;r13d es temp
	push r14		;r14d es la posicion del buffer


	;---------- seteo constantes------------

	;------ limpio bits superiores ---
	pxor xmm10, xmm10	; xmm10 es 0
	mov r12d, 0xFFFFFFFF
	movd xmm10, r12d		; xmm10 tiene un dw de unos, el resto 0

	;desplazo todos un xmm a la derecha - pequeño parche porque estaba mal la calling convention
	movdqu xmm8, xmm7
	movdqu xmm7, xmm6
	movdqu xmm6, xmm5
	movdqu xmm5, xmm4
	movdqu xmm4, xmm3
	movdqu xmm3, xmm2
	movdqu xmm2, xmm1
	
	movdqu xmm1, xmm0		;en xmm0 tendré lo mismo que en el 1
	mulss xmm1, [rel unDos]	;lo multiplico por dos, porque float psuma1 = psuma0 *2;

	; pand xmm0, xmm10	; filtro todo lo que no sea el primer float - todo sacar, no hace falta
	; pand xmm1, xmm10	; filtro todo lo que no sea el primer float
	; pand xmm2, xmm10	; filtro todo lo que no sea el primer float
	; pand xmm3, xmm10	; filtro todo lo que no sea el primer float
	; pand xmm4, xmm10	; filtro todo lo que no sea el primer float
	; pand xmm5, xmm10	; filtro todo lo que no sea el primer float
	; pand xmm6, xmm10	; filtro todo lo que no sea el primer float
	; pand xmm7, xmm10	; filtro todo lo que no sea el primer float
	; pand xmm8, xmm10	; filtro todo lo que no sea el primer float
	;----------------.
	;-----------------


	movdqu xmm9, xmm0		;xmm9 = factorsuma1

	;primersuma
						;xmm0	= 0 | 0 | 0 | primersuma0
	pslldq xmm1, 4		;xmm1	= 0 | 0 | primersuma1 | 0
	pslldq xmm2, 8		;xmm2	= 0 | primersuma2 | 0 | 0
	pslldq xmm3, 12		;xmm3	= primersuma3 | 0 | 0 | 0

	orps xmm0, xmm1
	orps xmm2, xmm3
	orps xmm0, xmm2		;xmm0 = primersuma3 | primersuma2 | primersuma1 | primersuma0
	;acá tengo las constantes de la primer suma en horizontal


	;segundasuma
						;xmm4	= 0 | 0 | 0 | segundasuma0
	pslldq xmm5, 4		;xmm5	= 0 | 0 | segundasuma1 | 0
	pslldq xmm6, 8		;xmm6	= 0 | segundasuma2 | 0 | 0
	pslldq xmm7, 12		;xmm7	= segundasuma3 | 0 | 0 | 0

	orps xmm4, xmm5
	orps xmm6, xmm7
	orps xmm4, xmm6		;xmm4 = segundasuma3 | segundasuma2 | segundasuma1 | segundasuma0

	;acá tengo las constantes de la segunda suma en horizontal
	
	movdqu xmm1, xmm9
	movdqu xmm3, xmm8
	movdqu xmm2, xmm4

	
	movdqu xmm7, xmm10	;xmm7 tiene un dw de unos
	movdqu xmm15, xmm10 ;xmm15 = 0 | 0 | 0 | unos
	pslldq xmm15, 4		;xmm15 = 0 | 0 | unos | 0
	por xmm10, xmm15	;xmm10 tiene un qw de unos

	;ctes:
	; xmm0: primersuma
	; xmm1: factorsuma1
	; xmm2: segundasuma
	; xmm3: factorsuma2	
	; xmm10: un qw de unos
	; xmm7: un dw de unos

	;------- fin constantes ------------------ 

	;------- levanto prev_vals
	movdqu xmm11, [rsi] ; xmm11 = *(prev_vals+3) |*(prev_vals+2) |*(prev_vals+1) | *(prev_vals)
	movdqu xmm12, xmm11	; xmm12 = *(prev_vals+3) |*(prev_vals+2) |*(prev_vals+1) | *(prev_vals)
	psrldq xmm12, 8		; xmm12 = 0 | 0 | *(prev_vals+3) | *(prev_vals+2)

	pand xmm11, xmm10 	; xmm11 = 0 | 0 |*(prev_vals+1) | *(prev_vals)



	movq xmm13, [rsi + 16]	;xmm13 = basura | basura | *(prev_vals+5) |*(prev_vals+4)
	pand xmm13, xmm10	; xmm13 = 0 | 0 | *(prev_vals+5) |*(prev_vals+4)


	;------- arranca el ciclo grande ----------------
	xor rbx, rbx		; i empieza en 0
	.cicloGrande:
	cmp edx, ebx		;si i es sample_count, termino
	jae .finGrande

	mov r14, rbx
	sal r14, 2		;multiplico por 4
	add r14, rdi	;r14d es la posicion a escribir del buffer

	movd xmm4, [r14]		;copio una entrada a xmm4

	;---------- low-pass filter-------------------

	;------float temp = p(m_output)[i];
	movd r13d, xmm4

	;------p(m_output)[i] *= lpf_b0;
	mulss xmm4, xmm1

	;------p(m_output)[i] +=  lpf_b0 * *(prev_vals) + lpf_b1 * *(prev_vals+1) - lpf_a2 * *(prev_vals+2) - lpf_a1 * *(prev_vals+3);
	;movdqu xmm5, [esi]	;xmm5 = *(prev_vals+3) |*(prev_vals+2) |*(prev_vals+1) | *(prev_vals)
	movdqu xmm5, xmm12	;xmm5 = 0 | 0 | *(prev_vals+3) |*(prev_vals+2)
	pslldq xmm5, 8		;xmm5 =  *(prev_vals+3) |*(prev_vals+2) | 0 | 0
	por xmm5, xmm11		;xmm5 = *(prev_vals+3) |*(prev_vals+2) |*(prev_vals+1) | *(prev_vals)

	mulps xmm5, xmm0	;xmm5 = *(pv+3)*ps3	   |*(pv+2)*ps2	   |*(pv+1)*ps1	   |*(pv)*ps0

	;---suma vertical
	movdqu xmm15, xmm5	;xmm15 = a | b | c | d
	psrldq xmm15, 8		;xmm15 = 0 | 0 | a | b
	addps xmm5, xmm15	;xmm5  = a | b | a+c | b+d
	movdqu xmm15, xmm5	;xmm15 = a | b | a+c | b+d
	psrldq xmm15, 4		;xmm15 = 0 | a | b   | a+c
	addps xmm5, xmm15	;xmm5 = basura | basura | basura |a+c+b+d

	; haddps xmm5, xmm5	;xmm5 = basura      | basura      |psuma3+psuma2|psuma1+psuma0
	; haddps xmm5, xmm5	;xmm5 = basura      | basura      | basura		|ps3+ps2+ps1+ps0

	addss xmm4, xmm5		;xmm4 = xmm4 * lpf_b0 + lpf_b0 * *(prev_vals) + lpf_b1 * *(prev_vals+1) - lpf_a2 * *(prev_vals+2) - lpf_a1 * *(prev_vals+3)

	;-------------fin operaciones sobre el output

	;----- vieja forma
	;------*prev_vals = *(prev_vals+1);
	; mov r12d, [esi+4]		;r12d = *(prev_vals + 1)
	; mov [esi], r12d		;*prev_vals = r12d

	; xmm11 = 0 | 0 |*(prev_vals+1) | *(prev_vals)
	;------*(prev_vals+1) = temp;
	; mov [esi+4], r13d		;*(prev_vals + 1) = r13d
	;----- vieja forma

	;----- todo de una
	pxor xmm15, xmm15		;xmm15 = 0
	movd xmm15, r13d		;xmm15 = 0 | 0 | 0 | r13d
	pslldq xmm15, 8			;xmm15 = 0 | r13d | 0 | 0
	por xmm11, xmm15		;xmm11 = 0 | r13d | *(prev_vals+1) | *(prev_vals) 
	psrldq xmm11, 4			;xmm11 = 0 | 0 | r13d | *(prev_vals+1)


	;----------------- peaking EQ (resonance) ----------------
	;-------float temp2 = p(m_output)[i];
	movd r13d, xmm4

    ;-------p(m_output)[i] *= peak_b0;
    mulss xmm4, xmm3	;xmm4 = xmm4 * factorsuma2

    ;-------p(m_output)[i] += peak_b2 * *(prev_vals+2) + peak_b1 * *(prev_vals+3) - peak_a2 * *(prev_vals+4) - peak_a1 * *(prev_vals+5);
    ;movdqu xmm5, [esi+8]	;xmm5 = *(prev_vals+5) |*(prev_vals+4) |*(prev_vals+3) | *(prev_vals2)
    movdqu xmm5, xmm13		;xmm5 = 0 | 0 | *(prev_vals+5) |*(prev_vals+4)
    pslldq xmm5, 8			;xmm5 = *(prev_vals+5) |*(prev_vals+4) | 0 | 0
    por xmm5, xmm12			;xmm5 = *(prev_vals+5) |*(prev_vals+4) |*(prev_vals+3) | *(prev_vals2)

    mulps xmm5, xmm2		;xmm5 = *(pv+5)*ss3	   |*(pv+4)*ss2	   |*(pv+3)*ss1	   |*(pv+2)*ss0

    ; ---suma vertical
	movdqu xmm15, xmm5	;xmm15 = a | b | c | d
	psrldq xmm15, 8		;xmm15 = 0 | 0 | a | b
	addps xmm5, xmm15	;xmm5  = a | b | a+c | b+d
	movdqu xmm15, xmm5	;xmm15 = a | b | a+c | b+d
	psrldq xmm15, 4		;xmm15 = 0 | a | b   | a+c
	addps xmm5, xmm15	;xmm5 = basura | basura | basura |a+c+b+d


	; haddps xmm5, xmm5	;xmm5 = basura      | basura      |ssuma3+ssuma2|ssuma1+ssuma0
	; haddps xmm5, xmm5	;xmm5 = basura      | basura      | basura		|ss3+ss2+ss1+ss0

	addss xmm4, xmm5		;xmm4 = xmm4 * peak_b0 + peak_b2 * *(prev_vals+2) + peak_b1 * *(prev_vals+3) - peak_a2 * *(prev_vals+4) - peak_a1 * *(prev_vals+5);

	;------------------ fin operaciones sobre el output

	;----- vieja forma
    ;-------*(prev_vals+2) = *(prev_vals+3);
    ; mov r12d, [esi+12]		;r12d = *(prev_vals+3)
    ; mov [esi+8], r12d		;*(prev_vals+2) = r12d

    ;-------*(prev_vals+3) = temp2;
	; mov [esi+12], r13d		;*(prev_vals+3) = r13d
	;----- vieja forma

	;-------todo de una
	pxor xmm15, xmm15		;xmm15 = 0
	movd xmm15, r13d		;xmm15 = 0 | 0 | 0 | r13d
	pslldq xmm15, 8			;xmm15 = 0 | r13d | 0 | 0
	por xmm12, xmm15		;xmm12 = 0 | r13d | *(prev_vals+3) | *(prev_vals+2)
	psrldq xmm12, 4			;xmm12 = 0 | 0 | r13d | *(prev_vals+3)


	;-------vieja forma
    ;-------*(prev_vals+4) = *(prev_vals+5);
    ; mov r12d, [esi+20]		;r12d = *(prev_vals+5)
    ; mov [esi+16], r12d		;*(prev_vals+4) = r12d

    ;-------*(prev_vals+5) = p(m_output)[i];
    ; movd [esi+20], xmm4
    ;-------vieja forma

    ;-------todo de una
    pxor xmm15, xmm15		;xmm15 = 0
    movd r12d, xmm4
    movd xmm15, r12d		;xmm15 = 0 | 0 | 0 | output
    pslldq xmm15, 8			;xmm15 = 0 | output | 0 | 0
    por xmm13, xmm15		;xmm13 = 0 | output | *(prev_vals+5) | *(prev_vals+4)
    psrldq xmm13, 4			;xmm13 = 0 | 0 | output| *(prev_vals+5) 


    movdqu xmm15, xmm4		;meto xmm4 en el dw mas alto de xmm15
    pslldq xmm15, 12		;xmm15 = res | 0 | 0 | 0
    orps xmm8, xmm15

    psrldq xmm9, 4			;shifteo 1 dw a la derecha, para usar el siguiente dato. la segunda entrada pasa a ser la primera
    movdqu xmm4, xmm9		;copio toda la entrada a xmm4
	pand xmm4, xmm7		;limpio la parte superior. solo queda la primer entrada



    ;----- copio xmm4 a la direccion del buffer
    movd [r14], xmm4


	;---incrementaciones
	inc ebx					;incremento el contador i, en 1
	jmp .cicloGrande
	.finGrande:

	;-----guardo el prev_vals modificado
	pslldq xmm12, 8
	por xmm12, xmm11
	movdqu [rsi], xmm12
	movq [rsi+16], xmm13
	;---

	pop r14
	pop r13
	pop r12
	pop rbx
	pop rbp
ret

;------------------------------------------------------------------------------------------
;----------------------------- VERSIONES UN ACCESO CUATRO DATOS, LOOPEADAS ----------------
;------------------------------------------------------------------------------------------


;versión con sumas horizontales 
equalizerc:
	push rbp
	mov rbp, rsp
	push rbx		;rbx es i
	push r12		;r12 es aux
	push r13		;r13d es temp
	push r14		;r14d es la posicion del buffer


	;---------- seteo constantes------------

	;------ limpio bits superiores ---
	pxor xmm10, xmm10	; xmm10 es 0
	mov r12d, 0xFFFFFFFF
	movd xmm10, r12d		; xmm10 tiene un dw de unos, el resto 0

	;desplazo todos un xmm a la derecha - pequeño parche porque estaba mal la calling convention
	movdqu xmm8, xmm7
	movdqu xmm7, xmm6
	movdqu xmm6, xmm5
	movdqu xmm5, xmm4
	movdqu xmm4, xmm3
	movdqu xmm3, xmm2
	movdqu xmm2, xmm1
	
	movdqu xmm1, xmm0		;en xmm0 tendré lo mismo que en el 1
	mulss xmm1, [rel unDos]	;lo multiplico por dos, porque float psuma1 = psuma0 *2;

	; pand xmm0, xmm10	; filtro todo lo que no sea el primer float - todo sacar, no hace falta
	; pand xmm1, xmm10	; filtro todo lo que no sea el primer float
	; pand xmm2, xmm10	; filtro todo lo que no sea el primer float
	; pand xmm3, xmm10	; filtro todo lo que no sea el primer float
	; pand xmm4, xmm10	; filtro todo lo que no sea el primer float
	; pand xmm5, xmm10	; filtro todo lo que no sea el primer float
	; pand xmm6, xmm10	; filtro todo lo que no sea el primer float
	; pand xmm7, xmm10	; filtro todo lo que no sea el primer float
	; pand xmm8, xmm10	; filtro todo lo que no sea el primer float
	;----------------.
	;-----------------


	movdqu xmm9, xmm0		;xmm9 = factorsuma1

	;primersuma
						;xmm0	= 0 | 0 | 0 | primersuma0
	pslldq xmm1, 4		;xmm1	= 0 | 0 | primersuma1 | 0
	pslldq xmm2, 8		;xmm2	= 0 | primersuma2 | 0 | 0
	pslldq xmm3, 12		;xmm3	= primersuma3 | 0 | 0 | 0

	orps xmm0, xmm1
	orps xmm2, xmm3
	orps xmm0, xmm2		;xmm0 = primersuma3 | primersuma2 | primersuma1 | primersuma0
	;acá tengo las constantes de la primer suma en horizontal


	;segundasuma
						;xmm4	= 0 | 0 | 0 | segundasuma0
	pslldq xmm5, 4		;xmm5	= 0 | 0 | segundasuma1 | 0
	pslldq xmm6, 8		;xmm6	= 0 | segundasuma2 | 0 | 0
	pslldq xmm7, 12		;xmm7	= segundasuma3 | 0 | 0 | 0

	orps xmm4, xmm5
	orps xmm6, xmm7
	orps xmm4, xmm6		;xmm4 = segundasuma3 | segundasuma2 | segundasuma1 | segundasuma0

	;acá tengo las constantes de la segunda suma en horizontal
	
	movdqu xmm1, xmm9
	movdqu xmm3, xmm8
	movdqu xmm2, xmm4

	
	movdqu xmm7, xmm10	;xmm7 tiene un dw de unos
	movdqu xmm15, xmm10 ;xmm15 = 0 | 0 | 0 | unos
	pslldq xmm15, 4		;xmm15 = 0 | 0 | unos | 0
	por xmm10, xmm15	;xmm10 tiene un qw de unos

	;ctes:
	; xmm0: primersuma
	; xmm1: factorsuma1
	; xmm2: segundasuma
	; xmm3: factorsuma2	
	; xmm10: un qw de unos
	; xmm7: un dw de unos

	;------- fin constantes ------------------ 

	;------- levanto prev_vals
	movdqu xmm11, [rsi] ; xmm11 = *(prev_vals+3) |*(prev_vals+2) |*(prev_vals+1) | *(prev_vals)
	movdqu xmm12, xmm11	; xmm12 = *(prev_vals+3) |*(prev_vals+2) |*(prev_vals+1) | *(prev_vals)
	psrldq xmm12, 8		; xmm12 = 0 | 0 | *(prev_vals+3) | *(prev_vals+2)

	pand xmm11, xmm10 	; xmm11 = 0 | 0 |*(prev_vals+1) | *(prev_vals)



	movq xmm13, [rsi + 16]	;xmm13 = basura | basura | *(prev_vals+5) |*(prev_vals+4)
	pand xmm13, xmm10	; xmm13 = 0 | 0 | *(prev_vals+5) |*(prev_vals+4)


	;------- arranca el ciclo grande ----------------
	xor rbx, rbx		; i empieza en 0
	.cicloGrande:
	cmp edx, ebx		;si i es sample_count, termino
	jae .finGrande

	mov r14, rbx
	sal r14, 2		;multiplico por 4
	;imul r14d, 4
	add r14, rdi	;r14d es la posicion a escribir del buffer	 - TODO - mejorar con un lea
	; lea r14d, [rbx*4 + rdi]		- con el lea termino dando peor - creo que es porque hago un acceso ahi abajo, y ambos usan el bus de direcciones

	movdqu xmm9, [r14]		;levanto *buffer + i a xmm9. xmm9 va a tener TODA la entrada
	movdqu xmm4, xmm9		;copio toda la entrada a xmm4
	pand xmm4, xmm7		;limpio la parte superior. solo queda la primer entrada

	pxor xmm8, xmm8			;xmm8 va a tener toda la salida

	;------ arranca el ciclo chico -------------
	xor r11d, r11d		; r11d empieza en 0
	.cicloChico:
	cmp r11d, 3			;si r11d es 3, termino
	jae .finChico


	psrldq xmm8, 4			;shifteo 4 bytes, para correr los resultados anteriores hacia la derecha (los primeros van en los bits mas bajos)


	;---------- low-pass filter-------------------

	;------float temp = p(m_output)[i];
	movd r13d, xmm4

	;------p(m_output)[i] *= lpf_b0;
	mulss xmm4, xmm1

	;------p(m_output)[i] +=  lpf_b0 * *(prev_vals) + lpf_b1 * *(prev_vals+1) - lpf_a2 * *(prev_vals+2) - lpf_a1 * *(prev_vals+3);
	;movdqu xmm5, [esi]	;xmm5 = *(prev_vals+3) |*(prev_vals+2) |*(prev_vals+1) | *(prev_vals)
	movdqu xmm5, xmm12	;xmm5 = 0 | 0 | *(prev_vals+3) |*(prev_vals+2)
	pslldq xmm5, 8		;xmm5 =  *(prev_vals+3) |*(prev_vals+2) | 0 | 0
	por xmm5, xmm11		;xmm5 = *(prev_vals+3) |*(prev_vals+2) |*(prev_vals+1) | *(prev_vals)

	mulps xmm5, xmm0	;xmm5 = *(pv+3)*ps3	   |*(pv+2)*ps2	   |*(pv+1)*ps1	   |*(pv)*ps0

	;---suma vertical
	movdqu xmm15, xmm5	;xmm15 = a | b | c | d
	psrldq xmm15, 8		;xmm15 = 0 | 0 | a | b
	addps xmm5, xmm15	;xmm5  = a | b | a+c | b+d
	movdqu xmm15, xmm5	;xmm15 = a | b | a+c | b+d
	psrldq xmm15, 4		;xmm15 = 0 | a | b   | a+c
	addps xmm5, xmm15	;xmm5 = basura | basura | basura |a+c+b+d

	; haddps xmm5, xmm5	;xmm5 = basura      | basura      |psuma3+psuma2|psuma1+psuma0
	; haddps xmm5, xmm5	;xmm5 = basura      | basura      | basura		|ps3+ps2+ps1+ps0

	addss xmm4, xmm5		;xmm4 = xmm4 * lpf_b0 + lpf_b0 * *(prev_vals) + lpf_b1 * *(prev_vals+1) - lpf_a2 * *(prev_vals+2) - lpf_a1 * *(prev_vals+3)

	;-------------fin operaciones sobre el output

	;----- vieja forma
	;------*prev_vals = *(prev_vals+1);
	; mov r12d, [esi+4]		;r12d = *(prev_vals + 1)
	; mov [esi], r12d		;*prev_vals = r12d

	; xmm11 = 0 | 0 |*(prev_vals+1) | *(prev_vals)
	;------*(prev_vals+1) = temp;
	; mov [esi+4], r13d		;*(prev_vals + 1) = r13d
	;----- vieja forma

	;----- todo de una
	pxor xmm15, xmm15		;xmm15 = 0
	movd xmm15, r13d		;xmm15 = 0 | 0 | 0 | r13d
	pslldq xmm15, 8			;xmm15 = 0 | r13d | 0 | 0
	por xmm11, xmm15		;xmm11 = 0 | r13d | *(prev_vals+1) | *(prev_vals) 
	psrldq xmm11, 4			;xmm11 = 0 | 0 | r13d | *(prev_vals+1)


	;----------------- peaking EQ (resonance) ----------------
	;-------float temp2 = p(m_output)[i];
	movd r13d, xmm4

    ;-------p(m_output)[i] *= peak_b0;
    mulss xmm4, xmm3	;xmm4 = xmm4 * factorsuma2

    ;-------p(m_output)[i] += peak_b2 * *(prev_vals+2) + peak_b1 * *(prev_vals+3) - peak_a2 * *(prev_vals+4) - peak_a1 * *(prev_vals+5);
    ;movdqu xmm5, [esi+8]	;xmm5 = *(prev_vals+5) |*(prev_vals+4) |*(prev_vals+3) | *(prev_vals2)
    movdqu xmm5, xmm13		;xmm5 = 0 | 0 | *(prev_vals+5) |*(prev_vals+4)
    pslldq xmm5, 8			;xmm5 = *(prev_vals+5) |*(prev_vals+4) | 0 | 0
    por xmm5, xmm12			;xmm5 = *(prev_vals+5) |*(prev_vals+4) |*(prev_vals+3) | *(prev_vals2)

    mulps xmm5, xmm2		;xmm5 = *(pv+5)*ss3	   |*(pv+4)*ss2	   |*(pv+3)*ss1	   |*(pv+2)*ss0

    ; ---suma vertical
	movdqu xmm15, xmm5	;xmm15 = a | b | c | d
	psrldq xmm15, 8		;xmm15 = 0 | 0 | a | b
	addps xmm5, xmm15	;xmm5  = a | b | a+c | b+d
	movdqu xmm15, xmm5	;xmm15 = a | b | a+c | b+d
	psrldq xmm15, 4		;xmm15 = 0 | a | b   | a+c
	addps xmm5, xmm15	;xmm5 = basura | basura | basura |a+c+b+d


	; haddps xmm5, xmm5	;xmm5 = basura      | basura      |ssuma3+ssuma2|ssuma1+ssuma0
	; haddps xmm5, xmm5	;xmm5 = basura      | basura      | basura		|ss3+ss2+ss1+ss0

	addss xmm4, xmm5		;xmm4 = xmm4 * peak_b0 + peak_b2 * *(prev_vals+2) + peak_b1 * *(prev_vals+3) - peak_a2 * *(prev_vals+4) - peak_a1 * *(prev_vals+5);

	;------------------ fin operaciones sobre el output

	;----- vieja forma
    ;-------*(prev_vals+2) = *(prev_vals+3);
    ; mov r12d, [esi+12]		;r12d = *(prev_vals+3)
    ; mov [esi+8], r12d		;*(prev_vals+2) = r12d

    ;-------*(prev_vals+3) = temp2;
	; mov [esi+12], r13d		;*(prev_vals+3) = r13d
	;----- vieja forma

	;-------todo de una
	pxor xmm15, xmm15		;xmm15 = 0
	movd xmm15, r13d		;xmm15 = 0 | 0 | 0 | r13d
	pslldq xmm15, 8			;xmm15 = 0 | r13d | 0 | 0
	por xmm12, xmm15		;xmm12 = 0 | r13d | *(prev_vals+3) | *(prev_vals+2)
	psrldq xmm12, 4			;xmm12 = 0 | 0 | r13d | *(prev_vals+3)


	;-------vieja forma
    ;-------*(prev_vals+4) = *(prev_vals+5);
    ; mov r12d, [esi+20]		;r12d = *(prev_vals+5)
    ; mov [esi+16], r12d		;*(prev_vals+4) = r12d

    ;-------*(prev_vals+5) = p(m_output)[i];
    ; movd [esi+20], xmm4
    ;-------vieja forma

    ;-------todo de una
    pxor xmm15, xmm15		;xmm15 = 0
    movd r12d, xmm4
    movd xmm15, r12d		;xmm15 = 0 | 0 | 0 | output
    pslldq xmm15, 8			;xmm15 = 0 | output | 0 | 0
    por xmm13, xmm15		;xmm13 = 0 | output | *(prev_vals+5) | *(prev_vals+4)
    psrldq xmm13, 4			;xmm13 = 0 | 0 | output| *(prev_vals+5) 


    movdqu xmm15, xmm4		;meto xmm4 en el dw mas alto de xmm15
    pslldq xmm15, 12		;xmm15 = res | 0 | 0 | 0
    orps xmm8, xmm15

    psrldq xmm9, 4			;shifteo 1 dw a la derecha, para usar el siguiente dato. la segunda entrada pasa a ser la primera
    movdqu xmm4, xmm9		;copio toda la entrada a xmm4
	pand xmm4, xmm7		;limpio la parte superior. solo queda la primer entrada


    inc r11d
    jmp .cicloChico
    .finChico:
    ;-------fin ciclo chico

    ;----- copio xmm8 a la direccion del buffer
    movdqu [r14], xmm8


	;---incrementaciones
	add ebx, 4					;incremento el contador i, en 4
	jmp .cicloGrande
	.finGrande:

	;-----guardo el prev_vals modificado
	pslldq xmm12, 8
	por xmm12, xmm11
	movdqu [rsi], xmm12
	movq [rsi+16], xmm13
	;---

	pop r14
	pop r13
	pop r12
	pop rbx
	pop rbp
ret

;versión con sumas verticales
equalizerd:
	push rbp
	mov rbp, rsp
	push rbx		;rbx es i
	push r12		;r12 es aux
	push r13		;r13d es temp
	push r14		;r14d es la posicion del buffer


	;---------- seteo constantes------------

	;------ limpio bits superiores ---
	pxor xmm10, xmm10	; xmm10 es 0
	mov r12d, 0xFFFFFFFF
	movd xmm10, r12d		; xmm10 tiene un dw de unos, el resto 0

	;desplazo todos un xmm a la derecha - pequeño parche porque estaba mal la calling convention
	movdqu xmm8, xmm7
	movdqu xmm7, xmm6
	movdqu xmm6, xmm5
	movdqu xmm5, xmm4
	movdqu xmm4, xmm3
	movdqu xmm3, xmm2
	movdqu xmm2, xmm1
	
	movdqu xmm1, xmm0		;en xmm0 tendré lo mismo que en el 1
	mulss xmm1, [rel unDos]	;lo multiplico por dos, porque float psuma1 = psuma0 *2;

	; pand xmm0, xmm10	; filtro todo lo que no sea el primer float - todo sacar, no hace falta
	; pand xmm1, xmm10	; filtro todo lo que no sea el primer float
	; pand xmm2, xmm10	; filtro todo lo que no sea el primer float
	; pand xmm3, xmm10	; filtro todo lo que no sea el primer float
	; pand xmm4, xmm10	; filtro todo lo que no sea el primer float
	; pand xmm5, xmm10	; filtro todo lo que no sea el primer float
	; pand xmm6, xmm10	; filtro todo lo que no sea el primer float
	; pand xmm7, xmm10	; filtro todo lo que no sea el primer float
	; pand xmm8, xmm10	; filtro todo lo que no sea el primer float
	;----------------.
	;-----------------


	movdqu xmm9, xmm0		;xmm9 = factorsuma1

	;primersuma
						;xmm0	= 0 | 0 | 0 | primersuma0
	pslldq xmm1, 4		;xmm1	= 0 | 0 | primersuma1 | 0
	pslldq xmm2, 8		;xmm2	= 0 | primersuma2 | 0 | 0
	pslldq xmm3, 12		;xmm3	= primersuma3 | 0 | 0 | 0

	orps xmm0, xmm1
	orps xmm2, xmm3
	orps xmm0, xmm2		;xmm0 = primersuma3 | primersuma2 | primersuma1 | primersuma0
	;acá tengo las constantes de la primer suma en horizontal


	;segundasuma
						;xmm4	= 0 | 0 | 0 | segundasuma0
	pslldq xmm5, 4		;xmm5	= 0 | 0 | segundasuma1 | 0
	pslldq xmm6, 8		;xmm6	= 0 | segundasuma2 | 0 | 0
	pslldq xmm7, 12		;xmm7	= segundasuma3 | 0 | 0 | 0

	orps xmm4, xmm5
	orps xmm6, xmm7
	orps xmm4, xmm6		;xmm4 = segundasuma3 | segundasuma2 | segundasuma1 | segundasuma0

	;acá tengo las constantes de la segunda suma en horizontal
	
	movdqu xmm1, xmm9
	movdqu xmm3, xmm8
	movdqu xmm2, xmm4

	
	movdqu xmm7, xmm10	;xmm7 tiene un dw de unos
	movdqu xmm15, xmm10 ;xmm15 = 0 | 0 | 0 | unos
	pslldq xmm15, 4		;xmm15 = 0 | 0 | unos | 0
	por xmm10, xmm15	;xmm10 tiene un qw de unos

	;ctes:
	; xmm0: primersuma
	; xmm1: factorsuma1
	; xmm2: segundasuma
	; xmm3: factorsuma2	
	; xmm10: un qw de unos
	; xmm7: un dw de unos

	;------- fin constantes ------------------ 

	;------- levanto prev_vals
	movdqu xmm11, [rdi] ; xmm11 = *(prev_vals+3) |*(prev_vals+2) |*(prev_vals+1) | *(prev_vals)
	movdqu xmm12, xmm11	; xmm12 = *(prev_vals+3) |*(prev_vals+2) |*(prev_vals+1) | *(prev_vals)
	psrldq xmm12, 8		; xmm12 = 0 | 0 | *(prev_vals+3) | *(prev_vals+2)

	pand xmm11, xmm10 	; xmm11 = 0 | 0 |*(prev_vals+1) | *(prev_vals)



	movq xmm13, [rdi + 16]	;xmm13 = basura | basura | *(prev_vals+5) |*(prev_vals+4)
	pand xmm13, xmm10	; xmm13 = 0 | 0 | *(prev_vals+5) |*(prev_vals+4)


	;------- arranca el ciclo grande ----------------
	xor rbx, rbx		; i empieza en 0
	.cicloGrande:
	cmp edx, ebx		;si i es sample_count, termino
	jae .finGrande

	mov r14, rbx
	sal r14, 2		;multiplico por 4
	;imul r14d, 4
	add r14, rdi	;r14d es la posicion a escribir del buffer	 - TODO - mejorar con un lea
	; lea r14d, [rbx*4 + rdi]		- con el lea termino dando peor - creo que es porque hago un acceso ahi abajo, y ambos usan el bus de direcciones

	movdqu xmm9, [r14]		;levanto *buffer + i a xmm9. xmm9 va a tener TODA la entrada
	movdqu xmm4, xmm9		;copio toda la entrada a xmm4
	pand xmm4, xmm7		;limpio la parte superior. solo queda la primer entrada

	pxor xmm8, xmm8			;xmm8 va a tener toda la salida

	;------ arranca el ciclo chico -------------
	xor r11d, r11d		; r11d empieza en 0
	.cicloChico:
	cmp r11d, 3			;si r11d es 3, termino
	jae .finChico


	psrldq xmm8, 4			;shifteo 4 bytes, para correr los resultados anteriores hacia la derecha (los primeros van en los bits mas bajos)


	;---------- low-pass filter-------------------

	;------float temp = p(m_output)[i];
	movd r13d, xmm4

	;------p(m_output)[i] *= lpf_b0;
	mulss xmm4, xmm1

	;------p(m_output)[i] +=  lpf_b0 * *(prev_vals) + lpf_b1 * *(prev_vals+1) - lpf_a2 * *(prev_vals+2) - lpf_a1 * *(prev_vals+3);
	;movdqu xmm5, [esi]	;xmm5 = *(prev_vals+3) |*(prev_vals+2) |*(prev_vals+1) | *(prev_vals)
	movdqu xmm5, xmm12	;xmm5 = 0 | 0 | *(prev_vals+3) |*(prev_vals+2)
	pslldq xmm5, 8		;xmm5 =  *(prev_vals+3) |*(prev_vals+2) | 0 | 0
	por xmm5, xmm11		;xmm5 = *(prev_vals+3) |*(prev_vals+2) |*(prev_vals+1) | *(prev_vals)

	mulps xmm5, xmm0	;xmm5 = *(pv+3)*ps3	   |*(pv+2)*ps2	   |*(pv+1)*ps1	   |*(pv)*ps0


    ; ---suma vertical
	movdqu xmm15, xmm5	;xmm15 = a | b | c | d
	psrldq xmm15, 8		;xmm15 = 0 | 0 | a | b
	addps xmm5, xmm15	;xmm5  = a | b | a+c | b+d
	movdqu xmm15, xmm5	;xmm15 = a | b | a+c | b+d
	psrldq xmm15, 4		;xmm15 = 0 | a | b   | a+c
	addps xmm5, xmm15	;xmm5 = basura | basura | basura |a+c+b+d


	; haddps xmm5, xmm5	;xmm5 = basura      | basura      |psuma3+psuma2|psuma1+psuma0
	; haddps xmm5, xmm5	;xmm5 = basura      | basura      | basura		|ps3+ps2+ps1+ps0

	addss xmm4, xmm5		;xmm4 = xmm4 * lpf_b0 + lpf_b0 * *(prev_vals) + lpf_b1 * *(prev_vals+1) - lpf_a2 * *(prev_vals+2) - lpf_a1 * *(prev_vals+3)

	;-------------fin operaciones sobre el output

	;----- vieja forma
	;------*prev_vals = *(prev_vals+1);
	; mov r12d, [esi+4]		;r12d = *(prev_vals + 1)
	; mov [esi], r12d		;*prev_vals = r12d

	; xmm11 = 0 | 0 |*(prev_vals+1) | *(prev_vals)
	;------*(prev_vals+1) = temp;
	; mov [esi+4], r13d		;*(prev_vals + 1) = r13d
	;----- vieja forma

	;----- todo de una
	pxor xmm15, xmm15		;xmm15 = 0
	movd xmm15, r13d		;xmm15 = 0 | 0 | 0 | r13d
	pslldq xmm15, 8			;xmm15 = 0 | r13d | 0 | 0
	por xmm11, xmm15		;xmm11 = 0 | r13d | *(prev_vals+1) | *(prev_vals) 
	psrldq xmm11, 4			;xmm11 = 0 | 0 | r13d | *(prev_vals+1)


	;----------------- peaking EQ (resonance) ----------------
	;-------float temp2 = p(m_output)[i];
	movd r13d, xmm4

    ;-------p(m_output)[i] *= peak_b0;
    mulss xmm4, xmm3	;xmm4 = xmm4 * factorsuma2

    ;-------p(m_output)[i] += peak_b2 * *(prev_vals+2) + peak_b1 * *(prev_vals+3) - peak_a2 * *(prev_vals+4) - peak_a1 * *(prev_vals+5);
    ;movdqu xmm5, [esi+8]	;xmm5 = *(prev_vals+5) |*(prev_vals+4) |*(prev_vals+3) | *(prev_vals2)
    movdqu xmm5, xmm13		;xmm5 = 0 | 0 | *(prev_vals+5) |*(prev_vals+4)
    pslldq xmm5, 8			;xmm5 = *(prev_vals+5) |*(prev_vals+4) | 0 | 0
    por xmm5, xmm12			;xmm5 = *(prev_vals+5) |*(prev_vals+4) |*(prev_vals+3) | *(prev_vals2)

    mulps xmm5, xmm2		;xmm5 = *(pv+5)*ss3	   |*(pv+4)*ss2	   |*(pv+3)*ss1	   |*(pv+2)*ss0

    ; ---suma vertical
	movdqu xmm15, xmm5	;xmm15 = a | b | c | d
	psrldq xmm15, 8		;xmm15 = 0 | 0 | a | b
	addps xmm5, xmm15	;xmm5  = a | b | a+c | b+d
	movdqu xmm15, xmm5	;xmm15 = a | b | a+c | b+d
	psrldq xmm15, 4		;xmm15 = 0 | a | b   | a+c
	addps xmm5, xmm15	;xmm5 = basura | basura | basura |a+c+b+d


	; haddps xmm5, xmm5	;xmm5 = basura      | basura      |ssuma3+ssuma2|ssuma1+ssuma0
	; haddps xmm5, xmm5	;xmm5 = basura      | basura      | basura		|ss3+ss2+ss1+ss0

	addss xmm4, xmm5		;xmm4 = xmm4 * peak_b0 + peak_b2 * *(prev_vals+2) + peak_b1 * *(prev_vals+3) - peak_a2 * *(prev_vals+4) - peak_a1 * *(prev_vals+5);

	;------------------ fin operaciones sobre el output

	;----- vieja forma
    ;-------*(prev_vals+2) = *(prev_vals+3);
    ; mov r12d, [esi+12]		;r12d = *(prev_vals+3)
    ; mov [esi+8], r12d		;*(prev_vals+2) = r12d

    ;-------*(prev_vals+3) = temp2;
	; mov [esi+12], r13d		;*(prev_vals+3) = r13d
	;----- vieja forma

	;-------todo de una
	pxor xmm15, xmm15		;xmm15 = 0
	movd xmm15, r13d		;xmm15 = 0 | 0 | 0 | r13d
	pslldq xmm15, 8			;xmm15 = 0 | r13d | 0 | 0
	por xmm12, xmm15		;xmm12 = 0 | r13d | *(prev_vals+3) | *(prev_vals+2)
	psrldq xmm12, 4			;xmm12 = 0 | 0 | r13d | *(prev_vals+3)


	;-------vieja forma
    ;-------*(prev_vals+4) = *(prev_vals+5);
    ; mov r12d, [esi+20]		;r12d = *(prev_vals+5)
    ; mov [esi+16], r12d		;*(prev_vals+4) = r12d

    ;-------*(prev_vals+5) = p(m_output)[i];
    ; movd [esi+20], xmm4
    ;-------vieja forma

    ;-------todo de una
    pxor xmm15, xmm15		;xmm15 = 0
    movd r12d, xmm4
    movd xmm15, r12d		;xmm15 = 0 | 0 | 0 | output
    pslldq xmm15, 8			;xmm15 = 0 | output | 0 | 0
    por xmm13, xmm15		;xmm13 = 0 | output | *(prev_vals+5) | *(prev_vals+4)
    psrldq xmm13, 4			;xmm13 = 0 | 0 | output| *(prev_vals+5) 


    movdqu xmm15, xmm4		;meto xmm4 en el dw mas alto de xmm15
    pslldq xmm15, 12		;xmm15 = res | 0 | 0 | 0
    orps xmm8, xmm15

    psrldq xmm9, 4			;shifteo 1 dw a la derecha, para usar el siguiente dato. la segunda entrada pasa a ser la primera
    movdqu xmm4, xmm9		;copio toda la entrada a xmm4
	pand xmm4, xmm7		;limpio la parte superior. solo queda la primer entrada


    inc r11d
    jmp .cicloChico
    .finChico:
    ;-------fin ciclo chico

    ;----- copio xmm8 a la direccion del buffer
    movdqu [r14], xmm8


	;---incrementaciones
	add ebx, 4					;incremento el contador i, en 4
	jmp .cicloGrande
	.finGrande:

	;-----guardo el prev_vals modificado
	pslldq xmm12, 8
	por xmm12, xmm11
	movdqu [rsi], xmm12
	movq [rsi+16], xmm13
	;---

	pop r14
	pop r13
	pop r12
	pop rbx
	pop rbp
ret

;------------------------------------------------------------------------------------------
;---------------------------- VERSIONES UN ACCESO CUATRO DATOS, LOOP UNROLLED -------------
;------------------------------------------------------------------------------------------

;versión con sumas horizontales
equalizere:
	push rbp
	mov rbp, rsp
	push rbx		;rbx es i
	push r12		;r12 es aux
	push r13		;r13d es temp
	push r14		;r14d es la posicion del buffer


	;---------- seteo constantes------------

	;------ limpio bits superiores ---
	pxor xmm10, xmm10	; xmm10 es 0
	mov r12d, 0xFFFFFFFF
	movd xmm10, r12d		; xmm10 tiene un dw de unos, el resto 0

	;desplazo todos un xmm a la derecha - pequeño parche porque estaba mal la calling convention
	movdqu xmm8, xmm7
	movdqu xmm7, xmm6
	movdqu xmm6, xmm5
	movdqu xmm5, xmm4
	movdqu xmm4, xmm3
	movdqu xmm3, xmm2
	movdqu xmm2, xmm1
	
	movdqu xmm1, xmm0		;en xmm0 tendré lo mismo que en el 1
	mulss xmm1, [rel unDos]	;lo multiplico por dos, porque float psuma1 = psuma0 *2;

	; pand xmm0, xmm10	; filtro todo lo que no sea el primer float - todo sacar, no hace falta
	; pand xmm1, xmm10	; filtro todo lo que no sea el primer float
	; pand xmm2, xmm10	; filtro todo lo que no sea el primer float
	; pand xmm3, xmm10	; filtro todo lo que no sea el primer float
	; pand xmm4, xmm10	; filtro todo lo que no sea el primer float
	; pand xmm5, xmm10	; filtro todo lo que no sea el primer float
	; pand xmm6, xmm10	; filtro todo lo que no sea el primer float
	; pand xmm7, xmm10	; filtro todo lo que no sea el primer float
	; pand xmm8, xmm10	; filtro todo lo que no sea el primer float
	;----------------.
	;-----------------


	movdqu xmm9, xmm0		;xmm9 = factorsuma1

	;primersuma
						;xmm0	= 0 | 0 | 0 | primersuma0
	pslldq xmm1, 4		;xmm1	= 0 | 0 | primersuma1 | 0
	pslldq xmm2, 8		;xmm2	= 0 | primersuma2 | 0 | 0
	pslldq xmm3, 12		;xmm3	= primersuma3 | 0 | 0 | 0

	orps xmm0, xmm1
	orps xmm2, xmm3
	orps xmm0, xmm2		;xmm0 = primersuma3 | primersuma2 | primersuma1 | primersuma0
	;acá tengo las constantes de la primer suma en horizontal


	;segundasuma
						;xmm4	= 0 | 0 | 0 | segundasuma0
	pslldq xmm5, 4		;xmm5	= 0 | 0 | segundasuma1 | 0
	pslldq xmm6, 8		;xmm6	= 0 | segundasuma2 | 0 | 0
	pslldq xmm7, 12		;xmm7	= segundasuma3 | 0 | 0 | 0

	orps xmm4, xmm5
	orps xmm6, xmm7
	orps xmm4, xmm6		;xmm4 = segundasuma3 | segundasuma2 | segundasuma1 | segundasuma0

	;acá tengo las constantes de la segunda suma en horizontal
	
	movdqu xmm1, xmm9
	movdqu xmm3, xmm8
	movdqu xmm2, xmm4

	
	movdqu xmm7, xmm10	;xmm7 tiene un dw de unos
	movdqu xmm15, xmm10 ;xmm15 = 0 | 0 | 0 | unos
	pslldq xmm15, 4		;xmm15 = 0 | 0 | unos | 0
	por xmm10, xmm15	;xmm10 tiene un qw de unos

	;ctes:
	; xmm0: primersuma
	; xmm1: factorsuma1
	; xmm2: segundasuma
	; xmm3: factorsuma2	
	; xmm10: un qw de unos
	; xmm7: un dw de unos

	;------- fin constantes ------------------ 

	;------- levanto prev_vals
	movdqu xmm11, [rsi] ; xmm11 = *(prev_vals+3) |*(prev_vals+2) |*(prev_vals+1) | *(prev_vals)
	movdqu xmm12, xmm11	; xmm12 = *(prev_vals+3) |*(prev_vals+2) |*(prev_vals+1) | *(prev_vals)
	psrldq xmm12, 8		; xmm12 = 0 | 0 | *(prev_vals+3) | *(prev_vals+2)

	pand xmm11, xmm10 	; xmm11 = 0 | 0 |*(prev_vals+1) | *(prev_vals)



	movq xmm13, [rsi + 16]	;xmm13 = basura | basura | *(prev_vals+5) |*(prev_vals+4)
	pand xmm13, xmm10	; xmm13 = 0 | 0 | *(prev_vals+5) |*(prev_vals+4)


	;------- arranca el ciclo grande ----------------
	xor rbx, rbx		; i empieza en 0
	.cicloGrande:
	cmp edx, ebx		;si i es sample_count, termino
	jae .finGrande

	mov r14, rbx
	sal r14, 2		;multiplico por 4
	;imul r14d, 4
	add r14, rdi	;r14d es la posicion a escribir del buffer	 - TODO - mejorar con un lea
	; lea r14d, [rbx*4 + rdi]		- con el lea termino dando peor - creo que es porque hago un acceso ahi abajo, y ambos usan el bus de direcciones

	movdqu xmm9, [r14]		;levanto *buffer + i a xmm9. xmm9 va a tener TODA la entrada
	movdqu xmm4, xmm9		;copio toda la entrada a xmm4
	pand xmm4, xmm7		;limpio la parte superior. solo queda la primer entrada

	pxor xmm8, xmm8			;xmm8 va a tener toda la salida

	;------ arrancan los 4 ciclos chicos -------------
	

	;--------------------------------------------- 
	;---------- inicio ciclo 0 -------------------
	;--------------------------------------------- 

	xor r11d, r11d		; r11d empieza en 0


	psrldq xmm8, 4			;shifteo 4 bytes, para correr los resultados anteriores hacia la derecha (los primeros van en los bits mas bajos)

	;---------- low-pass filter-------------------

	;------float temp = p(m_output)[i];
	movd r13d, xmm4

	;------p(m_output)[i] *= lpf_b0;
	mulss xmm4, xmm1

	;------p(m_output)[i] +=  lpf_b0 * *(prev_vals) + lpf_b1 * *(prev_vals+1) - lpf_a2 * *(prev_vals+2) - lpf_a1 * *(prev_vals+3);
	;movdqu xmm5, [esi]	;xmm5 = *(prev_vals+3) |*(prev_vals+2) |*(prev_vals+1) | *(prev_vals)
	movdqu xmm5, xmm12	;xmm5 = 0 | 0 | *(prev_vals+3) |*(prev_vals+2)
	pslldq xmm5, 8		;xmm5 =  *(prev_vals+3) |*(prev_vals+2) | 0 | 0
	por xmm5, xmm11		;xmm5 = *(prev_vals+3) |*(prev_vals+2) |*(prev_vals+1) | *(prev_vals)

	mulps xmm5, xmm0	;xmm5 = *(pv+3)*ps3	   |*(pv+2)*ps2	   |*(pv+1)*ps1	   |*(pv)*ps0

	;---suma vertical
	movdqu xmm15, xmm5	;xmm15 = a | b | c | d
	psrldq xmm15, 8		;xmm15 = 0 | 0 | a | b
	addps xmm5, xmm15	;xmm5  = a | b | a+c | b+d
	movdqu xmm15, xmm5	;xmm15 = a | b | a+c | b+d
	psrldq xmm15, 4		;xmm15 = 0 | a | b   | a+c
	addps xmm5, xmm15	;xmm5 = basura | basura | basura |a+c+b+d

	; haddps xmm5, xmm5	;xmm5 = basura      | basura      |psuma3+psuma2|psuma1+psuma0
	; haddps xmm5, xmm5	;xmm5 = basura      | basura      | basura		|ps3+ps2+ps1+ps0

	addss xmm4, xmm5		;xmm4 = xmm4 * lpf_b0 + lpf_b0 * *(prev_vals) + lpf_b1 * *(prev_vals+1) - lpf_a2 * *(prev_vals+2) - lpf_a1 * *(prev_vals+3)

	;-------------fin operaciones sobre el output

	;----- vieja forma
	;------*prev_vals = *(prev_vals+1);
	; mov r12d, [esi+4]		;r12d = *(prev_vals + 1)
	; mov [esi], r12d		;*prev_vals = r12d

	; xmm11 = 0 | 0 |*(prev_vals+1) | *(prev_vals)
	;------*(prev_vals+1) = temp;
	; mov [esi+4], r13d		;*(prev_vals + 1) = r13d
	;----- vieja forma

	;----- todo de una
	pxor xmm15, xmm15		;xmm15 = 0
	movd xmm15, r13d		;xmm15 = 0 | 0 | 0 | r13d
	pslldq xmm15, 8			;xmm15 = 0 | r13d | 0 | 0
	por xmm11, xmm15		;xmm11 = 0 | r13d | *(prev_vals+1) | *(prev_vals) 
	psrldq xmm11, 4			;xmm11 = 0 | 0 | r13d | *(prev_vals+1)


	;----------------- peaking EQ (resonance) ----------------
	;-------float temp2 = p(m_output)[i];
	movd r13d, xmm4

    ;-------p(m_output)[i] *= peak_b0;
    mulss xmm4, xmm3	;xmm4 = xmm4 * factorsuma2

    ;-------p(m_output)[i] += peak_b2 * *(prev_vals+2) + peak_b1 * *(prev_vals+3) - peak_a2 * *(prev_vals+4) - peak_a1 * *(prev_vals+5);
    ;movdqu xmm5, [esi+8]	;xmm5 = *(prev_vals+5) |*(prev_vals+4) |*(prev_vals+3) | *(prev_vals2)
    movdqu xmm5, xmm13		;xmm5 = 0 | 0 | *(prev_vals+5) |*(prev_vals+4)
    pslldq xmm5, 8			;xmm5 = *(prev_vals+5) |*(prev_vals+4) | 0 | 0
    por xmm5, xmm12			;xmm5 = *(prev_vals+5) |*(prev_vals+4) |*(prev_vals+3) | *(prev_vals2)

    mulps xmm5, xmm2		;xmm5 = *(pv+5)*ss3	   |*(pv+4)*ss2	   |*(pv+3)*ss1	   |*(pv+2)*ss0

    ; ---suma vertical
	movdqu xmm15, xmm5	;xmm15 = a | b | c | d
	psrldq xmm15, 8		;xmm15 = 0 | 0 | a | b
	addps xmm5, xmm15	;xmm5  = a | b | a+c | b+d
	movdqu xmm15, xmm5	;xmm15 = a | b | a+c | b+d
	psrldq xmm15, 4		;xmm15 = 0 | a | b   | a+c
	addps xmm5, xmm15	;xmm5 = basura | basura | basura |a+c+b+d


	; haddps xmm5, xmm5	;xmm5 = basura      | basura      |ssuma3+ssuma2|ssuma1+ssuma0
	; haddps xmm5, xmm5	;xmm5 = basura      | basura      | basura		|ss3+ss2+ss1+ss0

	addss xmm4, xmm5		;xmm4 = xmm4 * peak_b0 + peak_b2 * *(prev_vals+2) + peak_b1 * *(prev_vals+3) - peak_a2 * *(prev_vals+4) - peak_a1 * *(prev_vals+5);

	;------------------ fin operaciones sobre el output

	;----- vieja forma
    ;-------*(prev_vals+2) = *(prev_vals+3);
    ; mov r12d, [esi+12]		;r12d = *(prev_vals+3)
    ; mov [esi+8], r12d		;*(prev_vals+2) = r12d

    ;-------*(prev_vals+3) = temp2;
	; mov [esi+12], r13d		;*(prev_vals+3) = r13d
	;----- vieja forma

	;-------todo de una
	pxor xmm15, xmm15		;xmm15 = 0
	movd xmm15, r13d		;xmm15 = 0 | 0 | 0 | r13d
	pslldq xmm15, 8			;xmm15 = 0 | r13d | 0 | 0
	por xmm12, xmm15		;xmm12 = 0 | r13d | *(prev_vals+3) | *(prev_vals+2)
	psrldq xmm12, 4			;xmm12 = 0 | 0 | r13d | *(prev_vals+3)


	;-------vieja forma
    ;-------*(prev_vals+4) = *(prev_vals+5);
    ; mov r12d, [esi+20]		;r12d = *(prev_vals+5)
    ; mov [esi+16], r12d		;*(prev_vals+4) = r12d

    ;-------*(prev_vals+5) = p(m_output)[i];
    ; movd [esi+20], xmm4
    ;-------vieja forma

    ;-------todo de una
    pxor xmm15, xmm15		;xmm15 = 0
    movd r12d, xmm4
    movd xmm15, r12d		;xmm15 = 0 | 0 | 0 | output
    pslldq xmm15, 8			;xmm15 = 0 | output | 0 | 0
    por xmm13, xmm15		;xmm13 = 0 | output | *(prev_vals+5) | *(prev_vals+4)
    psrldq xmm13, 4			;xmm13 = 0 | 0 | output| *(prev_vals+5) 


    movdqu xmm15, xmm4		;meto xmm4 en el dw mas alto de xmm15
    pslldq xmm15, 12		;xmm15 = res | 0 | 0 | 0
    orps xmm8, xmm15

    psrldq xmm9, 4			;shifteo 1 dw a la derecha, para usar el siguiente dato. la segunda entrada pasa a ser la primera
    movdqu xmm4, xmm9		;copio toda la entrada a xmm4
	pand xmm4, xmm7		;limpio la parte superior. solo queda la primer entrada


    inc r11d
    
    ;--------------------------------------------- 
	;---------- fin ciclo 0 ----------------------
	;--------------------------------------------- 

	;--------------------------------------------- 
	;---------- inicio ciclo 1 -------------------
	;--------------------------------------------- 

	xor r11d, r11d		; r11d empieza en 0


	psrldq xmm8, 4			;shifteo 4 bytes, para correr los resultados anteriores hacia la derecha (los primeros van en los bits mas bajos)

	;---------- low-pass filter-------------------

	;------float temp = p(m_output)[i];
	movd r13d, xmm4

	;------p(m_output)[i] *= lpf_b0;
	mulss xmm4, xmm1

	;------p(m_output)[i] +=  lpf_b0 * *(prev_vals) + lpf_b1 * *(prev_vals+1) - lpf_a2 * *(prev_vals+2) - lpf_a1 * *(prev_vals+3);
	;movdqu xmm5, [esi]	;xmm5 = *(prev_vals+3) |*(prev_vals+2) |*(prev_vals+1) | *(prev_vals)
	movdqu xmm5, xmm12	;xmm5 = 0 | 0 | *(prev_vals+3) |*(prev_vals+2)
	pslldq xmm5, 8		;xmm5 =  *(prev_vals+3) |*(prev_vals+2) | 0 | 0
	por xmm5, xmm11		;xmm5 = *(prev_vals+3) |*(prev_vals+2) |*(prev_vals+1) | *(prev_vals)

	mulps xmm5, xmm0	;xmm5 = *(pv+3)*ps3	   |*(pv+2)*ps2	   |*(pv+1)*ps1	   |*(pv)*ps0

	;---suma vertical
	movdqu xmm15, xmm5	;xmm15 = a | b | c | d
	psrldq xmm15, 8		;xmm15 = 0 | 0 | a | b
	addps xmm5, xmm15	;xmm5  = a | b | a+c | b+d
	movdqu xmm15, xmm5	;xmm15 = a | b | a+c | b+d
	psrldq xmm15, 4		;xmm15 = 0 | a | b   | a+c
	addps xmm5, xmm15	;xmm5 = basura | basura | basura |a+c+b+d

	; haddps xmm5, xmm5	;xmm5 = basura      | basura      |psuma3+psuma2|psuma1+psuma0
	; haddps xmm5, xmm5	;xmm5 = basura      | basura      | basura		|ps3+ps2+ps1+ps0

	addss xmm4, xmm5		;xmm4 = xmm4 * lpf_b0 + lpf_b0 * *(prev_vals) + lpf_b1 * *(prev_vals+1) - lpf_a2 * *(prev_vals+2) - lpf_a1 * *(prev_vals+3)

	;-------------fin operaciones sobre el output

	;----- vieja forma
	;------*prev_vals = *(prev_vals+1);
	; mov r12d, [esi+4]		;r12d = *(prev_vals + 1)
	; mov [esi], r12d		;*prev_vals = r12d

	; xmm11 = 0 | 0 |*(prev_vals+1) | *(prev_vals)
	;------*(prev_vals+1) = temp;
	; mov [esi+4], r13d		;*(prev_vals + 1) = r13d
	;----- vieja forma

	;----- todo de una
	pxor xmm15, xmm15		;xmm15 = 0
	movd xmm15, r13d		;xmm15 = 0 | 0 | 0 | r13d
	pslldq xmm15, 8			;xmm15 = 0 | r13d | 0 | 0
	por xmm11, xmm15		;xmm11 = 0 | r13d | *(prev_vals+1) | *(prev_vals) 
	psrldq xmm11, 4			;xmm11 = 0 | 0 | r13d | *(prev_vals+1)


	;----------------- peaking EQ (resonance) ----------------
	;-------float temp2 = p(m_output)[i];
	movd r13d, xmm4

    ;-------p(m_output)[i] *= peak_b0;
    mulss xmm4, xmm3	;xmm4 = xmm4 * factorsuma2

    ;-------p(m_output)[i] += peak_b2 * *(prev_vals+2) + peak_b1 * *(prev_vals+3) - peak_a2 * *(prev_vals+4) - peak_a1 * *(prev_vals+5);
    ;movdqu xmm5, [esi+8]	;xmm5 = *(prev_vals+5) |*(prev_vals+4) |*(prev_vals+3) | *(prev_vals2)
    movdqu xmm5, xmm13		;xmm5 = 0 | 0 | *(prev_vals+5) |*(prev_vals+4)
    pslldq xmm5, 8			;xmm5 = *(prev_vals+5) |*(prev_vals+4) | 0 | 0
    por xmm5, xmm12			;xmm5 = *(prev_vals+5) |*(prev_vals+4) |*(prev_vals+3) | *(prev_vals2)

    mulps xmm5, xmm2		;xmm5 = *(pv+5)*ss3	   |*(pv+4)*ss2	   |*(pv+3)*ss1	   |*(pv+2)*ss0

    ; ---suma vertical
	movdqu xmm15, xmm5	;xmm15 = a | b | c | d
	psrldq xmm15, 8		;xmm15 = 0 | 0 | a | b
	addps xmm5, xmm15	;xmm5  = a | b | a+c | b+d
	movdqu xmm15, xmm5	;xmm15 = a | b | a+c | b+d
	psrldq xmm15, 4		;xmm15 = 0 | a | b   | a+c
	addps xmm5, xmm15	;xmm5 = basura | basura | basura |a+c+b+d


	; haddps xmm5, xmm5	;xmm5 = basura      | basura      |ssuma3+ssuma2|ssuma1+ssuma0
	; haddps xmm5, xmm5	;xmm5 = basura      | basura      | basura		|ss3+ss2+ss1+ss0

	addss xmm4, xmm5		;xmm4 = xmm4 * peak_b0 + peak_b2 * *(prev_vals+2) + peak_b1 * *(prev_vals+3) - peak_a2 * *(prev_vals+4) - peak_a1 * *(prev_vals+5);

	;------------------ fin operaciones sobre el output

	;----- vieja forma
    ;-------*(prev_vals+2) = *(prev_vals+3);
    ; mov r12d, [esi+12]		;r12d = *(prev_vals+3)
    ; mov [esi+8], r12d		;*(prev_vals+2) = r12d

    ;-------*(prev_vals+3) = temp2;
	; mov [esi+12], r13d		;*(prev_vals+3) = r13d
	;----- vieja forma

	;-------todo de una
	pxor xmm15, xmm15		;xmm15 = 0
	movd xmm15, r13d		;xmm15 = 0 | 0 | 0 | r13d
	pslldq xmm15, 8			;xmm15 = 0 | r13d | 0 | 0
	por xmm12, xmm15		;xmm12 = 0 | r13d | *(prev_vals+3) | *(prev_vals+2)
	psrldq xmm12, 4			;xmm12 = 0 | 0 | r13d | *(prev_vals+3)


	;-------vieja forma
    ;-------*(prev_vals+4) = *(prev_vals+5);
    ; mov r12d, [esi+20]		;r12d = *(prev_vals+5)
    ; mov [esi+16], r12d		;*(prev_vals+4) = r12d

    ;-------*(prev_vals+5) = p(m_output)[i];
    ; movd [esi+20], xmm4
    ;-------vieja forma

    ;-------todo de una
    pxor xmm15, xmm15		;xmm15 = 0
    movd r12d, xmm4
    movd xmm15, r12d		;xmm15 = 0 | 0 | 0 | output
    pslldq xmm15, 8			;xmm15 = 0 | output | 0 | 0
    por xmm13, xmm15		;xmm13 = 0 | output | *(prev_vals+5) | *(prev_vals+4)
    psrldq xmm13, 4			;xmm13 = 0 | 0 | output| *(prev_vals+5) 


    movdqu xmm15, xmm4		;meto xmm4 en el dw mas alto de xmm15
    pslldq xmm15, 12		;xmm15 = res | 0 | 0 | 0
    orps xmm8, xmm15

    psrldq xmm9, 4			;shifteo 1 dw a la derecha, para usar el siguiente dato. la segunda entrada pasa a ser la primera
    movdqu xmm4, xmm9		;copio toda la entrada a xmm4
	pand xmm4, xmm7		;limpio la parte superior. solo queda la primer entrada


    inc r11d
    
    ;--------------------------------------------- 
	;---------- fin ciclo 1 ----------------------
	;--------------------------------------------- 

	;--------------------------------------------- 
	;---------- inicio ciclo 2 -------------------
	;--------------------------------------------- 

	xor r11d, r11d		; r11d empieza en 0


	psrldq xmm8, 4			;shifteo 4 bytes, para correr los resultados anteriores hacia la derecha (los primeros van en los bits mas bajos)

	;---------- low-pass filter-------------------

	;------float temp = p(m_output)[i];
	movd r13d, xmm4

	;------p(m_output)[i] *= lpf_b0;
	mulss xmm4, xmm1

	;------p(m_output)[i] +=  lpf_b0 * *(prev_vals) + lpf_b1 * *(prev_vals+1) - lpf_a2 * *(prev_vals+2) - lpf_a1 * *(prev_vals+3);
	;movdqu xmm5, [esi]	;xmm5 = *(prev_vals+3) |*(prev_vals+2) |*(prev_vals+1) | *(prev_vals)
	movdqu xmm5, xmm12	;xmm5 = 0 | 0 | *(prev_vals+3) |*(prev_vals+2)
	pslldq xmm5, 8		;xmm5 =  *(prev_vals+3) |*(prev_vals+2) | 0 | 0
	por xmm5, xmm11		;xmm5 = *(prev_vals+3) |*(prev_vals+2) |*(prev_vals+1) | *(prev_vals)

	mulps xmm5, xmm0	;xmm5 = *(pv+3)*ps3	   |*(pv+2)*ps2	   |*(pv+1)*ps1	   |*(pv)*ps0

	;---suma vertical
	movdqu xmm15, xmm5	;xmm15 = a | b | c | d
	psrldq xmm15, 8		;xmm15 = 0 | 0 | a | b
	addps xmm5, xmm15	;xmm5  = a | b | a+c | b+d
	movdqu xmm15, xmm5	;xmm15 = a | b | a+c | b+d
	psrldq xmm15, 4		;xmm15 = 0 | a | b   | a+c
	addps xmm5, xmm15	;xmm5 = basura | basura | basura |a+c+b+d

	; haddps xmm5, xmm5	;xmm5 = basura      | basura      |psuma3+psuma2|psuma1+psuma0
	; haddps xmm5, xmm5	;xmm5 = basura      | basura      | basura		|ps3+ps2+ps1+ps0

	addss xmm4, xmm5		;xmm4 = xmm4 * lpf_b0 + lpf_b0 * *(prev_vals) + lpf_b1 * *(prev_vals+1) - lpf_a2 * *(prev_vals+2) - lpf_a1 * *(prev_vals+3)

	;-------------fin operaciones sobre el output

	;----- vieja forma
	;------*prev_vals = *(prev_vals+1);
	; mov r12d, [esi+4]		;r12d = *(prev_vals + 1)
	; mov [esi], r12d		;*prev_vals = r12d

	; xmm11 = 0 | 0 |*(prev_vals+1) | *(prev_vals)
	;------*(prev_vals+1) = temp;
	; mov [esi+4], r13d		;*(prev_vals + 1) = r13d
	;----- vieja forma

	;----- todo de una
	pxor xmm15, xmm15		;xmm15 = 0
	movd xmm15, r13d		;xmm15 = 0 | 0 | 0 | r13d
	pslldq xmm15, 8			;xmm15 = 0 | r13d | 0 | 0
	por xmm11, xmm15		;xmm11 = 0 | r13d | *(prev_vals+1) | *(prev_vals) 
	psrldq xmm11, 4			;xmm11 = 0 | 0 | r13d | *(prev_vals+1)


	;----------------- peaking EQ (resonance) ----------------
	;-------float temp2 = p(m_output)[i];
	movd r13d, xmm4

    ;-------p(m_output)[i] *= peak_b0;
    mulss xmm4, xmm3	;xmm4 = xmm4 * factorsuma2

    ;-------p(m_output)[i] += peak_b2 * *(prev_vals+2) + peak_b1 * *(prev_vals+3) - peak_a2 * *(prev_vals+4) - peak_a1 * *(prev_vals+5);
    ;movdqu xmm5, [esi+8]	;xmm5 = *(prev_vals+5) |*(prev_vals+4) |*(prev_vals+3) | *(prev_vals2)
    movdqu xmm5, xmm13		;xmm5 = 0 | 0 | *(prev_vals+5) |*(prev_vals+4)
    pslldq xmm5, 8			;xmm5 = *(prev_vals+5) |*(prev_vals+4) | 0 | 0
    por xmm5, xmm12			;xmm5 = *(prev_vals+5) |*(prev_vals+4) |*(prev_vals+3) | *(prev_vals2)

    mulps xmm5, xmm2		;xmm5 = *(pv+5)*ss3	   |*(pv+4)*ss2	   |*(pv+3)*ss1	   |*(pv+2)*ss0

    ; ---suma vertical
	movdqu xmm15, xmm5	;xmm15 = a | b | c | d
	psrldq xmm15, 8		;xmm15 = 0 | 0 | a | b
	addps xmm5, xmm15	;xmm5  = a | b | a+c | b+d
	movdqu xmm15, xmm5	;xmm15 = a | b | a+c | b+d
	psrldq xmm15, 4		;xmm15 = 0 | a | b   | a+c
	addps xmm5, xmm15	;xmm5 = basura | basura | basura |a+c+b+d


	; haddps xmm5, xmm5	;xmm5 = basura      | basura      |ssuma3+ssuma2|ssuma1+ssuma0
	; haddps xmm5, xmm5	;xmm5 = basura      | basura      | basura		|ss3+ss2+ss1+ss0

	addss xmm4, xmm5		;xmm4 = xmm4 * peak_b0 + peak_b2 * *(prev_vals+2) + peak_b1 * *(prev_vals+3) - peak_a2 * *(prev_vals+4) - peak_a1 * *(prev_vals+5);

	;------------------ fin operaciones sobre el output

	;----- vieja forma
    ;-------*(prev_vals+2) = *(prev_vals+3);
    ; mov r12d, [esi+12]		;r12d = *(prev_vals+3)
    ; mov [esi+8], r12d		;*(prev_vals+2) = r12d

    ;-------*(prev_vals+3) = temp2;
	; mov [esi+12], r13d		;*(prev_vals+3) = r13d
	;----- vieja forma

	;-------todo de una
	pxor xmm15, xmm15		;xmm15 = 0
	movd xmm15, r13d		;xmm15 = 0 | 0 | 0 | r13d
	pslldq xmm15, 8			;xmm15 = 0 | r13d | 0 | 0
	por xmm12, xmm15		;xmm12 = 0 | r13d | *(prev_vals+3) | *(prev_vals+2)
	psrldq xmm12, 4			;xmm12 = 0 | 0 | r13d | *(prev_vals+3)


	;-------vieja forma
    ;-------*(prev_vals+4) = *(prev_vals+5);
    ; mov r12d, [esi+20]		;r12d = *(prev_vals+5)
    ; mov [esi+16], r12d		;*(prev_vals+4) = r12d

    ;-------*(prev_vals+5) = p(m_output)[i];
    ; movd [esi+20], xmm4
    ;-------vieja forma

    ;-------todo de una
    pxor xmm15, xmm15		;xmm15 = 0
    movd r12d, xmm4
    movd xmm15, r12d		;xmm15 = 0 | 0 | 0 | output
    pslldq xmm15, 8			;xmm15 = 0 | output | 0 | 0
    por xmm13, xmm15		;xmm13 = 0 | output | *(prev_vals+5) | *(prev_vals+4)
    psrldq xmm13, 4			;xmm13 = 0 | 0 | output| *(prev_vals+5) 


    movdqu xmm15, xmm4		;meto xmm4 en el dw mas alto de xmm15
    pslldq xmm15, 12		;xmm15 = res | 0 | 0 | 0
    orps xmm8, xmm15

    psrldq xmm9, 4			;shifteo 1 dw a la derecha, para usar el siguiente dato. la segunda entrada pasa a ser la primera
    movdqu xmm4, xmm9		;copio toda la entrada a xmm4
	pand xmm4, xmm7		;limpio la parte superior. solo queda la primer entrada


    inc r11d
    
    ;--------------------------------------------- 
	;---------- fin ciclo 2 ----------------------
	;---------------------------------------------


	;--------------------------------------------- 
	;---------- inicio ciclo 3 -------------------
	;--------------------------------------------- 

	xor r11d, r11d		; r11d empieza en 0


	psrldq xmm8, 4			;shifteo 4 bytes, para correr los resultados anteriores hacia la derecha (los primeros van en los bits mas bajos)

	;---------- low-pass filter-------------------

	;------float temp = p(m_output)[i];
	movd r13d, xmm4

	;------p(m_output)[i] *= lpf_b0;
	mulss xmm4, xmm1

	;------p(m_output)[i] +=  lpf_b0 * *(prev_vals) + lpf_b1 * *(prev_vals+1) - lpf_a2 * *(prev_vals+2) - lpf_a1 * *(prev_vals+3);
	;movdqu xmm5, [esi]	;xmm5 = *(prev_vals+3) |*(prev_vals+2) |*(prev_vals+1) | *(prev_vals)
	movdqu xmm5, xmm12	;xmm5 = 0 | 0 | *(prev_vals+3) |*(prev_vals+2)
	pslldq xmm5, 8		;xmm5 =  *(prev_vals+3) |*(prev_vals+2) | 0 | 0
	por xmm5, xmm11		;xmm5 = *(prev_vals+3) |*(prev_vals+2) |*(prev_vals+1) | *(prev_vals)

	mulps xmm5, xmm0	;xmm5 = *(pv+3)*ps3	   |*(pv+2)*ps2	   |*(pv+1)*ps1	   |*(pv)*ps0

	;---suma vertical
	movdqu xmm15, xmm5	;xmm15 = a | b | c | d
	psrldq xmm15, 8		;xmm15 = 0 | 0 | a | b
	addps xmm5, xmm15	;xmm5  = a | b | a+c | b+d
	movdqu xmm15, xmm5	;xmm15 = a | b | a+c | b+d
	psrldq xmm15, 4		;xmm15 = 0 | a | b   | a+c
	addps xmm5, xmm15	;xmm5 = basura | basura | basura |a+c+b+d

	; haddps xmm5, xmm5	;xmm5 = basura      | basura      |psuma3+psuma2|psuma1+psuma0
	; haddps xmm5, xmm5	;xmm5 = basura      | basura      | basura		|ps3+ps2+ps1+ps0

	addss xmm4, xmm5		;xmm4 = xmm4 * lpf_b0 + lpf_b0 * *(prev_vals) + lpf_b1 * *(prev_vals+1) - lpf_a2 * *(prev_vals+2) - lpf_a1 * *(prev_vals+3)

	;-------------fin operaciones sobre el output

	;----- vieja forma
	;------*prev_vals = *(prev_vals+1);
	; mov r12d, [esi+4]		;r12d = *(prev_vals + 1)
	; mov [esi], r12d		;*prev_vals = r12d

	; xmm11 = 0 | 0 |*(prev_vals+1) | *(prev_vals)
	;------*(prev_vals+1) = temp;
	; mov [esi+4], r13d		;*(prev_vals + 1) = r13d
	;----- vieja forma

	;----- todo de una
	pxor xmm15, xmm15		;xmm15 = 0
	movd xmm15, r13d		;xmm15 = 0 | 0 | 0 | r13d
	pslldq xmm15, 8			;xmm15 = 0 | r13d | 0 | 0
	por xmm11, xmm15		;xmm11 = 0 | r13d | *(prev_vals+1) | *(prev_vals) 
	psrldq xmm11, 4			;xmm11 = 0 | 0 | r13d | *(prev_vals+1)


	;----------------- peaking EQ (resonance) ----------------
	;-------float temp2 = p(m_output)[i];
	movd r13d, xmm4

    ;-------p(m_output)[i] *= peak_b0;
    mulss xmm4, xmm3	;xmm4 = xmm4 * factorsuma2

    ;-------p(m_output)[i] += peak_b2 * *(prev_vals+2) + peak_b1 * *(prev_vals+3) - peak_a2 * *(prev_vals+4) - peak_a1 * *(prev_vals+5);
    ;movdqu xmm5, [esi+8]	;xmm5 = *(prev_vals+5) |*(prev_vals+4) |*(prev_vals+3) | *(prev_vals2)
    movdqu xmm5, xmm13		;xmm5 = 0 | 0 | *(prev_vals+5) |*(prev_vals+4)
    pslldq xmm5, 8			;xmm5 = *(prev_vals+5) |*(prev_vals+4) | 0 | 0
    por xmm5, xmm12			;xmm5 = *(prev_vals+5) |*(prev_vals+4) |*(prev_vals+3) | *(prev_vals2)

    mulps xmm5, xmm2		;xmm5 = *(pv+5)*ss3	   |*(pv+4)*ss2	   |*(pv+3)*ss1	   |*(pv+2)*ss0

    ; ---suma vertical
	movdqu xmm15, xmm5	;xmm15 = a | b | c | d
	psrldq xmm15, 8		;xmm15 = 0 | 0 | a | b
	addps xmm5, xmm15	;xmm5  = a | b | a+c | b+d
	movdqu xmm15, xmm5	;xmm15 = a | b | a+c | b+d
	psrldq xmm15, 4		;xmm15 = 0 | a | b   | a+c
	addps xmm5, xmm15	;xmm5 = basura | basura | basura |a+c+b+d


	; haddps xmm5, xmm5	;xmm5 = basura      | basura      |ssuma3+ssuma2|ssuma1+ssuma0
	; haddps xmm5, xmm5	;xmm5 = basura      | basura      | basura		|ss3+ss2+ss1+ss0

	addss xmm4, xmm5		;xmm4 = xmm4 * peak_b0 + peak_b2 * *(prev_vals+2) + peak_b1 * *(prev_vals+3) - peak_a2 * *(prev_vals+4) - peak_a1 * *(prev_vals+5);

	;------------------ fin operaciones sobre el output

	;----- vieja forma
    ;-------*(prev_vals+2) = *(prev_vals+3);
    ; mov r12d, [esi+12]		;r12d = *(prev_vals+3)
    ; mov [esi+8], r12d		;*(prev_vals+2) = r12d

    ;-------*(prev_vals+3) = temp2;
	; mov [esi+12], r13d		;*(prev_vals+3) = r13d
	;----- vieja forma

	;-------todo de una
	pxor xmm15, xmm15		;xmm15 = 0
	movd xmm15, r13d		;xmm15 = 0 | 0 | 0 | r13d
	pslldq xmm15, 8			;xmm15 = 0 | r13d | 0 | 0
	por xmm12, xmm15		;xmm12 = 0 | r13d | *(prev_vals+3) | *(prev_vals+2)
	psrldq xmm12, 4			;xmm12 = 0 | 0 | r13d | *(prev_vals+3)


	;-------vieja forma
    ;-------*(prev_vals+4) = *(prev_vals+5);
    ; mov r12d, [esi+20]		;r12d = *(prev_vals+5)
    ; mov [esi+16], r12d		;*(prev_vals+4) = r12d

    ;-------*(prev_vals+5) = p(m_output)[i];
    ; movd [esi+20], xmm4
    ;-------vieja forma

    ;-------todo de una
    pxor xmm15, xmm15		;xmm15 = 0
    movd r12d, xmm4
    movd xmm15, r12d		;xmm15 = 0 | 0 | 0 | output
    pslldq xmm15, 8			;xmm15 = 0 | output | 0 | 0
    por xmm13, xmm15		;xmm13 = 0 | output | *(prev_vals+5) | *(prev_vals+4)
    psrldq xmm13, 4			;xmm13 = 0 | 0 | output| *(prev_vals+5) 


    movdqu xmm15, xmm4		;meto xmm4 en el dw mas alto de xmm15
    pslldq xmm15, 12		;xmm15 = res | 0 | 0 | 0
    orps xmm8, xmm15

    psrldq xmm9, 4			;shifteo 1 dw a la derecha, para usar el siguiente dato. la segunda entrada pasa a ser la primera
    movdqu xmm4, xmm9		;copio toda la entrada a xmm4
	pand xmm4, xmm7		;limpio la parte superior. solo queda la primer entrada


    inc r11d
    
    ;--------------------------------------------- 
	;---------- fin ciclo 3 ----------------------
	;--------------------------------------------- 

    ;----- copio xmm8 a la direccion del buffer
    movdqu [r14], xmm8


	;---incrementaciones
	add ebx, 4					;incremento el contador i, en 4
	jmp .cicloGrande
	.finGrande:

	;-----guardo el prev_vals modificado
	pslldq xmm12, 8
	por xmm12, xmm11
	movdqu [rsi], xmm12
	movq [rsi+16], xmm13
	;---

	pop r14
	pop r13
	pop r12
	pop rbx
	pop rbp
ret

;versión con sumas verticales
equalizerf:
	push rbp
	mov rbp, rsp
	push rbx		;rbx es i
	push r12		;r12 es aux
	push r13		;r13d es temp
	push r14		;r14d es la posicion del buffer


	;---------- seteo constantes------------

	;------ limpio bits superiores ---
	pxor xmm10, xmm10	; xmm10 es 0
	mov r12d, 0xFFFFFFFF
	movd xmm10, r12d		; xmm10 tiene un dw de unos, el resto 0

	;desplazo todos un xmm a la derecha - pequeño parche porque estaba mal la calling convention
	movdqu xmm8, xmm7
	movdqu xmm7, xmm6
	movdqu xmm6, xmm5
	movdqu xmm5, xmm4
	movdqu xmm4, xmm3
	movdqu xmm3, xmm2
	movdqu xmm2, xmm1
	
	movdqu xmm1, xmm0		;en xmm0 tendré lo mismo que en el 1
	mulss xmm1, [rel unDos]	;lo multiplico por dos, porque float psuma1 = psuma0 *2;

	; pand xmm0, xmm10	; filtro todo lo que no sea el primer float - todo sacar, no hace falta
	; pand xmm1, xmm10	; filtro todo lo que no sea el primer float
	; pand xmm2, xmm10	; filtro todo lo que no sea el primer float
	; pand xmm3, xmm10	; filtro todo lo que no sea el primer float
	; pand xmm4, xmm10	; filtro todo lo que no sea el primer float
	; pand xmm5, xmm10	; filtro todo lo que no sea el primer float
	; pand xmm6, xmm10	; filtro todo lo que no sea el primer float
	; pand xmm7, xmm10	; filtro todo lo que no sea el primer float
	; pand xmm8, xmm10	; filtro todo lo que no sea el primer float
	;----------------.
	;-----------------


	movdqu xmm9, xmm0		;xmm9 = factorsuma1

	;primersuma
						;xmm0	= 0 | 0 | 0 | primersuma0
	pslldq xmm1, 4		;xmm1	= 0 | 0 | primersuma1 | 0
	pslldq xmm2, 8		;xmm2	= 0 | primersuma2 | 0 | 0
	pslldq xmm3, 12		;xmm3	= primersuma3 | 0 | 0 | 0

	orps xmm0, xmm1
	orps xmm2, xmm3
	orps xmm0, xmm2		;xmm0 = primersuma3 | primersuma2 | primersuma1 | primersuma0
	;acá tengo las constantes de la primer suma en horizontal


	;segundasuma
						;xmm4	= 0 | 0 | 0 | segundasuma0
	pslldq xmm5, 4		;xmm5	= 0 | 0 | segundasuma1 | 0
	pslldq xmm6, 8		;xmm6	= 0 | segundasuma2 | 0 | 0
	pslldq xmm7, 12		;xmm7	= segundasuma3 | 0 | 0 | 0

	orps xmm4, xmm5
	orps xmm6, xmm7
	orps xmm4, xmm6		;xmm4 = segundasuma3 | segundasuma2 | segundasuma1 | segundasuma0

	;acá tengo las constantes de la segunda suma en horizontal
	
	movdqu xmm1, xmm9
	movdqu xmm3, xmm8
	movdqu xmm2, xmm4

	
	movdqu xmm7, xmm10	;xmm7 tiene un dw de unos
	movdqu xmm15, xmm10 ;xmm15 = 0 | 0 | 0 | unos
	pslldq xmm15, 4		;xmm15 = 0 | 0 | unos | 0
	por xmm10, xmm15	;xmm10 tiene un qw de unos

	;ctes:
	; xmm0: primersuma
	; xmm1: factorsuma1
	; xmm2: segundasuma
	; xmm3: factorsuma2	
	; xmm10: un qw de unos
	; xmm7: un dw de unos

	;------- fin constantes ------------------ 

	;------- levanto prev_vals
	movdqu xmm11, [rdi] ; xmm11 = *(prev_vals+3) |*(prev_vals+2) |*(prev_vals+1) | *(prev_vals)
	movdqu xmm12, xmm11	; xmm12 = *(prev_vals+3) |*(prev_vals+2) |*(prev_vals+1) | *(prev_vals)
	psrldq xmm12, 8		; xmm12 = 0 | 0 | *(prev_vals+3) | *(prev_vals+2)

	pand xmm11, xmm10 	; xmm11 = 0 | 0 |*(prev_vals+1) | *(prev_vals)



	movq xmm13, [rdi + 16]	;xmm13 = basura | basura | *(prev_vals+5) |*(prev_vals+4)
	pand xmm13, xmm10	; xmm13 = 0 | 0 | *(prev_vals+5) |*(prev_vals+4)


	;------- arranca el ciclo grande ----------------
	xor rbx, rbx		; i empieza en 0
	.cicloGrande:
	cmp edx, ebx		;si i es sample_count, termino
	jae .finGrande

	mov r14, rbx
	sal r14, 2		;multiplico por 4
	;imul r14d, 4
	add r14, rdi	;r14d es la posicion a escribir del buffer	 - TODO - mejorar con un lea
	; lea r14d, [rbx*4 + rdi]		- con el lea termino dando peor - creo que es porque hago un acceso ahi abajo, y ambos usan el bus de direcciones

	movdqu xmm9, [r14]		;levanto *buffer + i a xmm9. xmm9 va a tener TODA la entrada
	movdqu xmm4, xmm9		;copio toda la entrada a xmm4
	pand xmm4, xmm7		;limpio la parte superior. solo queda la primer entrada

	pxor xmm8, xmm8			;xmm8 va a tener toda la salida

	;------ arrancan los ciclos chicos -------------

	;---------------------------------------------
	;---------- inicio ciclo 0 -------------------
	;---------------------------------------------


	psrldq xmm8, 4			;shifteo 4 bytes, para correr los resultados anteriores hacia la derecha (los primeros van en los bits mas bajos)


	;---------- low-pass filter-------------------

	;------float temp = p(m_output)[i];
	movd r13d, xmm4

	;------p(m_output)[i] *= lpf_b0;
	mulss xmm4, xmm1

	;------p(m_output)[i] +=  lpf_b0 * *(prev_vals) + lpf_b1 * *(prev_vals+1) - lpf_a2 * *(prev_vals+2) - lpf_a1 * *(prev_vals+3);
	;movdqu xmm5, [esi]	;xmm5 = *(prev_vals+3) |*(prev_vals+2) |*(prev_vals+1) | *(prev_vals)
	movdqu xmm5, xmm12	;xmm5 = 0 | 0 | *(prev_vals+3) |*(prev_vals+2)
	pslldq xmm5, 8		;xmm5 =  *(prev_vals+3) |*(prev_vals+2) | 0 | 0
	por xmm5, xmm11		;xmm5 = *(prev_vals+3) |*(prev_vals+2) |*(prev_vals+1) | *(prev_vals)

	mulps xmm5, xmm0	;xmm5 = *(pv+3)*ps3	   |*(pv+2)*ps2	   |*(pv+1)*ps1	   |*(pv)*ps0


    ; ---suma vertical
	movdqu xmm15, xmm5	;xmm15 = a | b | c | d
	psrldq xmm15, 8		;xmm15 = 0 | 0 | a | b
	addps xmm5, xmm15	;xmm5  = a | b | a+c | b+d
	movdqu xmm15, xmm5	;xmm15 = a | b | a+c | b+d
	psrldq xmm15, 4		;xmm15 = 0 | a | b   | a+c
	addps xmm5, xmm15	;xmm5 = basura | basura | basura |a+c+b+d


	; haddps xmm5, xmm5	;xmm5 = basura      | basura      |psuma3+psuma2|psuma1+psuma0
	; haddps xmm5, xmm5	;xmm5 = basura      | basura      | basura		|ps3+ps2+ps1+ps0

	addss xmm4, xmm5		;xmm4 = xmm4 * lpf_b0 + lpf_b0 * *(prev_vals) + lpf_b1 * *(prev_vals+1) - lpf_a2 * *(prev_vals+2) - lpf_a1 * *(prev_vals+3)

	;-------------fin operaciones sobre el output

	;----- vieja forma
	;------*prev_vals = *(prev_vals+1);
	; mov r12d, [esi+4]		;r12d = *(prev_vals + 1)
	; mov [esi], r12d		;*prev_vals = r12d

	; xmm11 = 0 | 0 |*(prev_vals+1) | *(prev_vals)
	;------*(prev_vals+1) = temp;
	; mov [esi+4], r13d		;*(prev_vals + 1) = r13d
	;----- vieja forma

	;----- todo de una
	pxor xmm15, xmm15		;xmm15 = 0
	movd xmm15, r13d		;xmm15 = 0 | 0 | 0 | r13d
	pslldq xmm15, 8			;xmm15 = 0 | r13d | 0 | 0
	por xmm11, xmm15		;xmm11 = 0 | r13d | *(prev_vals+1) | *(prev_vals) 
	psrldq xmm11, 4			;xmm11 = 0 | 0 | r13d | *(prev_vals+1)


	;----------------- peaking EQ (resonance) ----------------
	;-------float temp2 = p(m_output)[i];
	movd r13d, xmm4

    ;-------p(m_output)[i] *= peak_b0;
    mulss xmm4, xmm3	;xmm4 = xmm4 * factorsuma2

    ;-------p(m_output)[i] += peak_b2 * *(prev_vals+2) + peak_b1 * *(prev_vals+3) - peak_a2 * *(prev_vals+4) - peak_a1 * *(prev_vals+5);
    ;movdqu xmm5, [esi+8]	;xmm5 = *(prev_vals+5) |*(prev_vals+4) |*(prev_vals+3) | *(prev_vals2)
    movdqu xmm5, xmm13		;xmm5 = 0 | 0 | *(prev_vals+5) |*(prev_vals+4)
    pslldq xmm5, 8			;xmm5 = *(prev_vals+5) |*(prev_vals+4) | 0 | 0
    por xmm5, xmm12			;xmm5 = *(prev_vals+5) |*(prev_vals+4) |*(prev_vals+3) | *(prev_vals2)

    mulps xmm5, xmm2		;xmm5 = *(pv+5)*ss3	   |*(pv+4)*ss2	   |*(pv+3)*ss1	   |*(pv+2)*ss0

    ; ---suma vertical
	movdqu xmm15, xmm5	;xmm15 = a | b | c | d
	psrldq xmm15, 8		;xmm15 = 0 | 0 | a | b
	addps xmm5, xmm15	;xmm5  = a | b | a+c | b+d
	movdqu xmm15, xmm5	;xmm15 = a | b | a+c | b+d
	psrldq xmm15, 4		;xmm15 = 0 | a | b   | a+c
	addps xmm5, xmm15	;xmm5 = basura | basura | basura |a+c+b+d


	; haddps xmm5, xmm5	;xmm5 = basura      | basura      |ssuma3+ssuma2|ssuma1+ssuma0
	; haddps xmm5, xmm5	;xmm5 = basura      | basura      | basura		|ss3+ss2+ss1+ss0

	addss xmm4, xmm5		;xmm4 = xmm4 * peak_b0 + peak_b2 * *(prev_vals+2) + peak_b1 * *(prev_vals+3) - peak_a2 * *(prev_vals+4) - peak_a1 * *(prev_vals+5);

	;------------------ fin operaciones sobre el output

	;----- vieja forma
    ;-------*(prev_vals+2) = *(prev_vals+3);
    ; mov r12d, [esi+12]		;r12d = *(prev_vals+3)
    ; mov [esi+8], r12d		;*(prev_vals+2) = r12d

    ;-------*(prev_vals+3) = temp2;
	; mov [esi+12], r13d		;*(prev_vals+3) = r13d
	;----- vieja forma

	;-------todo de una
	pxor xmm15, xmm15		;xmm15 = 0
	movd xmm15, r13d		;xmm15 = 0 | 0 | 0 | r13d
	pslldq xmm15, 8			;xmm15 = 0 | r13d | 0 | 0
	por xmm12, xmm15		;xmm12 = 0 | r13d | *(prev_vals+3) | *(prev_vals+2)
	psrldq xmm12, 4			;xmm12 = 0 | 0 | r13d | *(prev_vals+3)


	;-------vieja forma
    ;-------*(prev_vals+4) = *(prev_vals+5);
    ; mov r12d, [esi+20]		;r12d = *(prev_vals+5)
    ; mov [esi+16], r12d		;*(prev_vals+4) = r12d

    ;-------*(prev_vals+5) = p(m_output)[i];
    ; movd [esi+20], xmm4
    ;-------vieja forma

    ;-------todo de una
    pxor xmm15, xmm15		;xmm15 = 0
    movd r12d, xmm4
    movd xmm15, r12d		;xmm15 = 0 | 0 | 0 | output
    pslldq xmm15, 8			;xmm15 = 0 | output | 0 | 0
    por xmm13, xmm15		;xmm13 = 0 | output | *(prev_vals+5) | *(prev_vals+4)
    psrldq xmm13, 4			;xmm13 = 0 | 0 | output| *(prev_vals+5) 


    movdqu xmm15, xmm4		;meto xmm4 en el dw mas alto de xmm15
    pslldq xmm15, 12		;xmm15 = res | 0 | 0 | 0
    orps xmm8, xmm15

    psrldq xmm9, 4			;shifteo 1 dw a la derecha, para usar el siguiente dato. la segunda entrada pasa a ser la primera
    movdqu xmm4, xmm9		;copio toda la entrada a xmm4
	pand xmm4, xmm7		;limpio la parte superior. solo queda la primer entrada


    ;---------------------------------------------
	;---------- fin ciclo 0 ----------------------
	;---------------------------------------------


	;---------------------------------------------
	;---------- inicio ciclo 1 -------------------
	;---------------------------------------------


	psrldq xmm8, 4			;shifteo 4 bytes, para correr los resultados anteriores hacia la derecha (los primeros van en los bits mas bajos)


	;---------- low-pass filter-------------------

	;------float temp = p(m_output)[i];
	movd r13d, xmm4

	;------p(m_output)[i] *= lpf_b0;
	mulss xmm4, xmm1

	;------p(m_output)[i] +=  lpf_b0 * *(prev_vals) + lpf_b1 * *(prev_vals+1) - lpf_a2 * *(prev_vals+2) - lpf_a1 * *(prev_vals+3);
	;movdqu xmm5, [esi]	;xmm5 = *(prev_vals+3) |*(prev_vals+2) |*(prev_vals+1) | *(prev_vals)
	movdqu xmm5, xmm12	;xmm5 = 0 | 0 | *(prev_vals+3) |*(prev_vals+2)
	pslldq xmm5, 8		;xmm5 =  *(prev_vals+3) |*(prev_vals+2) | 0 | 0
	por xmm5, xmm11		;xmm5 = *(prev_vals+3) |*(prev_vals+2) |*(prev_vals+1) | *(prev_vals)

	mulps xmm5, xmm0	;xmm5 = *(pv+3)*ps3	   |*(pv+2)*ps2	   |*(pv+1)*ps1	   |*(pv)*ps0


    ; ---suma vertical
	movdqu xmm15, xmm5	;xmm15 = a | b | c | d
	psrldq xmm15, 8		;xmm15 = 0 | 0 | a | b
	addps xmm5, xmm15	;xmm5  = a | b | a+c | b+d
	movdqu xmm15, xmm5	;xmm15 = a | b | a+c | b+d
	psrldq xmm15, 4		;xmm15 = 0 | a | b   | a+c
	addps xmm5, xmm15	;xmm5 = basura | basura | basura |a+c+b+d


	; haddps xmm5, xmm5	;xmm5 = basura      | basura      |psuma3+psuma2|psuma1+psuma0
	; haddps xmm5, xmm5	;xmm5 = basura      | basura      | basura		|ps3+ps2+ps1+ps0

	addss xmm4, xmm5		;xmm4 = xmm4 * lpf_b0 + lpf_b0 * *(prev_vals) + lpf_b1 * *(prev_vals+1) - lpf_a2 * *(prev_vals+2) - lpf_a1 * *(prev_vals+3)

	;-------------fin operaciones sobre el output

	;----- vieja forma
	;------*prev_vals = *(prev_vals+1);
	; mov r12d, [esi+4]		;r12d = *(prev_vals + 1)
	; mov [esi], r12d		;*prev_vals = r12d

	; xmm11 = 0 | 0 |*(prev_vals+1) | *(prev_vals)
	;------*(prev_vals+1) = temp;
	; mov [esi+4], r13d		;*(prev_vals + 1) = r13d
	;----- vieja forma

	;----- todo de una
	pxor xmm15, xmm15		;xmm15 = 0
	movd xmm15, r13d		;xmm15 = 0 | 0 | 0 | r13d
	pslldq xmm15, 8			;xmm15 = 0 | r13d | 0 | 0
	por xmm11, xmm15		;xmm11 = 0 | r13d | *(prev_vals+1) | *(prev_vals) 
	psrldq xmm11, 4			;xmm11 = 0 | 0 | r13d | *(prev_vals+1)


	;----------------- peaking EQ (resonance) ----------------
	;-------float temp2 = p(m_output)[i];
	movd r13d, xmm4

    ;-------p(m_output)[i] *= peak_b0;
    mulss xmm4, xmm3	;xmm4 = xmm4 * factorsuma2

    ;-------p(m_output)[i] += peak_b2 * *(prev_vals+2) + peak_b1 * *(prev_vals+3) - peak_a2 * *(prev_vals+4) - peak_a1 * *(prev_vals+5);
    ;movdqu xmm5, [esi+8]	;xmm5 = *(prev_vals+5) |*(prev_vals+4) |*(prev_vals+3) | *(prev_vals2)
    movdqu xmm5, xmm13		;xmm5 = 0 | 0 | *(prev_vals+5) |*(prev_vals+4)
    pslldq xmm5, 8			;xmm5 = *(prev_vals+5) |*(prev_vals+4) | 0 | 0
    por xmm5, xmm12			;xmm5 = *(prev_vals+5) |*(prev_vals+4) |*(prev_vals+3) | *(prev_vals2)

    mulps xmm5, xmm2		;xmm5 = *(pv+5)*ss3	   |*(pv+4)*ss2	   |*(pv+3)*ss1	   |*(pv+2)*ss0

    ; ---suma vertical
	movdqu xmm15, xmm5	;xmm15 = a | b | c | d
	psrldq xmm15, 8		;xmm15 = 0 | 0 | a | b
	addps xmm5, xmm15	;xmm5  = a | b | a+c | b+d
	movdqu xmm15, xmm5	;xmm15 = a | b | a+c | b+d
	psrldq xmm15, 4		;xmm15 = 0 | a | b   | a+c
	addps xmm5, xmm15	;xmm5 = basura | basura | basura |a+c+b+d


	; haddps xmm5, xmm5	;xmm5 = basura      | basura      |ssuma3+ssuma2|ssuma1+ssuma0
	; haddps xmm5, xmm5	;xmm5 = basura      | basura      | basura		|ss3+ss2+ss1+ss0

	addss xmm4, xmm5		;xmm4 = xmm4 * peak_b0 + peak_b2 * *(prev_vals+2) + peak_b1 * *(prev_vals+3) - peak_a2 * *(prev_vals+4) - peak_a1 * *(prev_vals+5);

	;------------------ fin operaciones sobre el output

	;----- vieja forma
    ;-------*(prev_vals+2) = *(prev_vals+3);
    ; mov r12d, [esi+12]		;r12d = *(prev_vals+3)
    ; mov [esi+8], r12d		;*(prev_vals+2) = r12d

    ;-------*(prev_vals+3) = temp2;
	; mov [esi+12], r13d		;*(prev_vals+3) = r13d
	;----- vieja forma

	;-------todo de una
	pxor xmm15, xmm15		;xmm15 = 0
	movd xmm15, r13d		;xmm15 = 0 | 0 | 0 | r13d
	pslldq xmm15, 8			;xmm15 = 0 | r13d | 0 | 0
	por xmm12, xmm15		;xmm12 = 0 | r13d | *(prev_vals+3) | *(prev_vals+2)
	psrldq xmm12, 4			;xmm12 = 0 | 0 | r13d | *(prev_vals+3)


	;-------vieja forma
    ;-------*(prev_vals+4) = *(prev_vals+5);
    ; mov r12d, [esi+20]		;r12d = *(prev_vals+5)
    ; mov [esi+16], r12d		;*(prev_vals+4) = r12d

    ;-------*(prev_vals+5) = p(m_output)[i];
    ; movd [esi+20], xmm4
    ;-------vieja forma

    ;-------todo de una
    pxor xmm15, xmm15		;xmm15 = 0
    movd r12d, xmm4
    movd xmm15, r12d		;xmm15 = 0 | 0 | 0 | output
    pslldq xmm15, 8			;xmm15 = 0 | output | 0 | 0
    por xmm13, xmm15		;xmm13 = 0 | output | *(prev_vals+5) | *(prev_vals+4)
    psrldq xmm13, 4			;xmm13 = 0 | 0 | output| *(prev_vals+5) 


    movdqu xmm15, xmm4		;meto xmm4 en el dw mas alto de xmm15
    pslldq xmm15, 12		;xmm15 = res | 0 | 0 | 0
    orps xmm8, xmm15

    psrldq xmm9, 4			;shifteo 1 dw a la derecha, para usar el siguiente dato. la segunda entrada pasa a ser la primera
    movdqu xmm4, xmm9		;copio toda la entrada a xmm4
	pand xmm4, xmm7		;limpio la parte superior. solo queda la primer entrada


    ;---------------------------------------------
	;---------- fin ciclo 1 ----------------------
	;---------------------------------------------

	;---------------------------------------------
	;---------- inicio ciclo 2 -------------------
	;---------------------------------------------


	psrldq xmm8, 4			;shifteo 4 bytes, para correr los resultados anteriores hacia la derecha (los primeros van en los bits mas bajos)


	;---------- low-pass filter-------------------

	;------float temp = p(m_output)[i];
	movd r13d, xmm4

	;------p(m_output)[i] *= lpf_b0;
	mulss xmm4, xmm1

	;------p(m_output)[i] +=  lpf_b0 * *(prev_vals) + lpf_b1 * *(prev_vals+1) - lpf_a2 * *(prev_vals+2) - lpf_a1 * *(prev_vals+3);
	;movdqu xmm5, [esi]	;xmm5 = *(prev_vals+3) |*(prev_vals+2) |*(prev_vals+1) | *(prev_vals)
	movdqu xmm5, xmm12	;xmm5 = 0 | 0 | *(prev_vals+3) |*(prev_vals+2)
	pslldq xmm5, 8		;xmm5 =  *(prev_vals+3) |*(prev_vals+2) | 0 | 0
	por xmm5, xmm11		;xmm5 = *(prev_vals+3) |*(prev_vals+2) |*(prev_vals+1) | *(prev_vals)

	mulps xmm5, xmm0	;xmm5 = *(pv+3)*ps3	   |*(pv+2)*ps2	   |*(pv+1)*ps1	   |*(pv)*ps0


    ; ---suma vertical
	movdqu xmm15, xmm5	;xmm15 = a | b | c | d
	psrldq xmm15, 8		;xmm15 = 0 | 0 | a | b
	addps xmm5, xmm15	;xmm5  = a | b | a+c | b+d
	movdqu xmm15, xmm5	;xmm15 = a | b | a+c | b+d
	psrldq xmm15, 4		;xmm15 = 0 | a | b   | a+c
	addps xmm5, xmm15	;xmm5 = basura | basura | basura |a+c+b+d


	; haddps xmm5, xmm5	;xmm5 = basura      | basura      |psuma3+psuma2|psuma1+psuma0
	; haddps xmm5, xmm5	;xmm5 = basura      | basura      | basura		|ps3+ps2+ps1+ps0

	addss xmm4, xmm5		;xmm4 = xmm4 * lpf_b0 + lpf_b0 * *(prev_vals) + lpf_b1 * *(prev_vals+1) - lpf_a2 * *(prev_vals+2) - lpf_a1 * *(prev_vals+3)

	;-------------fin operaciones sobre el output

	;----- vieja forma
	;------*prev_vals = *(prev_vals+1);
	; mov r12d, [esi+4]		;r12d = *(prev_vals + 1)
	; mov [esi], r12d		;*prev_vals = r12d

	; xmm11 = 0 | 0 |*(prev_vals+1) | *(prev_vals)
	;------*(prev_vals+1) = temp;
	; mov [esi+4], r13d		;*(prev_vals + 1) = r13d
	;----- vieja forma

	;----- todo de una
	pxor xmm15, xmm15		;xmm15 = 0
	movd xmm15, r13d		;xmm15 = 0 | 0 | 0 | r13d
	pslldq xmm15, 8			;xmm15 = 0 | r13d | 0 | 0
	por xmm11, xmm15		;xmm11 = 0 | r13d | *(prev_vals+1) | *(prev_vals) 
	psrldq xmm11, 4			;xmm11 = 0 | 0 | r13d | *(prev_vals+1)


	;----------------- peaking EQ (resonance) ----------------
	;-------float temp2 = p(m_output)[i];
	movd r13d, xmm4

    ;-------p(m_output)[i] *= peak_b0;
    mulss xmm4, xmm3	;xmm4 = xmm4 * factorsuma2

    ;-------p(m_output)[i] += peak_b2 * *(prev_vals+2) + peak_b1 * *(prev_vals+3) - peak_a2 * *(prev_vals+4) - peak_a1 * *(prev_vals+5);
    ;movdqu xmm5, [esi+8]	;xmm5 = *(prev_vals+5) |*(prev_vals+4) |*(prev_vals+3) | *(prev_vals2)
    movdqu xmm5, xmm13		;xmm5 = 0 | 0 | *(prev_vals+5) |*(prev_vals+4)
    pslldq xmm5, 8			;xmm5 = *(prev_vals+5) |*(prev_vals+4) | 0 | 0
    por xmm5, xmm12			;xmm5 = *(prev_vals+5) |*(prev_vals+4) |*(prev_vals+3) | *(prev_vals2)

    mulps xmm5, xmm2		;xmm5 = *(pv+5)*ss3	   |*(pv+4)*ss2	   |*(pv+3)*ss1	   |*(pv+2)*ss0

    ; ---suma vertical
	movdqu xmm15, xmm5	;xmm15 = a | b | c | d
	psrldq xmm15, 8		;xmm15 = 0 | 0 | a | b
	addps xmm5, xmm15	;xmm5  = a | b | a+c | b+d
	movdqu xmm15, xmm5	;xmm15 = a | b | a+c | b+d
	psrldq xmm15, 4		;xmm15 = 0 | a | b   | a+c
	addps xmm5, xmm15	;xmm5 = basura | basura | basura |a+c+b+d


	; haddps xmm5, xmm5	;xmm5 = basura      | basura      |ssuma3+ssuma2|ssuma1+ssuma0
	; haddps xmm5, xmm5	;xmm5 = basura      | basura      | basura		|ss3+ss2+ss1+ss0

	addss xmm4, xmm5		;xmm4 = xmm4 * peak_b0 + peak_b2 * *(prev_vals+2) + peak_b1 * *(prev_vals+3) - peak_a2 * *(prev_vals+4) - peak_a1 * *(prev_vals+5);

	;------------------ fin operaciones sobre el output

	;----- vieja forma
    ;-------*(prev_vals+2) = *(prev_vals+3);
    ; mov r12d, [esi+12]		;r12d = *(prev_vals+3)
    ; mov [esi+8], r12d		;*(prev_vals+2) = r12d

    ;-------*(prev_vals+3) = temp2;
	; mov [esi+12], r13d		;*(prev_vals+3) = r13d
	;----- vieja forma

	;-------todo de una
	pxor xmm15, xmm15		;xmm15 = 0
	movd xmm15, r13d		;xmm15 = 0 | 0 | 0 | r13d
	pslldq xmm15, 8			;xmm15 = 0 | r13d | 0 | 0
	por xmm12, xmm15		;xmm12 = 0 | r13d | *(prev_vals+3) | *(prev_vals+2)
	psrldq xmm12, 4			;xmm12 = 0 | 0 | r13d | *(prev_vals+3)


	;-------vieja forma
    ;-------*(prev_vals+4) = *(prev_vals+5);
    ; mov r12d, [esi+20]		;r12d = *(prev_vals+5)
    ; mov [esi+16], r12d		;*(prev_vals+4) = r12d

    ;-------*(prev_vals+5) = p(m_output)[i];
    ; movd [esi+20], xmm4
    ;-------vieja forma

    ;-------todo de una
    pxor xmm15, xmm15		;xmm15 = 0
    movd r12d, xmm4
    movd xmm15, r12d		;xmm15 = 0 | 0 | 0 | output
    pslldq xmm15, 8			;xmm15 = 0 | output | 0 | 0
    por xmm13, xmm15		;xmm13 = 0 | output | *(prev_vals+5) | *(prev_vals+4)
    psrldq xmm13, 4			;xmm13 = 0 | 0 | output| *(prev_vals+5) 


    movdqu xmm15, xmm4		;meto xmm4 en el dw mas alto de xmm15
    pslldq xmm15, 12		;xmm15 = res | 0 | 0 | 0
    orps xmm8, xmm15

    psrldq xmm9, 4			;shifteo 1 dw a la derecha, para usar el siguiente dato. la segunda entrada pasa a ser la primera
    movdqu xmm4, xmm9		;copio toda la entrada a xmm4
	pand xmm4, xmm7		;limpio la parte superior. solo queda la primer entrada


    ;---------------------------------------------
	;---------- fin ciclo 2 ----------------------
	;---------------------------------------------


	;---------------------------------------------
	;---------- inicio ciclo 3 -------------------
	;---------------------------------------------


	psrldq xmm8, 4			;shifteo 4 bytes, para correr los resultados anteriores hacia la derecha (los primeros van en los bits mas bajos)


	;---------- low-pass filter-------------------

	;------float temp = p(m_output)[i];
	movd r13d, xmm4

	;------p(m_output)[i] *= lpf_b0;
	mulss xmm4, xmm1

	;------p(m_output)[i] +=  lpf_b0 * *(prev_vals) + lpf_b1 * *(prev_vals+1) - lpf_a2 * *(prev_vals+2) - lpf_a1 * *(prev_vals+3);
	;movdqu xmm5, [esi]	;xmm5 = *(prev_vals+3) |*(prev_vals+2) |*(prev_vals+1) | *(prev_vals)
	movdqu xmm5, xmm12	;xmm5 = 0 | 0 | *(prev_vals+3) |*(prev_vals+2)
	pslldq xmm5, 8		;xmm5 =  *(prev_vals+3) |*(prev_vals+2) | 0 | 0
	por xmm5, xmm11		;xmm5 = *(prev_vals+3) |*(prev_vals+2) |*(prev_vals+1) | *(prev_vals)

	mulps xmm5, xmm0	;xmm5 = *(pv+3)*ps3	   |*(pv+2)*ps2	   |*(pv+1)*ps1	   |*(pv)*ps0


    ; ---suma vertical
	movdqu xmm15, xmm5	;xmm15 = a | b | c | d
	psrldq xmm15, 8		;xmm15 = 0 | 0 | a | b
	addps xmm5, xmm15	;xmm5  = a | b | a+c | b+d
	movdqu xmm15, xmm5	;xmm15 = a | b | a+c | b+d
	psrldq xmm15, 4		;xmm15 = 0 | a | b   | a+c
	addps xmm5, xmm15	;xmm5 = basura | basura | basura |a+c+b+d


	; haddps xmm5, xmm5	;xmm5 = basura      | basura      |psuma3+psuma2|psuma1+psuma0
	; haddps xmm5, xmm5	;xmm5 = basura      | basura      | basura		|ps3+ps2+ps1+ps0

	addss xmm4, xmm5		;xmm4 = xmm4 * lpf_b0 + lpf_b0 * *(prev_vals) + lpf_b1 * *(prev_vals+1) - lpf_a2 * *(prev_vals+2) - lpf_a1 * *(prev_vals+3)

	;-------------fin operaciones sobre el output

	;----- vieja forma
	;------*prev_vals = *(prev_vals+1);
	; mov r12d, [esi+4]		;r12d = *(prev_vals + 1)
	; mov [esi], r12d		;*prev_vals = r12d

	; xmm11 = 0 | 0 |*(prev_vals+1) | *(prev_vals)
	;------*(prev_vals+1) = temp;
	; mov [esi+4], r13d		;*(prev_vals + 1) = r13d
	;----- vieja forma

	;----- todo de una
	pxor xmm15, xmm15		;xmm15 = 0
	movd xmm15, r13d		;xmm15 = 0 | 0 | 0 | r13d
	pslldq xmm15, 8			;xmm15 = 0 | r13d | 0 | 0
	por xmm11, xmm15		;xmm11 = 0 | r13d | *(prev_vals+1) | *(prev_vals) 
	psrldq xmm11, 4			;xmm11 = 0 | 0 | r13d | *(prev_vals+1)


	;----------------- peaking EQ (resonance) ----------------
	;-------float temp2 = p(m_output)[i];
	movd r13d, xmm4

    ;-------p(m_output)[i] *= peak_b0;
    mulss xmm4, xmm3	;xmm4 = xmm4 * factorsuma2

    ;-------p(m_output)[i] += peak_b2 * *(prev_vals+2) + peak_b1 * *(prev_vals+3) - peak_a2 * *(prev_vals+4) - peak_a1 * *(prev_vals+5);
    ;movdqu xmm5, [esi+8]	;xmm5 = *(prev_vals+5) |*(prev_vals+4) |*(prev_vals+3) | *(prev_vals2)
    movdqu xmm5, xmm13		;xmm5 = 0 | 0 | *(prev_vals+5) |*(prev_vals+4)
    pslldq xmm5, 8			;xmm5 = *(prev_vals+5) |*(prev_vals+4) | 0 | 0
    por xmm5, xmm12			;xmm5 = *(prev_vals+5) |*(prev_vals+4) |*(prev_vals+3) | *(prev_vals2)

    mulps xmm5, xmm2		;xmm5 = *(pv+5)*ss3	   |*(pv+4)*ss2	   |*(pv+3)*ss1	   |*(pv+2)*ss0

    ; ---suma vertical
	movdqu xmm15, xmm5	;xmm15 = a | b | c | d
	psrldq xmm15, 8		;xmm15 = 0 | 0 | a | b
	addps xmm5, xmm15	;xmm5  = a | b | a+c | b+d
	movdqu xmm15, xmm5	;xmm15 = a | b | a+c | b+d
	psrldq xmm15, 4		;xmm15 = 0 | a | b   | a+c
	addps xmm5, xmm15	;xmm5 = basura | basura | basura |a+c+b+d


	; haddps xmm5, xmm5	;xmm5 = basura      | basura      |ssuma3+ssuma2|ssuma1+ssuma0
	; haddps xmm5, xmm5	;xmm5 = basura      | basura      | basura		|ss3+ss2+ss1+ss0

	addss xmm4, xmm5		;xmm4 = xmm4 * peak_b0 + peak_b2 * *(prev_vals+2) + peak_b1 * *(prev_vals+3) - peak_a2 * *(prev_vals+4) - peak_a1 * *(prev_vals+5);

	;------------------ fin operaciones sobre el output

	;----- vieja forma
    ;-------*(prev_vals+2) = *(prev_vals+3);
    ; mov r12d, [esi+12]		;r12d = *(prev_vals+3)
    ; mov [esi+8], r12d		;*(prev_vals+2) = r12d

    ;-------*(prev_vals+3) = temp2;
	; mov [esi+12], r13d		;*(prev_vals+3) = r13d
	;----- vieja forma

	;-------todo de una
	pxor xmm15, xmm15		;xmm15 = 0
	movd xmm15, r13d		;xmm15 = 0 | 0 | 0 | r13d
	pslldq xmm15, 8			;xmm15 = 0 | r13d | 0 | 0
	por xmm12, xmm15		;xmm12 = 0 | r13d | *(prev_vals+3) | *(prev_vals+2)
	psrldq xmm12, 4			;xmm12 = 0 | 0 | r13d | *(prev_vals+3)


	;-------vieja forma
    ;-------*(prev_vals+4) = *(prev_vals+5);
    ; mov r12d, [esi+20]		;r12d = *(prev_vals+5)
    ; mov [esi+16], r12d		;*(prev_vals+4) = r12d

    ;-------*(prev_vals+5) = p(m_output)[i];
    ; movd [esi+20], xmm4
    ;-------vieja forma

    ;-------todo de una
    pxor xmm15, xmm15		;xmm15 = 0
    movd r12d, xmm4
    movd xmm15, r12d		;xmm15 = 0 | 0 | 0 | output
    pslldq xmm15, 8			;xmm15 = 0 | output | 0 | 0
    por xmm13, xmm15		;xmm13 = 0 | output | *(prev_vals+5) | *(prev_vals+4)
    psrldq xmm13, 4			;xmm13 = 0 | 0 | output| *(prev_vals+5) 


    movdqu xmm15, xmm4		;meto xmm4 en el dw mas alto de xmm15
    pslldq xmm15, 12		;xmm15 = res | 0 | 0 | 0
    orps xmm8, xmm15

    psrldq xmm9, 4			;shifteo 1 dw a la derecha, para usar el siguiente dato. la segunda entrada pasa a ser la primera
    movdqu xmm4, xmm9		;copio toda la entrada a xmm4
	pand xmm4, xmm7		;limpio la parte superior. solo queda la primer entrada


    ;---------------------------------------------
	;---------- fin ciclo 3 ----------------------
	;---------------------------------------------

    ;----- copio xmm8 a la direccion del buffer
    movdqu [r14], xmm8


	;---incrementaciones
	add ebx, 4					;incremento el contador i, en 4
	jmp .cicloGrande
	.finGrande:

	;-----guardo el prev_vals modificado
	pslldq xmm12, 8
	por xmm12, xmm11
	movdqu [rsi], xmm12
	movq [rsi+16], xmm13
	;---

	pop r14
	pop r13
	pop r12
	pop rbx
	pop rbp
ret


;------------------------------------------------------------------------------------------
;---------------------------------- VERSIONES MUY ANTERIORES ------------------------------
;------------------------------------------------------------------------------------------


;versión con prev_Vals en memoria, y 1 acceso por dato
equalizerg:
	push rbp
	mov rbp, rsp
	push rbx		;rbx es i
	push r12		;r12 es aux
	push r13		;r13d es temp
	push r14		;r14d es la posicion del buffer


	;---------- seteo constantes------------

	;------ limpio bits superiores ---------
	pxor xmm10, xmm10	; xmm10 es 0
	mov r12d, 0xFFFFFFFF
	movd xmm10, r12d		; xmm10 tiene un dw de unos, el resto 0

	;desplazo todos un xmm a la derecha - pequeño parche porque estaba mal la calling convention
	movdqu xmm8, xmm7
	movdqu xmm7, xmm6
	movdqu xmm6, xmm5
	movdqu xmm5, xmm4
	movdqu xmm4, xmm3
	movdqu xmm3, xmm2
	movdqu xmm2, xmm1
	
	movdqu xmm1, xmm0		;en xmm0 tendré lo mismo que en el 1
	mulss xmm1, [rel unDos]	;lo multiplico por dos, porque float psuma1 = psuma0 *2;

	pand xmm0, xmm10	; filtro todo lo que no sea el primer float
	pand xmm1, xmm10	; filtro todo lo que no sea el primer float
	pand xmm2, xmm10	; filtro todo lo que no sea el primer float
	pand xmm3, xmm10	; filtro todo lo que no sea el primer float
	pand xmm4, xmm10	; filtro todo lo que no sea el primer float
	pand xmm5, xmm10	; filtro todo lo que no sea el primer float
	pand xmm6, xmm10	; filtro todo lo que no sea el primer float
	pand xmm7, xmm10	; filtro todo lo que no sea el primer float
	pand xmm8, xmm10	; filtro todo lo que no sea el primer float
	;-----------------


	movdqu xmm9, xmm0		;xmm9 = factorsuma1

	;primersuma

						;xmm0	= 0 | 0 | 0 | primersuma0
	pslldq xmm1, 4		;xmm1	= 0 | 0 | primersuma1 | 0
	pslldq xmm2, 8		;xmm2	= 0 | primersuma2 | 0 | 0
	pslldq xmm3, 12		;xmm3	= primersuma3 | 0 | 0 | 0

	orps xmm0, xmm1
	orps xmm2, xmm3
	orps xmm0, xmm2		;xmm0 = primersuma3 | primersuma2 | primersuma1 | primersuma0
	;acá tengo las constantes de la primer suma en horizontal


	;segundasuma
						;xmm4	= 0 | 0 | 0 | segundasuma0
	pslldq xmm5, 4		;xmm5	= 0 | 0 | segundasuma1 | 0
	pslldq xmm6, 8		;xmm6	= 0 | segundasuma2 | 0 | 0
	pslldq xmm7, 12		;xmm7	= segundasuma3 | 0 | 0 | 0

	orps xmm4, xmm5
	orps xmm6, xmm7
	orps xmm4, xmm6		;xmm4 = segundasuma3 | segundasuma2 | segundasuma1 | segundasuma0

	;acá tengo las constantes de la segunda suma en horizontal
	
	movdqu xmm1, xmm9
	movdqu xmm3, xmm8
	movdqu xmm2, xmm4
	;ctes:
	; xmm0: primersuma
	; xmm1: factorsuma1
	; xmm2: segundasuma
	; xmm3: factorsuma2	

	;------- fin constantes ------------------ son 4

	;------- arranca el ciclo ----------------
	xor ebx, ebx		; i empieza en 0
	.ciclo:
	cmp ebx, edx		;si i es sample_count, termino
	jae .fin

	mov r14d, ebx
	sal r14d, 2		;multiplico por 4
	;imul r14d, 4
	add r14d, edi	;r14d es la posicion a escribir del buffer	 - TODO - mejorar con un lea

	movd xmm4, [r14d]		;levanto *buffer + i a xmm4


	;---------- low-pass filter-------------------

	;------float temp = p(m_output)[i];
	movd r13d, xmm4

	;------p(m_output)[i] *= lpf_b0;
	mulss xmm4, xmm1

	;------p(m_output)[i] +=  lpf_b0 * *(prev_vals) + lpf_b1 * *(prev_vals+1) - lpf_a2 * *(prev_vals+2) - lpf_a1 * *(prev_vals+3);
	movdqu xmm5, [esi]	;xmm5 = *(prev_vals+3) |*(prev_vals+2) |*(prev_vals+1) | *(prev_vals)
	mulps xmm5, xmm0	;xmm5 = *(pv+3)*ps3	   |*(pv+2)*ps2	   |*(pv+1)*ps1	   |*(pv)*ps0

	haddps xmm5, xmm5	;xmm5 = basura      | basura      |psuma3+psuma2|psuma1+psuma0
	haddps xmm5, xmm5	;xmm5 = basura      | basura      | basura		|ps3+ps2+ps1+ps0

	addss xmm4, xmm5		;xmm4 = xmm4 * lpf_b0 + lpf_b0 * *(prev_vals) + lpf_b1 * *(prev_vals+1) - lpf_a2 * *(prev_vals+2) - lpf_a1 * *(prev_vals+3)

	;-------------fin operaciones sobre el output

	;------*prev_vals = *(prev_vals+1);
	mov r12d, [esi+4]	;r12d = *(prev_vals + 1)
	mov [esi], r12d		;*prev_vals = r12d

	;------*(prev_vals+1) = temp;
	mov [esi+4], r13d	;*(prev_vals + 1) = r13d



	;----------------- peaking EQ (resonance) ----------------
	;-------float temp2 = p(m_output)[i];
	movd r13d, xmm4

    ;-------p(m_output)[i] *= peak_b0;
    mulss xmm4, xmm3	;xmm4 = xmm4 * factorsuma2

    ;-------p(m_output)[i] += peak_b2 * *(prev_vals+2) + peak_b1 * *(prev_vals+3) - peak_a2 * *(prev_vals+4) - peak_a1 * *(prev_vals+5);
    movdqu xmm5, [esi+8]	;xmm5 = *(prev_vals+5) |*(prev_vals+4) |*(prev_vals+3) | *(prev_vals2)
    mulps xmm5, xmm2		;xmm5 = *(pv+5)*ss3	   |*(pv+4)*ss2	   |*(pv+3)*ss1	   |*(pv+2)*ss0

	haddps xmm5, xmm5	;xmm5 = basura      | basura      |ssuma3+ssuma2|ssuma1+ssuma0
	haddps xmm5, xmm5	;xmm5 = basura      | basura      | basura		|ss3+ss2+ss1+ss0

	addss xmm4, xmm5		;xmm4 = xmm4 * peak_b0 + peak_b2 * *(prev_vals+2) + peak_b1 * *(prev_vals+3) - peak_a2 * *(prev_vals+4) - peak_a1 * *(prev_vals+5);

	;------------------ fin operaciones sobre el output

    ;-------*(prev_vals+2) = *(prev_vals+3);
    mov r12d, [esi+12]		;r12d = *(prev_vals+3)
    mov [esi+8], r12d		;*(prev_vals+2) = r12d

    ;-------*(prev_vals+3) = temp2;
	mov [esi+12], r13d		;*(prev_vals+3) = r13d

    ;-------*(prev_vals+4) = *(prev_vals+5);
    mov r12d, [esi+20]		;r12d = *(prev_vals+5)
    mov [esi+16], r12d		;*(prev_vals+4) = r12d

    ;-------*(prev_vals+5) = p(m_output)[i];
    movd [esi+20], xmm4


    ;----- copio xmm4 a la direccion del buffer
    movd [r14d], xmm4




	;---incrementaciones
	inc ebx					;incremento el contador i, en 1
	jmp .ciclo
	.fin:



	pop r14
	pop r13
	pop r12
	pop rbx
	pop rbp
ret
