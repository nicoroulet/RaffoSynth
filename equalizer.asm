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
	;float* buffer 			edi
	;float* prev 			esi
	;int sample_count		edx
  	;equ_asm(buffer, prev, sample_count, lpf_b0, lpf_b1, - lpf_a2, - lpf_a1, peak_b2, peak_b1, -peak_a2, -peak_a1, peak_b0);

	;float primersuma0		xmm0 - tambien factorsuma1
	;float primersuma1 		xmm1
	;float primersuma2		xmm2
	;float primersuma3		xmm3
	;float segundasuma0		xmm4
	;float segundasuma1		xmm5
	;float segundasuma2		xmm6
	;float segundasuma3		xmm7
	;float factorSuma2		xmm8

equalizer:
	push rbp
	mov rbp, rsp
	push rbx		;rbx es i
	push r12		;r12 es aux
	push r13		;r13d es temp
	push r14		;r14d es la posicion del buffer


	;---------- seteo constantes------------

	;------ limpio bits superiores --- (esto no hace falta)
	; movq xmm0, xmm0
	; movq xmm1, xmm1
	; movq xmm2, xmm2
	; movq xmm3, xmm3
	; movq xmm4, xmm4
	; movq xmm5, xmm5
	; movq xmm6, xmm6
	; movq xmm7, xmm7
	; movq xmm8, xmm8

	pxor xmm10, xmm10	; xmm10 es 0
	mov r12d, 0xFFFFFFFF
	movd xmm10, r12d		; xmm10 tiene un dw de unos, el resto 0

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