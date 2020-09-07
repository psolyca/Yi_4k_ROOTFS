#!/bin/sh

echo "------------------------------------"
echo "RTMP stop Wi-Fi ..."
echo "------------------------------------"

killall youtube_live
sleep 2
killall udhcpc

if [ ! -e /tmp/ethernet.connected ]; then
    ${SCRIPT_PATH}/wifi_stop.sh
    # notify rtos live module
    /usr/bin/SendToRTOS rtmp 10
    if [ -e ${RTMP_CONFIG_FILE} ]; then
        rm -rf ${RTMP_CONFIG_FILE}
    fi
else
    rm -f /tmp/ethernet.connected
fi



exit 0
