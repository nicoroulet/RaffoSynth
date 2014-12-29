#include <lv2synth.hpp>
#include "moog.peg"

class MoogSound : public LV2::Voice {
public:
  
  MoogSound(double rate) 
    : m_key(LV2::INVALID_KEY), m_rate(rate), m_period(10), m_counter(0) {
    
  }
protected:

  unsigned char m_key;
  double m_rate;
  uint32_t m_period;
  uint32_t m_counter;
  float m_envelope;
  
};


class MoogSynth : public LV2::Synth<MoogSound, MoogSynth> {
public:
	//MoogSynth(double rate){}
};

//static int _ = MoogSynth::register_class(m_uri);
