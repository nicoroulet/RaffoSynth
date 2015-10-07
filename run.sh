killall jackd
jackd -R -d alsa -r 44100 -p 256 &
sleep 1
jalv.gtk http://example.org/raffo &
sleep 1
a2jmidid -e &
sleep 1
aconnect "USB Midi":0 "Midi Through":0
jack_connect "Raffo Synth":output system:playback_1
jack_connect "a2j:Midi Through [14] (capture): Midi Through Port-0" "Raffo Synth":midi 
