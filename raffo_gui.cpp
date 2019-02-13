#include "raffo_gui.h"

RaffoSynthGUI::RaffoSynthGUI(const std::string& URI) {
	Table* interfaz = manage(new Table(2, 4)); // tabla que contiene toda la interfaz
	Table* osciladores = manage(new Table(5, 4)); // subtablas
	Table* modificadores = manage(new Table(8, 3));
	Table* params = manage(new Table(4,1));
	
	interfaz->set_border_width(16);
	interfaz->set_spacings(6);
	
	osciladores->attach(*manage(new Label("Range")), 1, 2, 0, 1);
	osciladores->attach(*manage(new Label("Waveform")), 2, 3, 0, 1);
	osciladores->attach(*manage(new Label("Volume")), 3, 4, 0, 1);
	osciladores->attach(*manage(new Label("Frequency")), 4, 5, 0, 1);
	osciladores->attach(*manage(new Label("Osc 0")), 0, 1, 1, 2);
	osciladores->attach(*manage(new Label("Osc 1")), 0, 1, 2, 3);
	osciladores->attach(*manage(new Label("Osc 2")), 0, 1, 3, 4);
	osciladores->attach(*manage(new Label("Osc 3")), 0, 1, 4, 5);
	
	for (int i=0; i<4; i++) {
		range[i] = manage(new HScale(m_ports[m_range0 + i].min, m_ports[m_range0+i].max, 1));
		Table* wavetable = manage(new Table(2,1));
		wave_label[i] = manage(new Label(waveshapes[i]));
		wavetable->attach(*wave_label[i], 0, 1, 0, 1);
		wave[i] = manage(new HScale(m_ports[m_wave0 + i].min, m_ports[m_wave0+i].max, 1));
		wavetable->attach(*wave[i], 0, 1, 1, 2);
		vol[i] = manage(new HScale(m_ports[m_vol0 + i].min, m_ports[m_vol0+i].max, 0.01));
		oscButton[i] = manage(new VScale(m_ports[m_oscButton0 + i].min, m_ports[m_oscButton0+i].max, 1));
		oscButton[i]->set_inverted(true);

		oscTuning[i] = manage(new HScale(m_ports[m_tuning0 + i].min, m_ports[m_tuning0+i].max, 0.01));
		
		range[i]->set_size_request(100, 50);
		wave[i]->set_size_request(100, 35);
		wave_label[i]->set_size_request(100, 15);
		vol[i]->set_size_request(100, 50);
		oscButton[i]->set_size_request(100, 50);
		oscTuning[i]->set_size_request(100, 50);
		
		range[i]->signal_value_changed().connect(compose(bind<0>(mem_fun(*this, &RaffoSynthGUI::write_control), m_range0 + i), mem_fun(*range[i], &HScale::get_value)));
	 	
		wave[i]->signal_value_changed().connect(compose(bind<0>(mem_fun(*this, &RaffoSynthGUI::write_waveshape), m_wave0 + i), mem_fun(*wave[i], &HScale::get_value)));
		
		vol[i]->signal_value_changed().connect(compose(bind<0>(mem_fun(*this, &RaffoSynthGUI::write_control), m_vol0 + i), mem_fun(*vol[i], &HScale::get_value)));
		
		oscButton[i]->signal_value_changed().connect(compose(bind<0>(mem_fun(*this, &RaffoSynthGUI::write_control), m_oscButton0 + i), mem_fun(*oscButton[i], &VScale::get_value)));

		oscTuning[i]->signal_value_changed().connect(compose(bind<0>(mem_fun(*this, &RaffoSynthGUI::write_control), m_tuning0 + i), mem_fun(*oscTuning[i], &HScale::get_value)));

		wave[i]->set_draw_value(false);
		

		osciladores->attach(*range[i], 1, 2, 1 + i, 2 + i);
		osciladores->attach(*wavetable, 2, 3, 1 + i, 2 + i);
		osciladores->attach(*vol[i], 3, 4, 1 + i, 2 + i);			   	
		osciladores->attach(*oscButton[i], 5, 6, 1 + i, 2 + i);			   				   	
		osciladores->attach(*oscTuning[i], 4, 5, 1 + i, 2 + i);			   				   	
	}

	
	modificadores->attach(*manage(new Label("Filter")), 0, 3, 0, 1);
	modificadores->attach(*manage(new Label("Cutoff")), 0, 1, 1, 2);
	modificadores->attach(*manage(new Label("Resonance")), 2, 3, 1, 2);
	modificadores->attach(*manage(new Label("Attack")), 0, 1, 3, 4);
	modificadores->attach(*manage(new Label("Decay")), 1, 2, 3, 4);
	modificadores->attach(*manage(new Label("Sustain")), 2, 3, 3, 4);
	modificadores->attach(*manage(new Label("Release")), 3, 4, 3, 4);
	modificadores->attach(*manage(new Label("Loudness")), 0, 4, 5, 6);
	modificadores->attach(*manage(new Label("Attack")), 0, 1, 6, 7);
	modificadores->attach(*manage(new Label("Decay")), 1, 2, 6, 7);
	modificadores->attach(*manage(new Label("Sustain")), 2, 3, 6, 7);
	modificadores->attach(*manage(new Label("Release")), 3, 4, 6, 7);
	
	filter_cutoff = manage(new HScale(m_ports[m_filter_cutoff].min, m_ports[m_filter_cutoff].max, 1));
	filter_attack = manage(new HScale(m_ports[m_filter_attack].min, m_ports[m_filter_attack].max, 1));
	filter_decay = manage(new HScale(m_ports[m_filter_decay].min, m_ports[m_filter_decay].max, 1));
	filter_sustain = manage(new HScale(m_ports[m_filter_sustain].min, m_ports[m_filter_sustain].max, 0.01));
	filter_release = manage(new HScale(m_ports[m_filter_release].min, m_ports[m_filter_release].max, 0.01));
	filter_resonance = manage(new HScale(m_ports[m_filter_resonance].min, m_ports[m_filter_resonance].max, 0.01));


	attack = manage(new HScale(m_ports[m_attack].min, m_ports[m_attack].max, 1));
	decay = manage(new HScale(m_ports[m_decay].min, m_ports[m_decay].max, 1));
	sustain = manage(new HScale(m_ports[m_sustain].min, m_ports[m_sustain].max, 0.01));
	release = manage(new HScale(m_ports[m_release].min, m_ports[m_release].max, 0.01));
	
	
	filter_cutoff->set_size_request(100, -1);
	filter_attack->set_size_request(100, -1);
	filter_decay->set_size_request(100, -1);
	filter_sustain->set_size_request(100, -1);
	filter_release->set_size_request(100, -1);
	filter_resonance->set_size_request(100, -1);

	attack->set_size_request(100, -1);
	decay->set_size_request(100, -1);
	sustain->set_size_request(100, -1);
	release->set_size_request(100, -1);
	
	filter_cutoff->signal_value_changed().connect(compose(bind<0>(mem_fun(*this, &RaffoSynthGUI::write_control), m_filter_cutoff), mem_fun(*filter_cutoff, &HScale::get_value)));
	filter_attack->signal_value_changed().connect(compose(bind<0>(mem_fun(*this, &RaffoSynthGUI::write_control), m_filter_attack), mem_fun(*filter_attack, &HScale::get_value)));
	filter_decay->signal_value_changed().connect(compose(bind<0>(mem_fun(*this, &RaffoSynthGUI::write_control), m_filter_decay), mem_fun(*filter_decay, &HScale::get_value)));
	filter_sustain->signal_value_changed().connect(compose(bind<0>(mem_fun(*this, &RaffoSynthGUI::write_control), m_filter_sustain), mem_fun(*filter_sustain, &HScale::get_value)));
	filter_release->signal_value_changed().connect(compose(bind<0>(mem_fun(*this, &RaffoSynthGUI::write_control), m_filter_release), mem_fun(*filter_release, &HScale::get_value)));
	filter_resonance->signal_value_changed().connect(compose(bind<0>(mem_fun(*this, &RaffoSynthGUI::write_control), m_filter_resonance), mem_fun(*filter_resonance, &HScale::get_value)));

	attack->signal_value_changed().connect(compose(bind<0>(mem_fun(*this, &RaffoSynthGUI::write_control), m_attack), mem_fun(*attack, &HScale::get_value)));
	decay->signal_value_changed().connect(compose(bind<0>(mem_fun(*this, &RaffoSynthGUI::write_control), m_decay), mem_fun(*decay, &HScale::get_value)));
	sustain->signal_value_changed().connect(compose(bind<0>(mem_fun(*this, &RaffoSynthGUI::write_control), m_sustain), mem_fun(*sustain, &HScale::get_value)));
	release->signal_value_changed().connect(compose(bind<0>(mem_fun(*this, &RaffoSynthGUI::write_control), m_release), mem_fun(*release, &HScale::get_value)));
	
	modificadores->attach(*filter_cutoff, 0, 1, 2, 3);
	modificadores->attach(*filter_attack, 0, 1, 4, 5);
	modificadores->attach(*filter_decay, 1, 2, 4, 5);
	modificadores->attach(*filter_sustain, 2, 3, 4, 5);
	modificadores->attach(*filter_release, 3, 4, 4, 5);
	modificadores->attach(*filter_resonance, 2, 3, 2, 3);

	modificadores->attach(*attack, 0, 1, 7, 8);
	modificadores->attach(*decay, 1, 2, 7, 8);
	modificadores->attach(*sustain, 2, 3, 7, 8);
	modificadores->attach(*release, 3, 4, 7, 8);
	
	
	glide = manage(new VScale(m_ports[m_glide].min, m_ports[m_glide].max, 0.01));
	glide->signal_value_changed().connect(compose(bind<0>(mem_fun(*this, &RaffoSynthGUI::write_control), m_glide), mem_fun(*glide, &HScale::get_value)));
	glide->set_inverted(true);
	
	volume = manage(new VScale(m_ports[m_volume].min, m_ports[m_volume].max, 0.01));
	volume->signal_value_changed().connect(compose(bind<0>(mem_fun(*this, &RaffoSynthGUI::write_control), m_volume), 	mem_fun(*volume, &HScale::get_value)));
	volume->set_inverted(true);
	
	Frame* f_glide = manage(new Frame("Glide"));
	f_glide->add(*glide);
	Frame* f_osc = manage(new Frame("Oscillators"));
	f_osc->add(*osciladores);
	Frame* f_mod = manage(new Frame("Modifiers"));
	f_mod->add(*modificadores);
	Frame* f_vol = manage(new Frame("Volume"));
	f_vol->add(*volume);
	
	Button* save = manage(new Button("Save"));
	Button* load = manage(new Button("Load"));
	
	filename = manage(new Entry());
	
	save->signal_clicked().connect(mem_fun(*this, &RaffoSynthGUI::save_preset));
	
	load->signal_clicked().connect(mem_fun(*this, &RaffoSynthGUI::load_preset));
	
	Table* presets = manage(new Table(1,3));
	presets->attach(*save, 0, 1, 0, 1);
	presets->attach(*filename, 1, 2, 0, 1);
	presets->attach(*load, 2, 3, 0, 1);

	interfaz->attach(*f_glide, 0, 1, 1, 2);
	interfaz->attach(*f_osc, 1, 2, 1, 2);
	interfaz->attach(*f_mod, 2, 3, 1, 2);
	interfaz->attach(*f_vol, 3, 4, 1, 2);
	interfaz->attach(*presets, 2, 3, 0, 1);
	
	add(*interfaz);
}
	
