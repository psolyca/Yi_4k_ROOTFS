#!/bin/sh

# Keeping the same wifi0_mac until reboot.
if [ -e /tmp/wifi0_mac ]; then
	exit
fi

mac=`cat /proc/ambarella/board_info  | grep wifi_mac | awk '{ print $2 }' | tr '[:lower:]' '[:upper:]'`
if [ "${mac}" == "00:00:00:00:00:00" ] ||  [ "${mac}" == "" ]; then
	# TODO: from ROM or random?
	mac=`printf "58:70:C6:%02X:%02X:%02X" $(($RANDOM % 256)) $(($RANDOM % 256)) $(($RANDOM % 256))`
fi

echo $mac > /tmp/wifi0_mac

