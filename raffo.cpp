
#include "raffo.peg"
#include "fft.h"
#include "raffo.h"

// max_samples: cantidad maxima de samples que se procesan por llamado a render()
// un numero mayor resulta en mejor performance, pero peor granularidad en la transición de frecuencias
#define max_samples 256
#define ATTACK ((*p(m_attack) + 2) * 100)
#define DECAY (*p(m_decay)*100 + .1)
#define SUSTAIN pow(*p(m_sustain), 2)
#define RELEASE *p(m_release)
#define FILTER_ATTACK ((*p(m_filter_attack) + 2) * 100)
#define FILTER_DECAY (*p(m_filter_decay)*100 + .1)
#define FILTER_SUSTAIN *p(m_filter_sustain)
#define FILTER_RELEASE *p(m_filter_release)

using namespace std;

//funciones auxiliares
static inline float key2hz(unsigned char key) {
  return 8.1758 * pow(1.0594, key);
}
float min_fact(float a, float b) {
  return ((fabs(a-1) > fabs(b-1))? b: a);
}
float envelope(int count, float a, float d, float s) { 
  // adsr lineal
  // float c1 = (1.-s)/(2.*d);
  // float c2 = 1./(2.*a);
  // return (s - c1 * (count - a - d - fabs(count - a - d)) + 
  //        (c2 + c1) * (count - a - fabs(count - a))) ;
	
	// adsr cuadratico
	// wolfram input: Plot[Piecewise[{{-((x-10)^2)/(10^2) +1,x<10},{(x-10-10)^2/(10^2*(1-0.7))+0.7,10<x<10+10},{0.7,x>10+10}}],{x,0,30}]
  if (count > a+d) // si esta en fase de sustain
  	return s;
  if (count < a) // si esta en fase de attack
  	return -(count-a)*(count-a)/(a*a) + 1;
  // si esta en fase de decay
  return (count-a-d)*(count-a-d)*(1-s)/(d*d) + s;
}
float inv_envelope(float env, float a) { 
	// adsr lineal
	// return env*a;
	
	// adsr cuadratico
	return a - sqrt(-a*a*(env-1)); //-a * (a * sqrt((env+1) / (a*a)) - 1);
}

extern "C" void ondaTriangular(uint32_t from, uint32_t to, uint32_t counter, float* buffer, float subperiod, float vol, float env);

extern "C" void ondaSierra(uint32_t from, uint32_t to, uint32_t counter, float* buffer, float subperiod, float vol, float env);

extern "C" void ondaPulso(uint32_t from, uint32_t to, uint32_t counter, float* buffer, float subperiod, float vol, float env);

extern "C" void ondaCuadrada(uint32_t from, uint32_t to, uint32_t counter, float* buffer, float subperiod, float vol, float env);

extern "C" void equalizer(float* buffer, float* prev, uint32_t sample_count, float psuma0, float psuma2, float psuma3, float ssuma0, float ssuma1, float ssuma2, float ssuma3, float factorSuma2);

extern "C" void limpiarBuffer(uint32_t from, uint32_t to, float* buffer);

RaffoSynth::RaffoSynth(double rate):
  Parent(m_n_ports),
  sample_rate(rate)
#ifdef EXPERIENCIA
, output("data/oscasm_256.out")
#endif
  {
    midi_type = Parent::uri_to_id(LV2_EVENT_URI, "http://lv2plug.in/ns/ext/midi#MidiEvent"); 
  }

void RaffoSynth::activate()
{
  period = 500;
  glide_period = 500;
  pre_buf_end = 0;
  primer_nota = true;
  counter = 0;
  envelope_count = 0;
  filter_count = 0;
  modwheel = 0;
  pitch = 1;
  glide = 0;
  last_val[0] = last_val[1] = last_val[2] = last_val[3] = 0;
  prev_vals[0] = prev_vals[1] = prev_vals[2] = prev_vals[3] = prev_vals[4] = prev_vals[5] = 0;
}

void RaffoSynth::deactivate()
{
}

