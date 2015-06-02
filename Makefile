BUNDLE = raffo.lv2
INSTALL_DIR = /usr/local/lib/lv2
FLAGS = -O3 -std=c++11

ASM = nasm
DBG = gdb
CFLAGS64 = -ggdb -Wall -std=c99 -pedantic -m64 -O0
ASMFLAGS64 = -felf64 -g -F dwarf
COMPILE_ASM = 0

RAFFO_OBJ := if COMPILE_ASM then raffo_asm.o else raffo_c.o

$(BUNDLE): manifest.ttl raffo.ttl raffo.so raffo_gui.so raffo_asm.o Makefile
	rm -rf $(BUNDLE)
	mkdir $(BUNDLE)
	cp $^ $(BUNDLE)

#raffo.s: raffo.peg raffo.h tiempo.h raffo_asm.o raffo.o
#	g++ -shared -fPIC -DPIC raffo.o raffo_asm.o -o raffo.so

raffo.so: raffo.peg raffo.h tiempo.h raffo_asm.o raffo.cpp
	g++ -shared -fPIC -DPIC $(FLAGS) raffo.cpp raffo_asm.o `pkg-config --cflags --libs lv2-plugin` -o raffo.so

raffo_asm.o: raffo_asm.asm
	nasm -g -f elf64 raffo_asm.asm -o raffo_asm.o

raffo_gui.so: raffo_gui.cpp raffo.peg
	g++ -shared -fPIC -DPIC -Wno-write-strings $(FLAGS) raffo_gui.cpp `pkg-config --cflags --libs lv2-gui` -o raffo_gui.so 
	
raffo.peg: raffo.ttl
	lv2peg raffo.ttl raffo.peg

#defines:
#	compile_asm=1
#	COMPILE_ASM=1
	
install: $(BUNDLE)
	mkdir -p $(INSTALL_DIR)
	rm -rf $(INSTALL_DIR)/$(BUNDLE)
	cp -R $(BUNDLE) $(INSTALL_DIR)

clean:
	rm -rf $(BUNDLE) raffo.so raffo_gui.so raffo.peg raffo.o raffo_asm.o
