RaffoSynth
====

##Dependencies:
-lv2-c++-tools
-lv2peg
-libgtkmm-2.4-1c2a

##Compile:
-make && sudo make install - para instalar usando la implementacion pura en c++
-make asm && sudo make install - para instalar con las funciones de procesamiento de audio en asm

##Run:
-teniendo instalado vkeybd y jalv: ./run.sh
-utilizando cable MIDI y jalv: ./run.sh -u
