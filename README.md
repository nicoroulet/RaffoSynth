RaffoSynth
====

Dependencias:
Para compilar hace falta:
	- lv2-c++-tools
	- lv2peg
	- libgtkmm-2.4-1c2a

Comandos de compilación: 
	make && sudo make install - para instalar usando la implementacion pura en c++ 
	make asm && sudo make install - para instalar con las funciones de procesamiento de audio en asm
	
Comandos de ejecución:
	teniendo instalado vkeybd y jalv: ./run.sh
	utilizando cable MIDI y jalv: ./run.sh -u