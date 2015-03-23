NAME = raffo
BUNDLE = $(NAME).lv2
INSTALL_DIR = /usr/local/lib/lv2
FLAGS = -O2 -std=c++11


$(BUNDLE): manifest.ttl $(NAME).ttl $(NAME).so $(NAME)_gui.so Makefile
	rm -rf $(BUNDLE)
	mkdir $(BUNDLE)
	cp $^ $(BUNDLE)

$(NAME).so: $(NAME).cpp $(NAME).peg $(NAME).h fft.h
	g++ -shared -fPIC -DPIC $(FLAGS) $(NAME).cpp `pkg-config --cflags --libs lv2-plugin` -o $(NAME).so

$(NAME)_gui.so: $(NAME)_gui.cpp $(NAME).peg
	g++ -shared -fPIC -DPIC -Wno-write-strings $(FLAGS) $(NAME)_gui.cpp `pkg-config --cflags --libs lv2-gui` -o $(NAME)_gui.so
	
$(NAME).peg: $(NAME).ttl
	lv2peg $(NAME).ttl $(NAME).peg

install: $(BUNDLE)
	mkdir -p $(INSTALL_DIR)
	rm -rf $(INSTALL_DIR)/$(BUNDLE)
	cp -R $(BUNDLE) $(INSTALL_DIR)

clean:
	rm -rf $(BUNDLE) $(NAME).so $(NAME)_gui.so $(NAME).peg

