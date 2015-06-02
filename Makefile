BUNDLE = raffo.lv2
INSTALL_DIR = /usr/local/lib/lv2
FLAGS = -O3 -std=c++11 -m64

ASM = nasm
DBG = gdb
#CFLAGS64 = -ggdb -Wall -std=c99 -pedantic -m64 -O0
CFLAGS = -std=c99 -m64 -O3
ASMFLAGS64 = -felf64 -F dwarf

#RAFFO_OBJ := if COMPILE_ASM then raffo_asm.o else raffo_c.o

cpp: oscillators_c $(BUNDLE)

asm: oscillators_asm $(BUNDLE)

$(BUNDLE): manifest.ttl raffo.ttl raffo.so raffo_gui.so oscillators.o
	rm -rf $(BUNDLE)
	mkdir $(BUNDLE)
	cp $^ $(BUNDLE)
#raffo.s: raffo.peg raffo.h tiempo.h raffo_asm.o raffo.o
#	g++ -shared -fPIC -DPIC raffo.o raffo_asm.o -o raffo.so

raffo.so: raffo.peg raffo.h tiempo.h raffo.cpp oscillators.o 
	g++ -shared -fPIC -DPIC $(FLAGS) raffo.cpp oscillators.o `pkg-config --cflags --libs lv2-plugin` -o raffo.so

oscillators_asm: raffo_asm.asm
	nasm -g -f elf64 raffo_asm.asm -o oscillators.o
	
oscillators_c: oscillators.c
	cc -c -fPIC $(CFLAGS) oscillators.c -o oscillators.o

raffo_gui.so: raffo_gui.cpp raffo.peg
	g++ -shared -fPIC -Wno-write-strings $(FLAGS) raffo_gui.cpp `pkg-config --cflags --libs lv2-gui` -o raffo_gui.so 
	
raffo.peg: raffo.ttl
	lv2peg raffo.ttl raffo.peg

	
install: $(BUNDLE)
	mkdir -p $(INSTALL_DIR)
	rm -rf $(INSTALL_DIR)/$(BUNDLE)
	cp -R $(BUNDLE) $(INSTALL_DIR)
	mkdir -p -m=777 $(INSTALL_DIR)/$(BUNDLE)/presets

clean:
	rm -rf $(BUNDLE) raffo.so raffo_gui.so raffo.peg raffo.o raffo_asm.o

.PHONY: install clean oscillators_c oscillators_asm
