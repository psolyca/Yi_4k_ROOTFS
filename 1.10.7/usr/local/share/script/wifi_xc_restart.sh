#!/bin/sh

echo "stop Wi-Fi ..."
/usr/local/share/script/wifi_stop.sh $@

if [ -e /tmp/fuse_d/STA.DEBUG/WiFi.sh ]; then
    echo "start Wi-Fi from SDCard ..."
    chmod +x /tmp/fuse_d/STA.DEBUG/WiFi.sh
    /tmp/fuse_d/STA.DEBUG/WiFi.sh $@
else
    echo "start Wi-Fi from system ..."
    /usr/local/share/script/wifi_xc_start.sh $@
fi

echo "restart Wi-Fi finished ..."
