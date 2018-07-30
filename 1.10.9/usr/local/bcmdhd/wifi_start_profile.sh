#!/bin/sh
time insmod /lib/modules/bcmdhd.ko firmware_path=/usr/local/bcmdhd/fw_apsta.bin nvram_path=/usr/local/bcmdhd/nvram.txt iface_name=wlan dhd_msg_level=0x00 op_mode=2
time dnsmasq --nodns -5 -K -R -n --dhcp-range=192.168.42.2,192.168.42.6,infinite
time wpa_supplicant -Dnl80211 -iwlan0 -c/usr/local/bcmdhd/wpa_supplicant.ap.conf -B
time ifconfig wlan0 192.168.42.1
