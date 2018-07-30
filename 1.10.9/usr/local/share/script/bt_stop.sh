#!/bin/sh

if [ "${1}" == "fast" ]; then
	hciconfig hci0 noscan
	hciconfig hci0 noleadv
	exit 0
fi

killall bluetoothd bt-agent bt-device hciconfig hstest gatttool bt-monitor_headset 2>/dev/null
checkfuse=`cat /proc/mounts | grep /tmp/fuse_d`
if [ "${checkfuse}" == "" ]; then
	fuse_d="/tmp/SD0"
else
	fuse_d="/tmp/fuse_d"
fi

hciconfig hci0 down 2>/dev/null
killall hciattach brcm_patchram_plus bluetoothctl 2>/dev/null
BT_EN_GPIO=`cat /pref/bt.conf | grep -Ev "^#" | grep BT_EN_GPIO | cut -c 12-`
hci_on=`hciconfig`
if [ "${BT_EN_GPIO}" != "" ] && [ "${hci_on}" == "" ]; then
	/usr/local/share/script/t_gpio.sh ${BT_EN_GPIO} 0
fi

if [ "${1}" != "" ]; then
	#in case vffs hang
	rm -f `find ${fuse_d}/MISC/bluetooth/ -type f`
	rm -rf ${fuse_d}/MISC/bluetooth/*
fi
if [ -e /sys/module/rtk_btusb ]; then
	rmmod rtk_btusb
	rmmod btusb
fi
