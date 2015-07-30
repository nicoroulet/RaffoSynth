global ondaTriangular
global ondaSierra
global ondaPulso
global ondaCuadrada
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

	; pxor xmm10, xmm10	; xmm10 es 0
	; mov r12d, 0xFFFFFFFF
	; movd xmm10, r12d		; xmm10 tiene un dw de unos, el resto 0

	; pand xmm0, xmm10	; filtro todo lo que no sea el primer float
	; pand xmm1, xmm10	; filtro todo lo que no sea el primer float
	; pand xmm2, xmm10	; filtro todo lo que no sea el primer float
	; pand xmm3, xmm10	; filtro todo lo que no sea el primer float
	; pand xmm4, xmm10	; filtro todo lo que no sea el primer float
	; pand xmm5, xmm10	; filtro todo lo que no sea el primer float
	; pand xmm6, xmm10	; filtro todo lo que no sea el primer float
	; pand xmm7, xmm10	; filtro todo lo que no sea el primer float
	; pand xmm8, xmm10	; filtro todo lo que no sea el primer float
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



; byte = 8b = char
; word = 2B = short
; dw = 4B = int = float
; qw = 8B = r = double
; dqw = 16B = xmm


; void OndaSierra(uint32_t from, uint32_t to, uint32_t counter, float* buffer, float subperiod, float vol, float env){
; for (uint32_t i = from; i < to; ++i, counter++) {
;             buffer[i] += vol * (2. * fmod(counter, subperiod) / subperiod - 1) * env;  
;  }
; }

; buffer[0] = &buffer + 0
; buffer[1] = &buffer + 4
; buffer[2] = &buffer + 8
; buffer[3] = &buffer + 12

; buffer[4] = &buffer + 16


;void ondaSierra
	;uint32_i from 			edi
	;uint32_i to 			esi
	;uint32_t counter		edx
	;float* buffer			ecx

	;float subperiod		xmm0
	;float vol 				xmm1
	;float env				xmm2

ondaSierra:
	push rbp
	mov rbp, rsp
	push rbx		;rbx es i
	push r12		;
	push r13		;
	push r14		;


	;----seteo variables
	mov ebx, edi	;ebx es i

	movdqa xmm10, [rel unos]	;xmm10 = 1.0 | 1.0 | 1.0 | 1.0

	;movdqu xmm4, [rel cuatros]	
	movdqu xmm4, xmm10
	addps xmm4, xmm4
	addps xmm4, xmm4	;xmm4 es 4.0 | 4.0 | 4.0 | 4.0


	;----broadcasteo variables
	pshufd xmm0, xmm0, 0		;broadcasteo subperiod

	;movdqu xmm6, [rel dos]		
	movdqu xmm6, xmm10
	addps xmm6, xmm6			;xmm6 tiene 2.0 | 2.0 | 2.0 | 2.0

	divps xmm6, xmm0			;xmm6 tiene 2/subperiod | 2/subperiod | 2/subperiod | 2/subperiod 
	

	pshufd xmm1, xmm1, 0		;broadcasteo vol

	pshufd xmm2, xmm2, 0		;broadcasteo env

	movd xmm3, edx
	pshufd xmm3, xmm3, 0		;broadcasteo counter, en xmm3
	cvtdq2ps xmm3, xmm3
	addps xmm3, [rel sumadorCounter]	;xmm3= counter | counter+1 | counter+2 | counter +3


	.ciclo:
	cmp ebx, esi		;si i es to, termino
	jae .fin

	mov r14d, ebx
	imul r14d, 4	;r16d es i * 4
	add r14d, ecx	;r16d es la posicion a escribir del buffer

	movdqu xmm7, [r14d]		;levanto *buffer + i a xmm7

	;---en xmm5 calculo el valor a sumarle a buffer

	;--xmm5 = fmod(counter, subperiod)
	;No hay fmod, así que me las arreglo:
	;--xmm5 = (((counter/subperiod) - truncf(counter/subperiod))*subperiod)
	movdqu xmm5, xmm3		;xmm5 = counter
	divps xmm5, xmm0		;xmm5 = counter/subperiod
	movdqu xmm8, xmm5		;xmm8 = counter/subperiod
	
	roundps xmm8, xmm8, 3 	;xmm8 = roundps(counter/subperiod, 3), trunco xmm8
	
	subps xmm5, xmm8		;xmm5 = (counter/subperiod) - truncf(counter/subperiod)

	mulps xmm5, xmm0		;xmm8 = ((counter/subperiod) - truncf(counter/subperiod))*subperiod
	;----

	;buffer[i] += vol * (2. * fmod(counter, subperiod) / subperiod - 1) * env;


	mulps xmm5, xmm6		;lo multiplico por 2.0 /subperiod

	subps xmm5, xmm10		;le resto unos
	mulps xmm5, xmm1		;lo multiplico por vol
	mulps xmm5, xmm2		;lo multiplico por env


	;---counter = xmm7 + xmm5
	addps xmm5, xmm7		;le agrego el previo valor del buffer
	movdqu [r14d], xmm5		;guardo

	;---incrementaciones
	addps xmm3, xmm4		;a counter le sumo 4 | 4 | 4 | 4
	add ebx, 4					;incremento el contador i
	jmp .ciclo
	.fin:

	pop r14
	pop r13
	pop r12
	pop rbx
	pop rbp

