#!/bin/sh

echo "stop Wi-Fi ..."
/usr/local/share/script/wifi_stop.sh

if [ -e /tmp/fuse_d/AP.DEBUG/Wifi.sh ]; then
    echo "start Wi-Fi from SDCard ..."
    cp /tmp/fuse_d/AP.DEBUG/Wifi.sh /tmp/wifi.sh
    dos2unix -u /tmp/wifi.sh
    chmod +x /tmp/wifi.sh
    /tmp/wifi.sh
else
    echo "start Wi-Fi from system ..."
    /usr/local/share/script/wifi_xy_start.sh "ap"
fi

echo "restart Wi-Fi finished ..."
