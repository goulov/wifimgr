# wifimgr - WiFi manager script

A very simple script to manage WiFi connections

---

## Dependencies

- `awk`
- `dhcpcd`
- `iproute2`
- `iw`

---

## Scan for available networks

`# ./wifimgr.sh scan`

example output:
```
 Signal	 SSID                              	Enc	 Freq	 Ch	WPS
------------------------------------------------------------------------------
-65.00	 safenet2.4                        	WPA2	 2457	 10	Yes
-76.00	 safenet5                          	WPA2	 5500	 100
-81.00	 opennet                          	Open	 2462	 11
```

## Connect to an access point

`# ./wifimgr.sh connect PROTOCOL SSID [PASSWORD]`

connects to a network with the specified `SSID` and `PASSWORD`.

`PROTOCOL` is either:
- `plain` for open networks (without `PASSWORD`)
- `wep` for WEP networks
- `wpa` for WPA networks

## Save the access point currently connected to, with the name PROFILE

`# ./wifimgr.sh save PROFILE`

saves the current connection obtained with `connect` and stores it with the name `PROFILE`
(`connect` must be run first to be able to `save` a connection)

## Start previously saved PROFILE

`# ./wifimgr.sh start PROFILE`

connects to a previously saved connection with the name `PROFILE`
(`save` must be run first to be able to `start` a saved connection)

## Stop wifimgr and disconnect from the access point

`# ./wifimgr.sh stop`

stops a connection (releases DHCP lease and kills `wpa_supplicant`)

## Show connection status

`# ./wifimgr.sh status`

shows some information about the current connected access point

## Show help

`# ./wifimgr.sh help`

---

## Notes

- the directory where the profiles are saved can be modified by changing the variable `$SAVEDIR` in `wifimgr.sh` (default `/etc/wifimgr/`)
- `wifimgr` stores the WiFi SSIDs and passwords as plaintext files in the hard drive
- `wifimgr` was written to handle systems with a single WiFi interface (by default it uses the first one reported by `iw`)
