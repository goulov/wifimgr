# wifimgr - wifi manager script
The goal is to have a very simple script to manage wifi, instead of very complicated solutions doing a lot of stuff I (and maybe others) don't need/want, and use it together with standard linux tools like `iproute2`.

## usage:

### setup
set `IFACE` and `SAVEDIR` in the script

### help screen
`# ./wifimgr.sh`

### connect to a AP (once, doesn't save the profile)
`# ./wifimgr.sh connect plain/wep/wpa SSID PASSWORD`

supports open, wep, and wpa APs

### save a profile for future use
`# ./wifimgr.sh save PROFILE_NAME SSID PASSWORD`

only works for wpa: saves a profile by creating a file named `PROFILE_NAME` in `SAVEDIR`

### scan for wifi APs
`# ./wifimgr.sh scan`

### connect to a saved profile
`# ./wifimgr.sh start PROFILE`

reads a profile from `SAVEDIR` (name of the file)

### status information for current link
`# ./wifimgr.sh stat`

### disconnect from a AP
`# ./wifimgr.sh stop`

## Dependencies:
- `awk`
- `dhcpcd` (easy to adapt to `dhclient` if preferred)
- `iproute2`
- `iw`
