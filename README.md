
RaffoSynth
====

This is a digital emulator of a minimoog synthesizer, built as an LV2 audio plugin for Linux.

## Documentation:
 * Documentation can be found in **RaffoSynth.pdf**. This includes development explanation and experimentation.

## Dependencies:
 * `lv2-c++-tools`
 * `lv2peg`
 * `libgtkmm-2.4-1c2a`

## Compile:
 Two implementations are available: a plain C++ implementation and an implementation that uses 64 bit Intel Assembly with SIMD instructions for data parallelism for the audio processing part, that improves performance by over 3x compared to fully optimized (-O3) C++ code.
 * `make && sudo make install` - install using pure C++ implementation
 * `make asm && sudo make install` - para instalar con las funciones de procesamiento de audio en asm

## Run:
The plugin can be loaded from any LV2 host (e.g. DAWs like Ardour).
It can also be executed as standalone, using [jalv](https://drobilla.net/software/jalv) host.
This can be combined with both an actual MIDI controller (like a MIDI keyboard) connected by a MIDI cable, and through [vkeybd](https://github.com/tiwai/vkeybd) virtual keyboard. The script `run.sh` handles the necessary setup and JACK connections for both this options.
 * Using vkeybd and jalv: `./run.sh`
 * Using MIDI cable and jalv: `./run.sh -u`