ret

; void ondaCuadrada(uint32_t from, uint32_t to, uint32_t counter, float* buffer, float subperiod, float vol, float env){
; 	for (uint32_t i = from; i < to; ++i, counter++) {
;  		buffer[i] += vol * (2. * ((fmod(counter, subperiod) / subperiod - .5) < 0)-1) * env;
;  }
; }

;void ondaCuadrada   			- una sierra que cuando vale > .5 es un 1, y en cc es un 0
	;uint32_i from 			edi
	;uint32_i to 			esi
	;uint32_t counter		edx
	;float* buffer			ecx

	;float subperiod		xmm0
	;float vol 				xmm1
	;float env				xmm2

ondaCuadrada:
	push rbp
	mov rbp, rsp
	push rbx		;rbx es i
	push r12		;dasd
	push r13		;
	push r14		;


	;----seteo variables y constantes
	mov ebx, edi	;ebx es i

	mov r14d, 0xFFFFFFFF
	movq xmm14, r14
	pshufd xmm14, xmm14, 0		;xmm14 es full 1

	movdqa xmm11, [rel medios]	;xmm11 = 0.5 | 0.5 | 0.5 | 0.5

	;movdqu xmm10, [rel unos]	
	movdqu xmm10, xmm11
	addps xmm10, xmm10			;xmm10 = 1.0 | 1.0 | 1.0 | 1.0

	;movdqu xmm4, [rel cuatros]	
	movdqu xmm4, xmm10
	addps xmm4, xmm4
	addps xmm4, xmm4	;xmm4 es 4.0 | 4.0 | 4.0 | 4.0

	;movdqu xmm12, [rel ceros]	;xmm12 es 0.0 | 0.0 | 0.0 | 0.0
	movdqa xmm12, xmm4
	subps xmm12, xmm12

	pshufd xmm0, xmm0, 0		;broadcasteo subperiod

	;movdqu xmm6, [rel dos]		
	movdqu xmm6, xmm10
	addps xmm6, xmm6			;xmm6 es 2.0 | 2.0 | 2.0 | 2.0
	

	pshufd xmm1, xmm1, 0		;broadcasteo vol

	pshufd xmm2, xmm2, 0		;broadcasteo env

	movd xmm3, edx
	pshufd xmm3, xmm3, 0		;broadcasteo counter, en xmm3
	cvtdq2ps xmm3, xmm3
	addps xmm3, [rel sumadorCounter]	;xmm3= counter | counter+1 | counter+2 | counter +3


	.ciclo:
	cmp ebx, esi		;si i es to, termino
	jae .fin

	mov r14d, ebx
	imul r14d, 4	;r16d es i * 4
	add r14d, ecx	;r16d es la posicion a escribir del buffer

	movdqu xmm7, [r14d]		;levanto *buffer + i a xmm7

	;---en xmm5 calculo el valor a sumarle a buffer

	;--xmm5 = fmod(counter, subperiod)
	;No hay fmod, así que me las arreglo:
	;--xmm5 = (((counter/subperiod) - truncf(counter/subperiod))*subperiod)
	movdqu xmm5, xmm3		;xmm5 = counter
	divps xmm5, xmm0		;xmm5 = counter/subperiod
	movdqu xmm8, xmm5		;xmm8 = counter/subperiod
	
	roundps xmm8, xmm8, 3 	;xmm8 = roundps(counter/subperiod, 3), trunco xmm8
	
	subps xmm5, xmm8		;xmm5 = (counter/subperiod) - truncf(counter/subperiod)

	mulps xmm5, xmm0		;xmm8 = ((counter/subperiod) - truncf(counter/subperiod))*subperiod
	;----

	;buffer[i] += vol * (2. * ((fmod(counter, subperiod) / subperiod - .5) < 0)-1) * env;


	divps xmm5, xmm0		;lo divido por subperiod
	subps xmm5, xmm11		;le resto .5


	cmpps xmm5, xmm12, 1	;donde xmm5 < 0 hay unos, si no, hay ceros
	movdqu xmm13, xmm14		;xmm13 es full 1
	pxor xmm13, xmm5		;donde xmm5 >= 0 hay unos, si no, hay ceros

	pand xmm5, xmm10		;donde xmm5 < 0, hay un 1.0. donde no, hay ceros

	pand xmm13, xmm12		;donde xmm5>= 0 hay un 0.0, donde no, hay ceros.

	por xmm5, xmm13		;donde xmm5<0 hay 1.0. donde no, hay 0.0.


	mulps xmm5, xmm6		;lo multiplico por 2

	subps xmm5, xmm10		;le resto unos
	mulps xmm5, xmm1		;lo multiplico por vol
	mulps xmm5, xmm2		;lo multiplico por env


	;---counter = xmm7 + xmm5
	addps xmm5, xmm7		;le agrego el previo valor del buffer
	movdqu [r14d], xmm5		;guardo

	;---incrementaciones
	addps xmm3, xmm4		;a counter le sumo 4 | 4 | 4 | 4
	add ebx, 4					;incremento el contador i
	jmp .ciclo
	.fin:

	pop r14
	pop r13
	pop r12
	pop rbx
	pop rbp

