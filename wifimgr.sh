#!/bin/bash

IFACE="wlan0"
SAVEDIR="/path"

function usage {
    echo -e "RUN AS R00T !";
    echo -e "Options:";
    echo -e "\t connect \"plain/wep/wpa\" \"SSID\" \"PASSWORD\"";
    echo -e "\t save \"PROFILE_NAME\" \"SSID\" \"PASSWORD\"";
    echo -e "\t scan";
    echo -e "\t start \"PROFILE\"";
    echo -e "\t stat";
    echo -e "\t stop";
    exit
}

if [[ "$#" == 0 ]]; then
    usage;
fi

if [[ "$1" == "connect" ]]; then
    if [[ "$#" == 4 ]]; then
        if [[ "$2" == "wpa" ]]; then
            ip link set $IFACE up;
            wpa_supplicant -B -i $IFACE -c <(wpa_passphrase "$3" "$4");
	        dhcpcd $IFACE;
        elif [[ "$2" == "wep" ]]; then
            ip link set $IFACE up;
            iw dev $IFACE connect "$3" key "0:$4";
	        dhcpcd $IFACE;
        else
            usage;
        fi
    elif [[ "$#" == 3 ]]; then
        if [[ "$2" == "plain" ]]; then
            ip link set $IFACE up;
            iw dev $IFACE connect "$3";
	        dhcpcd $IFACE;
        else
            usage;
        fi
    else
        usage;
    fi

elif [[ "$1" == "save" ]]; then
    if [[ "$#" == 4 ]]; then
        if [[ ! -f "$SAVEDIR/$2" ]]; then
            wpa_passphrase "$3" "$4" >> "$SAVEDIR/$2";
        else
            echo "FILE ALREADY EXISTS !";
            usage;
        fi
    else
        usage;
    fi

elif [[ "$1" == "start" ]]; then
    if [[ "$#" == 2 ]]; then
        ip link set $IFACE up;
	    wpa_supplicant -B -i $IFACE -c "$SAVEDIR/$2";
	    #sleep 3s;
	    dhcpcd $IFACE;
    else
        usage;
    fi

elif [[ "$1" == "stat" ]]; then
    if [[ "$#" == 1 ]]; then
        iw dev $IFACE link;
    else
        usage;
    fi

elif [[ "$1" == "stop" ]]; then
    if [[ "$#" == 1 ]]; then
        dhcpcd -k $IFACE;
        killall wpa_supplicant;
        ip link set $IFACE down;
    else
        usage;
    fi

elif [[ "$1" == "scan" ]]; then
    if [[ "$#" == 1 ]]; then
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
        ip link set $IFACE up;
        iw dev wlan0 scan | awk "$AWKQ" | LC_ALL=C sort;
    else
        usage;
    fi

else
    usage;
fi

