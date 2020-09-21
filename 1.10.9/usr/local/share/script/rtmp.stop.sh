#!/bin/sh
RTMP_NETWORK_ACTIVE=/tmp/network.active

echo "------------------------------------"
echo "RTMP stop Wi-Fi ..."
echo "------------------------------------"

killall youtube_live
sleep 2


if [ ! -e ${RTMP_NETWORK_ACTIVE} ]; then
    killall udhcpc
    echo "Stopping wifi"
    ${SCRIPT_PATH}/wifi_stop.sh
    if [ ${1} == "stop" ]; then
        echo "Notify RTOS that wifi is stopped."
        /usr/bin/SendToRTOS rtmp 10
        if [ -e ${RTMP_CONFIG_FILE} ]; then
            rm -rf ${RTMP_CONFIG_FILE}
        fi
    fi
else
    echo "Not stopping wifi"
    rm -f ${RTMP_NETWORK_ACTIVE}
fi


exit 0
