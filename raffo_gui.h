#include <gtkmm.h>
#include <vector>
#include <fstream>
#include <iostream>

#include <lv2gui.hpp>
#include "raffo.peg"

using namespace sigc;
using namespace Gtk;

using namespace std;

#define PRESET_FOLDER "/usr/local/lib/lv2/raffo.lv2/presets/" 

class RaffoSynthGUI : public LV2::GUI<RaffoSynthGUI> {
public:

  	
	RaffoSynthGUI(const std::string& URI);
	void port_event(uint32_t port, uint32_t buffer_size, uint32_t format, const void* buffer);
	void save_preset();
	void load_preset();
protected:

	VScale* oscButton[4];

	HScale* range[4];

	HScale* oscTuning[4];

	HScale* wave[4];

	Label* wave_label[4];

	HScale* vol[4];

	HScale* filter_cutoff;
	HScale* filter_attack;
	HScale* filter_decay;
	HScale* filter_sustain;
	HScale* filter_release;
	HScale* filter_resonance;


	HScale* attack;
	HScale* decay;
	HScale* sustain;
	HScale* release;
	
	VScale* glide;
	VScale* volume;
	
	Entry* filename;
	
	char* waveshapes[4] = {"Triangle", "Saw", "Square", "Pulse"};
	void write_waveshape(int control, int shape);

	//static char* format_value(GtkScale *scale, int value){
     //   return str("-->%d<--", value);}
	
};