void RaffoSynth::render(uint32_t from, uint32_t to) {
#ifdef EXPERIENCIA
  t_osc.start();
#endif

  // buffer en 0
  limpiarBuffer(from, to, p(m_output));
  
  double glide_factor;
  if (*p(m_glide) < .1) {
    glide_period = period;
    glide_factor = 1;
  } else {
    glide = pow(2., (to-from) / (sample_rate * (*p(m_glide)/5.))) ;
    glide_factor = min_fact(((glide_period < period)? glide : 1. / glide), period/glide_period);
    glide_period *= glide_factor;
  }
  
  if (keys.empty()) { // actualizamos los envelopes
    envelope_count *= (pow(1.3, -pow(500, - RELEASE) * (to-from) / 256.) + 0.00052);
    filter_count *= (pow(1.3, -pow(500, - FILTER_RELEASE) * (to-from) / 256.) + 0.00052);
  } else {
    envelope_count += to - from;
    filter_count += to - from;
  }
  
  // osciladores
  
  float* buffer = p(m_output);
  for (int osc = 0; osc < 4; osc++) {
    if (*p(m_oscButton0 + osc) == 1){ //Si el botón del oscilador está en 1, se ejecuta render
      float vol = pow(*p(m_volume) * *p(m_vol0 + osc) / 100., .5)/4; // el volumen es el cuadrado de la amplitud
      float subperiod = glide_period / (pow(2,*p(m_range0 + osc))  * pitch * pow(2, *p(m_tuning0 + osc) / 12.) ); // periodo efectivo del oscilador
    
      // valores precalculados para el envelope
      // la función de envelope es:
        // f(t) = s - (1-s)/(2*d) * (t-a-d-|t-a-d|) + (1/(2*a) + (1-s)/(2*d)) * (t-a-|t-a|)
        /*
              /\
             /  \
            /    \_______________  -> s = sustain level
           /                     \
          /                       \
          |-a-|-d-|--------------|
        */

      float env = envelope(envelope_count, ATTACK, DECAY, SUSTAIN);
      counter = last_val[osc] * subperiod;

      switch ((int)*p(m_wave0 + osc)) {
        case (0): { //triangular
          //ASM/C
          ondaTriangular(from, to, counter, buffer, subperiod, vol, env);
          counter+= (to-from);
          break;
        }
        case (1): { //sierra
          //ASM/C
          ondaSierra(from, to, counter, buffer, subperiod, vol, env);
          counter+= (to - from);
          break;
        }
        case (2): { //cuadrada
          //ASM/C
          ondaCuadrada(from, to, counter, buffer, subperiod, vol, env);
          counter+= (to-from);
          break;
        }
        case (3): { //pulso
          //ASM/C
          ondaPulso(from, to, counter, buffer, subperiod, vol, env);
          counter+= (to-from);
          break;
        }
      }
    last_val[osc] = fmod(counter, subperiod) / subperiod; //para ajustar el enganche de la onda entre corridas de la funcion
    } //Fin del if
  } //Fin del for

#ifdef EXPERIENCIA
  t_osc.stop();
#endif
}

void RaffoSynth::handle_midi(uint32_t size, unsigned char* data) {
  if (size == 3) {
    switch (data[0] & 0xf0) {
      case (0x90): { // note on
        if (keys.empty()) {
	        if (primer_nota) {
		        glide_period = sample_rate * 4 / key2hz(data[1]); // la primera nota no tiene glide
		        primer_nota = false;
	        }
	        // last_val[0] = last_val[1] = last_val[2] = last_val[3] = 0.25;
        }
        keys.push_front(data[1]);
        period = sample_rate * 4 / key2hz(data[1]);
        break;
      }
      case (0xB0): { // Control Change => All Notes Off (CC 123)
        if (data[1]!=0x7B) break;
        keys.clear();
      }
      // No break because we want the note off behaviour ;-)
      case (0x80): { // note off
        keys.remove(data[1]);
        if (keys.empty()) {
        	// poner los contadores de adsr en el lugar correcto
			    envelope_count = inv_envelope(envelope(envelope_count, ATTACK, DECAY, SUSTAIN), ATTACK);
			    envelope_count *= (envelope_count>0);
			    filter_count = inv_envelope(envelope(filter_count, FILTER_ATTACK, FILTER_DECAY, FILTER_SUSTAIN), FILTER_ATTACK);
			    filter_count *= (filter_count>0);
        } else {
        	period = sample_rate * 4 / key2hz(keys.front());
        }
        break;
      }
      case (0xE0): { // pitch bend
        /* Calculamos el factor de pitch (numero por el que multiplicar 
           la frecuencia fundamental). data[2] es el byte mas significativo, 
           data[1] el menos. El primer bit de ambos es 0, por eso << 7. 
           el numero maximo de semitonos de amplitud del pitch es 2 (6=pitch_width/12).
        * Mas informacion: http://sites.uci.edu/camp2014/2014/04/30/managing-midi-pitchbend-messages/
        */
        pitch = pow(2.,(((data[2] << 7) ^ data[1]) / 8191. - 1) / 6.); 
      }  
    }
  }
}

