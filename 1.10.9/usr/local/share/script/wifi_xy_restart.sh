#!/bin/sh

echo "stop Wi-Fi ..."
/usr/local/share/script/wifi_stop.sh

if [ -e /tmp/SD0/AP.DEBUG/Wifi.sh ]; then
    echo "start Wi-Fi from SDCard ..."
    cp /tmp/SD0/AP.DEBUG/Wifi.sh /tmp/wifi.sh
    dos2unix -u /tmp/wifi.sh
    chmod +x /tmp/wifi.sh
    /tmp/wifi.sh
else
    echo "start Wi-Fi from system ..."
    /usr/local/share/script/wifi_start.sh "ap"
fi

echo "restart Wi-Fi finished ..."
