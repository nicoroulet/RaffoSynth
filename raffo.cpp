#include <lv2synth.hpp>
#include "raffo.peg"

class RaffoSound : public LV2::Voice {
public:
  
  RaffoSound(double rate) 
    : m_key(LV2::INVALID_KEY), m_rate(rate), m_period(10), m_counter(0) {
    
  }
protected:

  unsigned char m_key;
  double m_rate;
  uint32_t m_period;
  uint32_t m_counter;
  float m_envelope;
  
};


class RaffoSynth : public LV2::Synth<RaffoSound, RaffoSynth> {
public:
	RaffoSynth(double rate): 
		LV2::Synth<RaffoSound, RaffoSynth>(m_n_ports, m_midi) 
		
		 {}
};

static int _ = RaffoSynth::register_class(m_uri);
