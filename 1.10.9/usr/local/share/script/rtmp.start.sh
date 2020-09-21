#!/bin/sh

echo "------------------------------------"
echo "RTMP start Wi-Fi ..."
echo "------------------------------------"

if [ ${2} != "conf" ]; then
    ESSID=${RTMP_CONFIG_SSID}
    PASSWORD=${RTMP_CONFIG_PASS}
fi

${SCRIPT_PATH}/wifi_start.sh "rtmp" ${1} ${WIFI_MAC} ${AP_COUNTRY} ${ESSID} ${PASSWORD}
sleep 0.5

exit 0
