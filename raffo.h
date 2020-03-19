#include <math.h>
#include <lv2plugin.hpp>
#include <lv2types.hpp>
#include <stdlib.h>

#include "lv2/lv2plug.in/ns/ext/atom/atom.h"
#include "lv2/lv2plug.in/ns/ext/atom/util.h"
#include "lv2/lv2plug.in/ns/ext/midi/midi.h"
#include "lv2/lv2plug.in/ns/ext/urid/urid.h"

#include <list>
#include <iostream>
#include <fstream>

#include "tiempo.h"

//#define EXPERIENCIA

using namespace std;

class RaffoSynth : public LV2::Plugin<RaffoSynth> //LV2::Synth<RaffoVoice, RaffoSynth> 
{
  
protected:
  
  double sample_rate;
  list<unsigned char> keys;
  uint32_t period; // periodo de la nota presionada
  float glide_period; // periodo que se esta reproduciendo
  
  float last_val[4];
  float pre_buf_end; // el valor del ultimo sample del buffer anterior
  float prev_vals[6]; // [in[n-2], in[n-1], lpf[n-2], lpf[n-1], peak[n-2], peak[n-1]]
  bool primer_nota;

  uint32_t counter;
  int envelope_count;
  int filter_count;
  float modwheel;
  float pitch;
  
  double glide;
  
  uint32_t midi_type;
  
#ifdef EXPERIENCIA
  Tiempo t_run;
  Tiempo t_osc;
  Tiempo t_eq;
  int run_count;
  
  ofstream output;
#endif

  void equ_wrapper(int sample_count);

public:
  typedef LV2::Plugin<RaffoSynth> Parent;
  
  RaffoSynth(double rate);

  void activate();
  void deactivate();

  void render(uint32_t from, uint32_t to);
  void handle_midi(uint32_t size, unsigned char* data);
  void run(uint32_t sample_count);
  
};
  
  
