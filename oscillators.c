#include <stdint.h>
#include <math.h>

void ondaTriangular(uint32_t from, uint32_t to, uint32_t counter, float* buffer, float subperiod, float vol, float env){
	uint32_t i;
	for (i = from; i < to; ++i, counter++) {
		   buffer[i] += vol * (4. * (fabs(fmod(((counter) + subperiod/4.), subperiod) / subperiod - .5)-.25)) * env; 
	}
}

void ondaSierra(uint32_t from, uint32_t to, uint32_t counter, float* buffer, float subperiod, float vol, float env){
	uint32_t i;
	for (i = from; i < to; ++i, counter++) {
		buffer[i] += vol * (2. * fmod(counter, subperiod) / subperiod - 1) * env;  
	}
}

void ondaCuadrada(uint32_t from, uint32_t to, uint32_t counter, float* buffer, float subperiod, float vol, float env){
	uint32_t i;
	for (i = from; i < to; ++i, counter++) {
		buffer[i] += vol * (2. * ((fmod(counter, subperiod) / subperiod - .5) < 0)-1) * env;
	}
}

void ondaPulso(uint32_t from, uint32_t to, uint32_t counter, float* buffer, float subperiod, float vol, float env){
	uint32_t i;
	for (i = from; i < to; ++i, counter++) {
		buffer[i] += vol * (2. * ((fmod(counter, subperiod) / subperiod - .2) < 0)-1) * env;
	}
}