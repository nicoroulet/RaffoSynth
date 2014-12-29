#include <gtkmm.h>
#include <lv2gui.hpp>
#include "moog.peg"

using namespace sigc;
using namespace Gtk;

class MoogSynthGUI : public LV2::GUI<MoogSynthGUI> {
public:
  
	MoogSynthGUI(const std::string& URI) {
		Table* interfaz = manage(new Table(1, 3)); // tabla que contiene toda la interfaz
		Table* osciladores = manage(new Table(5, 4)); // subtablas
		Table* postprocesos = manage(new Table(8, 3));
		Table* params = manage(new Table(4,1));
		
		osciladores->attach(*manage(new Label("Range")), 1, 2, 0, 1);
		osciladores->attach(*manage(new Label("Waveform")), 2, 3, 0, 1);
		osciladores->attach(*manage(new Label("Volume")), 3, 4, 0, 1);
		osciladores->attach(*manage(new Label("Osc 0")), 0, 1, 1, 2);
		osciladores->attach(*manage(new Label("Osc 1")), 0, 1, 2, 3);
		osciladores->attach(*manage(new Label("Osc 2")), 0, 1, 3, 4);
		osciladores->attach(*manage(new Label("Osc 3")), 0, 1, 4, 5);
		
		for (int i=0; i<4; i++) {
			range[i] = manage(new HScale(m_ports[m_range0 + i].min, m_ports[m_range0+i].max, 1));
			wave[i] = manage(new HScale(m_ports[m_wave0 + i].min, m_ports[m_wave0+i].max, 1));
			vol[i] = manage(new HScale(m_ports[m_vol0 + i].min, m_ports[m_vol0+i].max, 0.01));
			
			range[i]->set_size_request(100, -1);
			wave[i]->set_size_request(100, -1);
			vol[i]->set_size_request(100, -1);
			
			range[i]->signal_value_changed().connect(compose(bind<0>(mem_fun(*this, &MoogSynthGUI::write_control), m_range0 + i), mem_fun(*range[i], &HScale::get_value)));
		 	
			wave[i]->signal_value_changed().connect(compose(bind<0>(mem_fun(*this, &MoogSynthGUI::write_control), m_wave0 + i), mem_fun(*wave[i], &HScale::get_value)));    	
			
			vol[i]->signal_value_changed().connect(compose(bind<0>(mem_fun(*this, &MoogSynthGUI::write_control), m_vol0 + i), mem_fun(*vol[i], &HScale::get_value)));
			
			osciladores->attach(*range[i], 1, 2, 1 + i*2, 2 + i*2);
			osciladores->attach(*wave[i], 2, 3, 1 + i*2, 2 + i*2);
			osciladores->attach(*vol[i], 3, 4, 1 + i*2, 2 + i*2);
			   	
		}
		
		postprocesos->attach(*manage(new Label("Filter")), 0, 3, 0, 1);
		postprocesos->attach(*manage(new Label("Cutoff")), 0, 1, 1, 2);
		postprocesos->attach(*manage(new Label("Attack")), 0, 1, 3, 4);
		postprocesos->attach(*manage(new Label("Decay")), 1, 2, 3, 4);
		postprocesos->attach(*manage(new Label("Sustain")), 2, 3, 3, 4);
		postprocesos->attach(*manage(new Label("Loudness")), 0, 3, 5, 6);
		postprocesos->attach(*manage(new Label("Attack")), 0, 1, 6, 7);
		postprocesos->attach(*manage(new Label("Decay")), 1, 2, 6, 7);
		postprocesos->attach(*manage(new Label("Sustain")), 2, 3, 6, 7);
		
		filter_cutoff = manage(new HScale(m_ports[m_filter_cutoff].min, m_ports[m_filter_cutoff].max, 0.01));
		filter_attack = manage(new HScale(m_ports[m_filter_attack].min, m_ports[m_filter_attack].max, 0.01));
		filter_decay = manage(new HScale(m_ports[m_filter_decay].min, m_ports[m_filter_decay].max, 0.01));
		filter_sustain = manage(new HScale(m_ports[m_filter_sustain].min, m_ports[m_filter_sustain].max, 0.01));
		attack = manage(new HScale(m_ports[m_attack].min, m_ports[m_attack].max, 0.01));
		decay = manage(new HScale(m_ports[m_decay].min, m_ports[m_decay].max, 0.01));
		sustain = manage(new HScale(m_ports[m_sustain].min, m_ports[m_sustain].max, 0.01));
		
		
		
		filter_cutoff->set_size_request(100, -1);
		filter_attack->set_size_request(100, -1);
		filter_decay->set_size_request(100, -1);
		filter_sustain->set_size_request(100, -1);
		attack->set_size_request(100, -1);
		decay->set_size_request(100, -1);
		sustain->set_size_request(100, -1);
		
		filter_cutoff->signal_value_changed().connect(compose(bind<0>(mem_fun(*this, &MoogSynthGUI::write_control), m_filter_cutoff), mem_fun(*filter_cutoff, &HScale::get_value)));
		filter_attack->signal_value_changed().connect(compose(bind<0>(mem_fun(*this, &MoogSynthGUI::write_control), m_filter_attack), mem_fun(*filter_attack, &HScale::get_value)));
		filter_decay->signal_value_changed().connect(compose(bind<0>(mem_fun(*this, &MoogSynthGUI::write_control), m_filter_decay), mem_fun(*filter_decay, &HScale::get_value)));
		filter_sustain->signal_value_changed().connect(compose(bind<0>(mem_fun(*this, &MoogSynthGUI::write_control), m_filter_sustain), mem_fun(*filter_sustain, &HScale::get_value)));
		attack->signal_value_changed().connect(compose(bind<0>(mem_fun(*this, &MoogSynthGUI::write_control), m_attack), mem_fun(*attack, &HScale::get_value)));
		decay->signal_value_changed().connect(compose(bind<0>(mem_fun(*this, &MoogSynthGUI::write_control), m_decay), mem_fun(*decay, &HScale::get_value)));
		sustain->signal_value_changed().connect(compose(bind<0>(mem_fun(*this, &MoogSynthGUI::write_control), m_sustain), mem_fun(*sustain, &HScale::get_value)));
		
		postprocesos->attach(*filter_cutoff, 2, 3, 0, 1);
		postprocesos->attach(*filter_attack, 4, 5, 0, 1);
		postprocesos->attach(*filter_decay, 4, 5, 1, 2);
		postprocesos->attach(*filter_sustain, 4, 5, 2, 3);
		postprocesos->attach(*attack, 7, 8, 0, 1);
		postprocesos->attach(*decay, 7, 8, 1, 2);
		postprocesos->attach(*sustain, 7, 8, 2, 3);
		
		/* falta params */
		
		interfaz->attach(*osciladores, 0, 1, 0, 1);
		interfaz->attach(*postprocesos, 0, 1, 1, 2);
	}
    
  /*
	void port_event(uint32_t port, uint32_t buffer_size, uint32_t format, const void* buffer) {
		if (port == p_width)
			w_scale->set_value(*static_cast<const float*>(buffer));
		else if (port == p_balance)
			b_scale->set_value(*static_cast<const float*>(buffer));
	}*/

	protected:

		HScale* range[4];

		HScale* wave[4];

		HScale* vol[4];

		HScale* filter_cutoff;
		HScale* filter_attack;
		HScale* filter_decay;
		HScale* filter_sustain;

		HScale* attack;
		HScale* decay;
		HScale* sustain;

	};


	static int _ = MoogSynthGUI::register_class("http://example.org/moog/gui");