void RaffoSynthGUI::port_event(uint32_t port, uint32_t buffer_size, uint32_t format, const void* buffer) {
	switch (port) {
		case (m_wave0): {
			wave[0]->set_value(*static_cast<const float*>(buffer));
			wave_label[0]->set_text(waveshapes[(int)wave[0]->get_value()]);
			break;
		}
		case (m_wave1):{
			wave[1]->set_value(*static_cast<const float*>(buffer));
			wave_label[1]->set_text(waveshapes[(int)wave[1]->get_value()]);
			break;
		}
		case (m_wave2):{
			wave[2]->set_value(*static_cast<const float*>(buffer));
			wave_label[2]->set_text(waveshapes[(int)wave[2]->get_value()]);
			break;
		}
		case (m_wave3):{
			wave[3]->set_value(*static_cast<const float*>(buffer));
			wave_label[3]->set_text(waveshapes[(int)wave[3]->get_value()]);
			break;
		}
		case (m_range0): {
			range[0]->set_value(*static_cast<const float*>(buffer));
			break;
		}
		case (m_range1): {
			range[1]->set_value(*static_cast<const float*>(buffer));
			break;
		}
		case (m_range2): {
			range[2]->set_value(*static_cast<const float*>(buffer));
			break;
		}
		case (m_range3): {
			range[3]->set_value(*static_cast<const float*>(buffer));
			break;
		}
		case (m_vol0): {
			vol[0]->set_value(*static_cast<const float*>(buffer));
			break;
		}
		case (m_vol1): {
			vol[1]->set_value(*static_cast<const float*>(buffer));
			break;
		}
		case (m_vol2): {
			vol[2]->set_value(*static_cast<const float*>(buffer));
			break;
		}
		case (m_vol3): {
			vol[3]->set_value(*static_cast<const float*>(buffer));
			break;
		}
		case (m_attack): {
			attack->set_value(*static_cast<const float*>(buffer));
			break;
		}
		case (m_decay): {
			decay->set_value(*static_cast<const float*>(buffer));
			break;
		}
		case (m_sustain): {
			sustain->set_value(*static_cast<const float*>(buffer));
			break;
		}
		case (m_release): {
			release->set_value(*static_cast<const float*>(buffer));
			break;
		}
		case (m_filter_cutoff): {
			filter_cutoff->set_value(*static_cast<const float*>(buffer));
			break;
		}
		case (m_filter_attack): {
			filter_attack->set_value(*static_cast<const float*>(buffer));
			break;
		}
		case (m_filter_decay): {
			filter_decay->set_value(*static_cast<const float*>(buffer));
			break;
		}
		case (m_filter_sustain): {
			filter_sustain->set_value(*static_cast<const float*>(buffer));
			break;
		}
		case (m_filter_resonance): {
			filter_resonance->set_value(*static_cast<const float*>(buffer));
			break;
		}
		case (m_volume): {
			volume->set_value(*static_cast<const float*>(buffer));
			break;
		}
		case (m_glide): {
			glide->set_value(*static_cast<const float*>(buffer));
			break;
		}
		case (m_oscButton0): {
			oscButton[0]->set_value(*static_cast<const float*>(buffer));
			break;
		}
		case (m_oscButton1): {
			oscButton[1]->set_value(*static_cast<const float*>(buffer));
			break;
		}
		case (m_oscButton2): {
			oscButton[2]->set_value(*static_cast<const float*>(buffer));
			break;
		}
		case (m_oscButton3): {
			oscButton[3]->set_value(*static_cast<const float*>(buffer));
			break;
		}
		case (m_tuning0): {
			oscTuning[0]->set_value(*static_cast<const float*>(buffer));
			break;
		}
		case (m_tuning1): {
			oscTuning[1]->set_value(*static_cast<const float*>(buffer));
			break;
		}
		case (m_tuning2): {
			oscTuning[2]->set_value(*static_cast<const float*>(buffer));
			break;
		}
		case (m_tuning3): {
			oscTuning[3]->set_value(*static_cast<const float*>(buffer));
			break;
		}
		case (m_filter_release): {
			filter_release->set_value(*static_cast<const float*>(buffer));
			break;
		}
	}
}

