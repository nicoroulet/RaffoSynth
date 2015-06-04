global ondaTriangular
global ondaSierra
global ondaPulso
global ondaCuadrada
global nada

extern fprintf

section .data
align 16	;Alineo - TODO: usar movdqa para mejorar tiempocounter, subperiods
; cuatros: dd 4.0, 4.0, 4.0, 4.0
cuatros: dd 4.0, 4.0, 4.0, 4.0
medios: dd 0.5, 0.5, 0.5, 0.5
; sacadorDeSigno: dd 0x7FFFFFFF, 0x7FFFFFFF, 0x7FFFFFFF, 0x7FFFFFFF
sumadorCounter: dd 0.0, 1.0, 2.0, 3.0
medioMedios: dd 0.25, 0.25, 0.25, 0.25
menosUnos: dd -1.0, -1.0, -1.0, -1.0
unos: dd 1.0, 1.0, 1.0, 1.0
dos: dd 2.0, 2.0, 2.0, 2.0
puntoDos: dd 0.2, 0.2, 0.2, 0.2
ceros: dd 0.0, 0.0, 0.0, 0.0


;no aligned
stringImprimirFloat: DB '%.2f', 10, 0

section .text
nada:
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

	movdqu xmm10, [rel unos]	;xmm10 = 1.0 | 1.0 | 1.0 | 1.0

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
	push r12		;
	push r13		;
	push r14		;


	;----seteo variables y constantes
	mov ebx, edi	;ebx es i

	mov r14d, 0xFFFFFFFF
	movq xmm14, r14
	pshufd xmm14, xmm14, 0		;xmm14 es full 1

	movdqu xmm11, [rel medios]	;xmm11 = 0.5 | 0.5 | 0.5 | 0.5

	;movdqu xmm10, [rel unos]	
	movdqu xmm10, xmm11
	addps xmm10, xmm10			;xmm10 = 1.0 | 1.0 | 1.0 | 1.0

	;movdqu xmm4, [rel cuatros]	
	movdqu xmm4, xmm10
	addps xmm4, xmm4
	addps xmm4, xmm4	;xmm4 es 4.0 | 4.0 | 4.0 | 4.0

	movdqu xmm12, [rel ceros]	;xmm12 es 0.0 | 0.0 | 0.0 | 0.0

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

	movdqu xmm15, [rel puntoDos]	;xmm11 = 0.2 | 0.2 | 0.2 | 0.2
	; movdqu xmm11, [rel medios]

	movdqu xmm10, [rel unos]	
	; movdqu xmm10, xmm11
	; addps xmm10, xmm10			;xmm10 = 1.0 | 1.0 | 1.0 | 1.0

	;movdqu xmm4, [rel cuatros]	
	movdqu xmm4, xmm10
	addps xmm4, xmm4
	addps xmm4, xmm4	;xmm4 es 4.0 | 4.0 | 4.0 | 4.0

	movdqu xmm12, [rel ceros]	;xmm12 es 0.0 | 0.0 | 0.0 | 0.0

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

	;----seteo constantes

	movdqu xmm4, [rel cuatros]		;xmm4 va a tener cuatro cuatros en floats

	movdqu xmm13, xmm0
	divps xmm13, xmm4				;xmm13 va a tener cuatro subperiod/4 en floats
	
	movdqa xmm5, [rel medios]		;xmm5 va a tener cuatro .5 en floats
	
	movdqu xmm10, [rel ceros]		;xmm10 va a tener cuatro ceros
	
	movdqu xmm15, [rel menosUnos]	;xmm15 va a tener cuatro -1

	movdqu xmm14, [rel medioMedios]	;xmm14 va a tener cuatro .25

	
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

	mulps xmm6, xmm0		;xmm6 = ((aux/subperiod) - truncf(aux/subperiod))*subperiod
	;----

	;aux = aux / subperiod
	divps xmm6, xmm0		;todo-tachar con el mulps de arriba

	;aux = aux - .5
	subps xmm6, xmm5

	;----xmm6 = fabs(xmm6);
	;como no existe para simd, me las arreglo
	movdqu xmm8, xmm6			;copio a xmm8
	movdqu xmm13, xmm6			;copio a xmm13

	cmpps xmm8, xmm10, 1		;es equivalente a cmpltps xmm8, [ceros] -> da unos donde era negativo

	movdqu xmm9, xmm8
	pxor xmm9, xmm11			;en xmm9 tengo unos donde era positivo
	pand xmm9, xmm6				;en xmm9 tengo el valor donde era positivo. 0 cc

	mulps xmm13, xmm15			;en xmm13 tengo los valores multiplicados por -1
	pand xmm8, xmm13			;en xmm8 tengo el valor multiplicado por -1, si era negativo. 0 cc

	por xmm8, xmm9				;en xmm8 tengo los valores cuando eran pos, y los valores *-1 cuando eran neg
	;----

	subps xmm8, xmm14	;le resto .25

	mulps xmm8, xmm4	;multiplico por 4

	mulps xmm8, xmm2	;multiplico por env

	mulps xmm8, xmm1	;multiplico por vol

	;lea r14d, [ecx + ebx *4]	;r14d es &buffer + i * 4 todo-mas eficiente

	mov r14d, ebx
	imul r14d, 4	;r16d es i * 4
	add r14d, ecx	;r16d es la posicion a escribir del buffer

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