ret

; void ondaPulso(uint32_t from, uint32_t to, uint32_t counter, float* buffer, float subperiod, float vol, float env){
; 	for (uint32_t i = from; i < to; ++i, counter++) {
;    buffer[i] += vol * (2. * ((fmod(counter, subperiod) / subperiod - .2) < 0)-1) * env;
;  }
; }

;void ondaPulso   			- idem cuadrada, pero con .2 en vez de .5
	;uint32_i from 			edi
	;uint32_i to 			esi
	;uint32_t counter		edx
	;float* buffer			ecx

	;float subperiod		xmm0
	;float vol 				xmm1
	;float env				xmm2

ondaPulso:
	push rbp
	mov rbp, rsp
	push rbx		;rbx es i
	push r12		;
	push r13		;
	push r14		;


	;----seteo variables y constantes
	mov ebx, edi	;ebx es i

	mov r14d, 0xFFFFFFFF
	movq xmm14, r14
	pshufd xmm14, xmm14, 0		;xmm14 es full 1

	movdqa xmm15, [rel puntoDos]	;xmm11 = 0.2 | 0.2 | 0.2 | 0.2
	; movdqu xmm11, [rel medios]

	; movdqu xmm10, [rel unos]
	movdqa xmm10, xmm15	;.2
	addps xmm10, xmm10	;.4
	addps xmm10, xmm10	;.8
	addps xmm10, xmm15	;1.		;xmm10 = 1.0 | 1.0 | 1.0 | 1.0

	; movdqu xmm4, [rel cuatros]	
	movdqa xmm4, xmm10	;1
	addps xmm4, xmm4	;2
	addps xmm4, xmm4	;xmm4 es 4.0 | 4.0 | 4.0 | 4.0

	;movdqu xmm12, [rel ceros]	;xmm12 es 0.0 | 0.0 | 0.0 | 0.0
	movdqa xmm12, xmm4	;4.
	subps xmm12, xmm12	;0.

	pshufd xmm0, xmm0, 0		;broadcasteo subperiod

	;movdqu xmm6, [rel dos]		
	movdqa xmm6, xmm10
	addps xmm6, xmm6			;xmm6 es 2.0 | 2.0 | 2.0 | 2.0
	

	pshufd xmm1, xmm1, 0		;broadcasteo vol

	pshufd xmm2, xmm2, 0		;broadcasteo env

	movd xmm3, edx
	pshufd xmm3, xmm3, 0		;broadcasteo counter, en xmm3
	cvtdq2ps xmm3, xmm3
	addps xmm3, [rel sumadorCounter]	;xmm3= counter | counter+1 | counter+2 | counter +3


	.ciclo:
	cmp ebx, esi		;si i es to, termino
	jae .fin

	mov r14d, ebx
	imul r14d, 4	;r16d es i * 4
	add r14d, ecx	;r16d es la posicion a escribir del buffer

	movdqu xmm7, [r14d]		;levanto *buffer + i a xmm7

	;---en xmm5 calculo el valor a sumarle a buffer

	;--xmm5 = fmod(counter, subperiod)
	;No hay fmod, así que me las arreglo:
	;--xmm5 = (((counter/subperiod) - truncf(counter/subperiod))*subperiod)
	movdqu xmm5, xmm3		;xmm5 = counter
	divps xmm5, xmm0		;xmm5 = counter/subperiod
	movdqu xmm8, xmm5		;xmm8 = counter/subperiod
	
	roundps xmm8, xmm8, 3 	;xmm8 = roundps(counter/subperiod, 3), trunco xmm8
	
	subps xmm5, xmm8		;xmm5 = (counter/subperiod) - truncf(counter/subperiod)

	mulps xmm5, xmm0		;xmm8 = ((counter/subperiod) - truncf(counter/subperiod))*subperiod
	;----

	;buffer[i] += vol * (2. * ((fmod(counter, subperiod) / subperiod - .5) < 0)-1) * env;


	divps xmm5, xmm0		;lo divido por subperiod
	subps xmm5, xmm15		;le resto .2


	cmpps xmm5, xmm12, 1	;donde xmm5 < 0 hay unos, si no, hay ceros
	movdqu xmm13, xmm14		;xmm13 es full 1
	pxor xmm13, xmm5		;donde xmm5 >= 0 hay unos, si no, hay ceros

	pand xmm5, xmm10		;donde xmm5 < 0, hay un 1.0. donde no, hay ceros

	pand xmm13, xmm12		;donde xmm5>= 0 hay un 0.0, donde no, hay ceros.

	por xmm5, xmm13		;donde xmm5<0 hay 1.0. donde no, hay 0.0.


	mulps xmm5, xmm6		;lo multiplico por 2

	subps xmm5, xmm10		;le resto unos
	mulps xmm5, xmm1		;lo multiplico por vol
	mulps xmm5, xmm2		;lo multiplico por env


	;---counter = xmm7 + xmm5
	addps xmm5, xmm7		;le agrego el previo valor del buffer
	movdqu [r14d], xmm5		;guardo

	;---incrementaciones
	addps xmm3, xmm4		;a counter le sumo 4 | 4 | 4 | 4
	add ebx, 4					;incremento el contador i
	jmp .ciclo
	.fin:

	pop r14
	pop r13
	pop r12
	pop rbx
	pop rbp

