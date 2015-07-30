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



//hace lo mismo que la versión en asm
void equalizer(float* buffer, float* prev_vals, uint32_t sample_count, float psuma0, float psuma1, float psuma2, float psuma3, float ssuma0, float ssuma1, float ssuma2, float ssuma3, float factorSuma2){
  for (int i = 0; i < sample_count; i++) {
    //low-pass filter    

    float temp = buffer[i];
    buffer[i] *= psuma0; 	//psuma0 == factorsuma1
    buffer[i] += psuma0 * prev_vals[0] + psuma1 * prev_vals[1] 
                    + psuma2 * prev_vals[2] + psuma3* prev_vals[3];
    prev_vals[0] = prev_vals[1];
    prev_vals[1] = temp;
    
    // peaking EQ (resonance)
    float temp2 = buffer[i];

    buffer[i] *= factorSuma2;
    buffer[i] += ssuma0 * prev_vals[2] + ssuma1 * prev_vals[3] 
                    + ssuma2 * prev_vals[4] + ssuma3 * prev_vals[5];
    prev_vals[2] = prev_vals[3];
    prev_vals[3] = temp;
    prev_vals[4] = prev_vals[5];
    prev_vals[5] = buffer[i];
 	}
}

