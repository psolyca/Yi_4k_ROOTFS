#!/bin/sh

echo "stop Wi-Fi ..."
/usr/local/share/script/wifi_stop.sh

if [ -e /tmp/fuse_d/AP.DEBUG/Wifi.sh ]; then
    echo "start Wi-Fi from SDCard ..."
    chmod +x /tmp/fuse_d/AP.DEBUG/Wifi.sh
    /tmp/fuse_d/AP.DEBUG/Wifi.sh
else
    echo "start Wi-Fi from system ..."
    /usr/local/share/script/wifi_xy_start.sh "ap"
fi

echo "restart Wi-Fi finished ..."
