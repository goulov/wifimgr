#!/bin/bash

SAVEDIR="/etc/wifimgr/" # directory where the profiles will be stored
PIDFILE="/tmp/wifimgr.pid" # pid file of wpa_supplicant
CONNFILE="/tmp/wifimgrconn" # file with the current connection

function usage {
    echo -e "options:"
    echo -e "\t scan"
    echo -e "\t connect \"plain/wep/wpa\" \"SSID\" [\"PASSWORD\"]"
    echo -e "\t save \"PROFILE\""
    echo -e "\t start \"PROFILE\""
    echo -e "\t stop"
    echo -e "\t status"
    echo -e "\t help"
    exit
}

# check if run as root
if [[ $EUID != 0 ]]; then
    echo "ERROR: must be run as root"
    exit 1
fi

# check dependencies
dependencies=("ip" "iw" "dhcpcd" "awk")
for dep in ${dependencies[@]}; do
    if [[ ! `command -v $dep` ]]; then
        echo "ERROR: dependency '$dep' not found"
        exit 1
    fi
done

# grab the wifi interface name
IFACE="`iw dev | awk '$1=="Interface"{print $2}'`"
if [[ -z $IFACE ]]; then
    echo "ERROR: could not find interface name"
    exit 1
fi

# check if no arguments provided
[[ $# == 0 ]] && usage

# check if SAVEDIR path exists or create it
[[ ! -d "$SAVEDIR" ]] && mkdir -p $SAVEDIR && chmod 700 $SAVEDIR

# start interface
ip link set $IFACE up

case $1 in
    connect)
        case $2 in
            plain)
                [[ $# != 3 ]] && usage
                CONN="network={\nssid=\"$3\"\nkey_mgmt=NONE\n}"
                ;;
            wep)
                [[ $# != 4 ]] && usage
                CONN="network={\nssid=\"$3\"\nkey_mgmt=NONE\nwep_key0=\"$4\"\nwep_tx_keyidx=0\n}"
                ;;
            wpa)
                [[ $# != 4 ]] && usage
                CONN="network={\nssid=\"$3\"\npsk=\"$4\"\n}"
                ;;
            *)
                usage
                ;;
        esac
        echo -e $CONN > $CONNFILE
        wpa_supplicant -B -P $PIDFILE -i $IFACE -c $CONNFILE
        dhcpcd $IFACE
        exit
        ;;

    save)
        [[ $# != 2 ]] && usage
        if [[ ! -f $CONNFILE ]]; then
            echo "ERROR: current profile not found, did you run 'connect' first?"
            exit 1
        fi
        cp $CONNFILE $SAVEDIR/$2
        exit
        ;;

    start)
        [[ $# != 2 ]] && usage
        if [[ ! -f "$SAVEDIR/$2" ]]; then
            echo "ERROR: profile $2 not found, did you use 'save' to save the profile?"
            exit 1
        fi
        wpa_supplicant -B -P $PIDFILE -i $IFACE -c "$SAVEDIR/$2"
        dhcpcd $IFACE
        exit
        ;;

    status)
        [[ $# != 1 ]] && usage
        iw dev $IFACE link
        exit
        ;;

    scan)
        [[ $# != 1 ]] && usage
        AWKQ='BEGIN {
                FS=":" # Everything except BSS is : separated.
            }
            substr($1, 0, 3) == "BSS" {
            #$1 == "BSS" {
                MAC = substr($1,5,6)":"$2":"$3":"$4":"$5":"substr($6,1,2)
                wifi[MAC]["enc"] = "Open"
                wifi[MAC]["SSID"] = "Hidden"
            }
            $1 == "\tSSID" {
                wifi[MAC]["SSID"] = $2
            }
            $1 == "\t\t * primary channel" {
                wifi[MAC]["channel"] = $2
            }
            $1 == "\tsignal" {
                split($2, a, " ")
                wifi[MAC]["sig"] = a[1]
            }
            $1 == "\tfreq" {
                wifi[MAC]["freq"] = $2
            }
            $1 == "\tWEP" {
                wifi[MAC]["enc"] = "WEP"
            }
            $1 == "\tWPA" {
                wifi[MAC]["enc"] = "WPA"
            }
            $1 == "\tRSN" {
                wifi[MAC]["enc"] = "WPA"
                wifi[MAC]["wpa2"] = "2"
            }
            $1 == "\tWPS" {
                wifi[MAC]["wps"] = "Yes"
            }
            END {
                fmt = "%s\t%-35s\t%s\t%s\t%s\t%s\n"
                printf fmt, " Signal", " SSID", "Enc", " Freq", " Ch", "WPS"
                printf "------------------------------------------------------------------------------\n"

                fmt = "%s\t%-35s\t%s%s\t%s\t%3s\t%s\n"
                for (w in wifi) {
                    printf fmt,  wifi[w]["sig"], wifi[w]["SSID"], wifi[w]["enc"], wifi[w]["wpa2"], wifi[w]["freq"], wifi[w]["channel"], wifi[w]["wps"]
                }
            }'
        iw dev $IFACE scan | awk "$AWKQ" | LC_ALL=C sort
        exit
        ;;

    stop)
        [[ $# != 1 ]] && usage
        [[ -f $PIDFILE ]] && kill `cat $PIDFILE`
        dhcpcd -k $IFACE
        [[ -f $CONNFILE ]] && rm $CONNFILE
        exit
        ;;

    help)
        usage
        ;;

    *)
        echo "ERROR: unknown argument $1"
        exit 1
        ;;

esac