ret



;void ondaTriangular(uint32_t from, uint32_t to, uint32_t counter, float* buffer, float subperiod, float vol, float env){
;	for (uint32_t i = from; i < to; ++i, counter++) {
;		buffer[i] += vol * (4. * (fabs(fmod((counter + subperiod/4.), subperiod) /
;	                  subperiod - .5)-.25)) * env;
;	}
;}

;void ondaTriangular    (
	;uint32_i from 			edi
	;uint32_i to 			esi
	;uint32_t counter		edx
	;float* buffer			ecx

	;float subperiod		xmm0
	;float vol 				xmm1
	;float env				xmm2
ondaTriangular:
	push rbp
	mov rbp, rsp
	push rbx		;rbx es i
	push r12		;
	push r13		;
	push r14		;

	;seteo variables
	mov ebx, edi	;ebx es i

	;----broadcasteo variables
	pshufd xmm0, xmm0, 0		;broadcasteo subperiod

	pshufd xmm1, xmm1, 0		;broadcasteo vol

	pshufd xmm2, xmm2, 0		;broadcasteo env

	;muevo counter a xmm3, broadcasteo y lo sumo con  0 | 1 | 2 | 3
	movd xmm3, edx
	pshufd xmm3, xmm3, 0
	cvtdq2ps xmm3, xmm3
	addps xmm3, [rel sumadorCounter]

	;----seteo constantes	- en vez de hacer accesos a memoria los calculo del que tiene .25
	movdqu xmm14, [rel medioMedios]	;xmm14 va a tener cuatro .25

	;movdqu xmm4, [rel cuatros]		;xmm4 va a tener cuatro cuatros en floats
	movdqu xmm4, xmm14
	addps xmm4, xmm4		;.5
	addps xmm4, xmm4		;1.
	addps xmm4, xmm4		;2.
	addps xmm4, xmm4		;4.

	movdqu xmm13, xmm0
	divps xmm13, xmm4				;xmm13 va a tener cuatro subperiod/4 en floats
	

	;movdqa xmm5, [rel medios]		;xmm5 va a tener cuatro .5 en floats
	movdqa xmm5, xmm14	;.25
	addps xmm5, xmm5	;.5	
	
	;movdqu xmm10, [rel ceros]		;xmm10 va a tener cuatro ceros
	movdqa xmm10, xmm5	;.5
	subps xmm10, xmm10	;0.
	
	;movdqu xmm15, [rel menosUnos]	;xmm15 va a tener cuatro -1
	movdqu xmm15, xmm5	;.5
	subps xmm15, xmm5	;0.
	subps xmm15, xmm5	;-.5
	subps xmm15, xmm5	;-1.
	
	mov r14d, 0xFFFFFFFF
	movd xmm11, r14d
	pshufd xmm11, xmm11, 0			;xmm11 va a tener full 1

	.ciclo:
	cmp ebx, esi		;si i es to, termino
	jae .fin


	;buffer[i] += vol * (4. * [fabs(fmod[(counter + subperiod/4.), subperiod] / subperiod - .5)-.25]) * env;

	;aux = counter + subperiod/4
	movdqu xmm6, xmm3		;xmm6 = counter
	addps xmm6, xmm13		;xmm6 = counter + subperiod/4.


	;--xmm6 = fmod(aux, subperiod)
	;No hay fmod, así que me las arreglo:
	;--xmm6 = (((aux/subperiod) - truncf(aux/subperiod))*subperiod)
	divps xmm6, xmm0		;xmm6 = aux/subperiod
	movdqu xmm8, xmm6		;xmm8 = aux/subperiod
	
	roundps xmm8, xmm8, 3 	;xmm8 = roundps(aux/subperiod, 3), trunco xmm8
	
	subps xmm6, xmm8		;xmm6 = (aux/subperiod) - truncf(aux/subperiod))

	;mulps xmm6, xmm0		;xmm6 = ((aux/subperiod) - truncf(aux/subperiod))*subperiod
	;----

	;aux = aux / subperiod
	;divps xmm6, xmm0		;se tacha con el mulps de arriba

	;aux = aux - .5
	subps xmm6, xmm5

	;----xmm6 = fabs(xmm6);
	;como no existe para simd, me las arreglo
	movdqu xmm8, xmm6			;copio a xmm8
	movdqu xmm7, xmm6			;copio a xmm7

	cmpps xmm8, xmm10, 1		;es equivalente a cmpltps xmm8, [ceros] -> da unos donde era negativo

	movdqu xmm9, xmm8
	pxor xmm9, xmm11			;en xmm9 tengo unos donde era positivo
	pand xmm9, xmm6				;en xmm9 tengo el valor donde era positivo. 0 cc

	mulps xmm7, xmm15			;en xmm7 tengo los valores multiplicados por -1
	pand xmm8, xmm7			;en xmm8 tengo el valor multiplicado por -1, si era negativo. 0 cc

	por xmm8, xmm9				;en xmm8 tengo los valores cuando eran pos, y los valores *-1 cuando eran neg
	;----

	subps xmm8, xmm14	;le resto .25

	mulps xmm8, xmm4	;multiplico por 4

	mulps xmm8, xmm2	;multiplico por env

	mulps xmm8, xmm1	;multiplico por vol

	lea r14d, [ecx + ebx *4]	;r14d es &buffer + i * 4	 - lea es mas eficiente

	; mov r14d, ebx
	; imul r14d, 4	;r16d es i * 4
	; add r14d, ecx	;r16d es la posicion a escribir del buffer

	movdqu xmm9, [r14d]
	addps xmm8, xmm9
	;addps xmm8, [r14d]		;levanto del buffer y sumo
	movdqu [r14d], xmm8	;escribo en el buffer

	;---incrementaciones
	addps xmm3, xmm4		;a counter le sumo 4 | 4 | 4 | 4
	add ebx, 4					;incremento el contador i	
	jmp .ciclo

	.fin:
	pop r14
	pop r13
	pop r12
	pop rbx
	pop rbp
ret