void RaffoSynth::run(uint32_t sample_count) {

#ifdef EXPERIENCIA
  run_count++;
  t_run.start();
#endif

  LV2_Event_Iterator iter;
  lv2_event_begin(&iter, reinterpret_cast<LV2_Event_Buffer*&>(Parent::m_ports[m_midi]));


  uint8_t* event_data;
  uint32_t samples_done = 0;
  while (samples_done < sample_count) {
    uint32_t to = sample_count;
    LV2_Event* ev = 0;
    if (lv2_event_is_valid(&iter)) {
      ev = lv2_event_get(&iter, &event_data);
      to = ev->frames;
      lv2_event_increment(&iter);
    }
    if (to > samples_done) {
      while (samples_done + max_samples < to) { // subdividimos el buffer en porciones de tamaño max_sample
        render(samples_done, samples_done + max_samples);
        samples_done += max_samples;
      }
      render(samples_done, to);
      samples_done = to;
    }

    if (ev) {
      if (ev->type == midi_type)
        static_cast<RaffoSynth*>(this)->handle_midi(ev->size, event_data);
    }
  }

  // EQ
#ifdef EXPERIENCIA
  t_eq.start();
#endif

  equ_wrapper(sample_count);
  // ir(sample_count);

#ifdef EXPERIENCIA
  t_eq.stop();

  t_run.stop();

  if (run_count<5000)
    output << run_count << " " << t_run.time << " " << t_osc.time << " " << t_eq.time << endl;
#endif
} /*run*/

//equ_wrapper prepara las variables y las manda a la funcion en asm o en c (segun como se compilo)
void RaffoSynth::equ_wrapper(int sample_count){
  //http://www.musicdsp.org/files/Audio-EQ-Cookbook.txt
  
  // variables precalculadas
 
  float env = envelope(filter_count, FILTER_ATTACK, FILTER_DECAY, FILTER_SUSTAIN);
  
  float w0 = 6.28318530717959 * (*p(m_filter_cutoff) * env + 100) / sample_rate;
  float alpha = sin(w0)/4.; // 2 * Q,  Q va a ser constante, por ahora = 2
  float cosw0 = cos(w0);

  float lpf_a0 = 1 + alpha;
  float lpf_a1 = - 2 * cosw0 / lpf_a0;
  float lpf_a2 = (1 - alpha) / lpf_a0;
  float lpf_b1 = (1 - cosw0) / lpf_a0;
  float lpf_b0 = lpf_b1 / 2;

  float gain_factor = pow(10., *p(m_filter_resonance)/20.);
  float peak_w0 = 6.28318530717959 * (*p(m_filter_cutoff) * env + 100) * 0.9 / sample_rate;
  float peak_alpha = sin(peak_w0)/4.; // 2 * Q,  Q va a ser constante, por ahora = 2
  float cos_peak_w0 = cos(peak_w0);
  float peak_a0 = 1 + peak_alpha / gain_factor;
  float peak_a1 = -2 * cos_peak_w0 / peak_a0;
  float peak_a2 = (1 - peak_alpha / gain_factor) / peak_a0;
  float peak_b0 = (1 + peak_alpha * gain_factor) / peak_a0;
  float peak_b1 = - 2 * cos_peak_w0 / peak_a0;
  float peak_b2 = (1 - peak_alpha * gain_factor) / peak_a0;

  float* buffer = p(m_output);
  float* prev = prev_vals;

  //si se hizo make, se llama a equalizer en oscillators.c
  //si se hizo make asm, se llama a equalizer en oscillators.asm
  // equalizer(p(m_output), prev_vals, sample_count, lpf_b0, lpf_b1, - lpf_a2, - lpf_a1, peak_b2, peak_b1, -peak_a2, -peak_a1, peak_b0);
  equalizer(p(m_output), prev_vals, sample_count, lpf_b0, - lpf_a2, - lpf_a1, peak_b2, peak_b1, -peak_a2, -peak_a1, peak_b0);
}

static int _ = RaffoSynth::register_class(m_uri);
