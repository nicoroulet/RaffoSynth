BUNDLE = raffo.lv2
INSTALL_DIR = /usr/local/lib/lv2
RAFFO_CXXFLAGS = -O3 -std=c++11 $(CXXFLAGS)

ASM = nasm
DBG = gdb
#CFLAGS64 = -ggdb -Wall -std=c99 -m64 -O0
RAFFO_CFLAGS = -std=c99 -O3 $(CFLAGS)
ASMFLAGS64 = -felf64 -F dwarf

#RAFFO_OBJ := if COMPILE_ASM then raffo_asm.o else raffo_c.o

cpp: oscillators_c equalizer_c $(BUNDLE)

asm: oscillators_asm equalizer_asm $(BUNDLE)

equasm: oscillators_c equalizer_asm $(BUNDLE)

oscasm: oscillators_asm equalizer_c $(BUNDLE)

$(BUNDLE): manifest.ttl raffo.ttl raffo.so raffo_gui.so
	rm -rf $(BUNDLE)
	mkdir $(BUNDLE)
	cp $^ $(BUNDLE)
#raffo.s: raffo.peg raffo.h tiempo.h raffo_asm.o raffo.o
#	g++ -shared -fPIC -DPIC raffo.o raffo_asm.o -o raffo.so

raffo.so: raffo.peg raffo.h tiempo.h raffo.cpp oscillators.o equalizer.o
	g++ -shared -fPIC -DPIC $(RAFFO_CXXFLAGS) raffo.cpp oscillators.o equalizer.o `pkg-config --cflags --libs lv2-plugin` -o raffo.so

equalizer_asm: equalizer.asm
	nasm -g -f elf64 equalizer.asm -o equalizer.o

equalizer_c: equalizer.c
	gcc -c -fPIC $(RAFFO_CFLAGS) equalizer.c -o equalizer.o

oscillators_asm: oscillators.asm
	nasm -g -f elf64 oscillators.asm -o oscillators.o
	
oscillators_c: oscillators.c
	gcc -c -fPIC $(RAFFO_CFLAGS) oscillators.c -o oscillators.o

raffo_gui.so: raffo_gui.cpp raffo.peg
	g++ -shared -fPIC -Wno-write-strings $(RAFFO_CXXFLAGS) raffo_gui.cpp `pkg-config --cflags --libs lv2-gui` -o raffo_gui.so 
	
raffo.peg: raffo.ttl
	lv2peg raffo.ttl raffo.peg

install: $(BUNDLE)
	mkdir -p $(INSTALL_DIR)
	rm -f $(INSTALL_DIR)/$(BUNDLE)/*.so $(INSTALL_DIR)/$(BUNDLE)/*.ttl
	mkdir -p -m=777 $(INSTALL_DIR)/$(BUNDLE)/presets
	cp -R $(BUNDLE) $(INSTALL_DIR)


clean:
	rm -rf $(BUNDLE) raffo.so raffo_gui.so raffo.peg raffo.o oscillators.o equalizer.o

uninstall: 
	rm -rf $(INSTALL_DIR)/$(BUNDLE)


.PHONY: install clean oscillators_c oscillators_asm equalizer_c equalizer_asm
