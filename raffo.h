#include <math.h>
#include <lv2plugin.hpp>
#include <lv2_event_helpers.h>
#include <lv2_uri_map.h>
#include <lv2types.hpp>
#include <stdlib.h>

#include <list>
#include <iostream>

#include "tiempo.h"

using namespace std;

class RaffoSynth : public LV2::Plugin<RaffoSynth, LV2::URIMap<true> > //LV2::Synth<RaffoVoice, RaffoSynth> 
{
  
protected:
  
  double sample_rate;
  double dt; // (1/sample_rate)
  list<unsigned char> keys;
  uint32_t period; // periodo de la nota presionada
  float glide_period; // periodo que se esta reproduciendo
  
  float last_val;
  float pre_buf_end; // el valor del ultimo sample del buffer anterior
  float prev_vals[6]; // [in[n-2], in[n-1], lpf[n-2], lpf[n-1], peak[n-2], peak[n-1]]
  
  uint32_t counter;
  int envelope_count;
  int filter_count;
  float modwheel;
  float pitch;
  
  double glide;
  
  uint32_t midi_type;
  
  Tiempo t_run;
  Tiempo t_osc;
  Tiempo t_eq;
  int run_count;

  
  static inline float key2hz(unsigned char key) {
    return 8.1758 * pow(1.0594, key);
  }

  float min_fact(float a, float b) {
    return ((fabs(a-1) > fabs(b-1))? b: a);
  }

  float envelope(int count, float a, float d, float s) { // zapato: esto seria mas eficiente con un define?
    
    
    float c1 = (1.-s)/(2.*d);
    float c2 = 1./(2.*a);
    float env = (s - c1 * (count - a - d - fabs(count - a - d)) + 
           (c2 + c1) * (count - a - fabs(count - a))) ;
    return env * (env>0);
  }
  
  void ir(int sample_count);

public:
  typedef LV2::Plugin<RaffoSynth, LV2::URIMap<true> > Parent;
  
  RaffoSynth(double rate);
  void render(uint32_t from, uint32_t to);
  void handle_midi(uint32_t size, unsigned char* data);
  void run(uint32_t sample_count);
  
};
  
  
