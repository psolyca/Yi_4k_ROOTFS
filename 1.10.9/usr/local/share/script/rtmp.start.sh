#!/bin/sh

echo "------------------------------------"
echo "RTMP start Wi-Fi ..."
echo "------------------------------------"

${SCRIPT_PATH}/wifi_start.sh "rtmp"
sleep 0.5
/usr/bin/SendToRTOS rtmp 3
${SCRIPT_PATH}/rtmp.connect.sh $@

exit 0