void RaffoSynthGUI::save_preset() {
	string s = PRESET_FOLDER;
	s += filename->get_buffer()->get_text();
	s += ".dat";
	cout << s << endl;
	ofstream f;
	f.open(s.c_str());
	for (int i = 0; i < 4; ++i)
	{
		f << oscButton[i]->get_value() << " ";
		f << range[i]->get_value() << " ";
		f << oscTuning[i]->get_value() << " ";
		f << wave[i]->get_value() << " ";
		f << vol[i]->get_value() << " ";
	}
	f << filter_cutoff->get_value() << " ";
	f << filter_attack->get_value() << " ";
	f << filter_decay->get_value() << " ";
	f << filter_sustain->get_value() << " ";
	f << filter_release->get_value() << " ";
	f << filter_resonance->get_value() << " ";
	
	f << attack->get_value() << " ";
	f << decay->get_value() << " ";
	f << sustain->get_value() << " ";
	f << release->get_value() << " ";
	
	f << glide->get_value() << " ";
	f << volume->get_value() << " ";
	
	f.close();
}

void RaffoSynthGUI::load_preset(){
	FileChooserDialog dialog("Select preset", FILE_CHOOSER_ACTION_OPEN);
	dialog.add_button("_Cancel", RESPONSE_CANCEL);
	dialog.add_button("_Open", RESPONSE_OK);
	dialog.add_shortcut_folder(PRESET_FOLDER);
	dialog.set_current_folder(PRESET_FOLDER);
	if (dialog.run() != RESPONSE_OK) return;
	
	string filename = dialog.get_filename();
	cout << filename << endl;
	ifstream f;
	f.open(filename.c_str());
	float aux;
	for (int i = 0; i < 4; ++i)
	{
		f >> aux;
		write_control(m_oscButton0 + i, aux);
		f >> aux;
		write_control(m_range0 + i, aux);
		f >> aux;
		write_control(m_tuning0 + i, aux);
		f >> aux;
		write_control(m_wave0 + i, aux);
		f >> aux;
		write_control(m_vol0 + i, aux);
	}
	f >> aux;
	write_control(m_filter_cutoff, aux);
	f >> aux;
	write_control(m_filter_attack, aux);
	f >> aux;
	write_control(m_filter_decay, aux);
	f >> aux;
	write_control(m_filter_sustain, aux);
	f >> aux;
	write_control(m_filter_release, aux);
	f >> aux;
	write_control(m_filter_resonance, aux);
	
	f >> aux;
	write_control(m_attack, aux);
	f >> aux;
	write_control(m_decay, aux);
	f >> aux;
	write_control(m_sustain, aux);
	f >> aux;
	write_control(m_release, aux);
	
	f >> aux;
	write_control(m_glide, aux);
	f >> aux;
	write_control(m_volume, aux);
	
	f.close();
	
}

void RaffoSynthGUI::write_waveshape(int control, int shape)
{
	wave_label[control - m_wave0]->set_text(waveshapes[shape]);
	write_control(control, shape);
}

static int _ = RaffoSynthGUI::register_class("http://example.org/raffo/gui");
