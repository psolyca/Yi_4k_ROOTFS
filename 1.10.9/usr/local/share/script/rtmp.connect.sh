#!/bin/sh

echo "------------------------------------"
echo "RTMP Wi-Fi connect ..."
echo "------------------------------------"


RTSP_CONF()
{
    if [ "${RTMP_CONFIG_SIZE}" == "720p" ]; then
        /usr/bin/SendToRTOS rtmp 80
    elif [ "${RTMP_CONFIG_SIZE}" == "1080p" ]; then
        /usr/bin/SendToRTOS rtmp 81
    elif [ "${RTMP_CONFIG_SIZE}" == "360p" ]; then
        /usr/bin/SendToRTOS rtmp 83
    else
        /usr/bin/SendToRTOS rtmp 82
    fi

    if [ "${RTMP_CONFIG_RATE}" -eq 3 ]; then
        /usr/bin/SendToRTOS rtmp 96
    elif [ "${RTMP_CONFIG_RATE}" -eq 2 ]; then
        /usr/bin/SendToRTOS rtmp 97
    elif [ "${RTMP_CONFIG_RATE}" -eq 1 ]; then
        /usr/bin/SendToRTOS rtmp 98
    else
        /usr/bin/SendToRTOS rtmp 99
    fi
}

RTSP_CONF

exit 0
