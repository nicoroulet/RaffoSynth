usage="opciones: 
    \n\t -u|--usb: midi input por cable midi (default: midi input por vkeybd)
    \n\t -r|--rate <value>: setear valor de frecuencia de muestreo (default: 44100) valores posibles: {44100, 48000, 96000...}
    \n\t -p|--period <value>: setear buffer size (default: 256) usar potencias de 2"

mode=virtual
rate=44100
buf=256
while [[ $# > 0 ]]
do
    key="$1"

    case $key in
        -u|--usb)
        mode=usb
        ;;
        -r|--rate)
        rate="$2"
        shift
        ;;
        -p|--period)
        buf="$2"
        shift 
        ;;
        -h|--help)
        echo -e $usage
        exit
        ;;
        *)
        ;;
    esac
    shift
done
killall jackd
jackd -R -d alsa -r $rate -p $buf &
sleep 1
jalv.gtk http://example.org/raffo & 
plugin="$(echo $!)"
sleep 1
a2jmidid -e &
sleep 1

case $mode in
    virtual) 
		vkeybd &
		sleep 1
		aconnect "Virtual Keyboard":0 "Midi Through":0
    ;;
    usb) 
		aconnect "USB Midi":0 "Midi Through":0
    ;;
esac 
jack_connect "Raffo Synth":output system:playback_1
jack_connect "Raffo Synth":output system:playback_2
jack_connect "a2j:Midi Through [14] (capture): Midi Through Port-0" "Raffo Synth":midi 

echo "Press <q> to quit"

while :
do
    read -n 1 esc
    if [[ $esc = q ]]
    then
        break
    fi
done
kill -9 $plugin
killall jackd
killall vkeybd