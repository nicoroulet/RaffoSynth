usage="Usage: ./run.sh [-usb (midi input por cable midi)] | [-virtual (midi input por vkeybd)]"
if [ $# -eq 0 ]
  then
    echo $usage
    exit
fi
killall jackd
jackd -R -d alsa -r 44100 -p 256 &
sleep 1
jalv.gtk http://example.org/raffo &
sleep 1
a2jmidid -e &
sleep 1
case "$1" in
    -virtual) 
		vkeybd &
		sleep 1
		aconnect "Virtual Keyboard":0 "Midi Through":0
    ;;
    -usb) 
		aconnect "USB Midi":0 "Midi Through":0
    ;;
    *)
		echo $usage
esac 
    shift

jack_connect "Raffo Synth":output system:playback_1
jack_connect "a2j:Midi Through [14] (capture): Midi Through Port-0" "Raffo Synth":midi 
