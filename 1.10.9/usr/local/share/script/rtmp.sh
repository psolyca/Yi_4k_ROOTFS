#!/bin/sh

export SCRIPT_PATH=/usr/local/share/script
# Created by qr_scan
export RTMP_CONFIG_FILE=/tmp/rtmp_info.conf
export RTMP_LOG=/tmp/SD0/rtmp.log

# check live configure
if [ ! -e ${RTMP_CONFIG_FILE} ]; then
    /usr/bin/SendToRTOS rtmp 4
    exit 0
fi

export WIFI_MAC=${3}
export AP_CONFIG_COUNTRY=${4}
export RTMP_CONFIG_NAME=${5}
export RTMP_CONFIG_SSID=`cat ${RTMP_CONFIG_FILE} | grep '<ssid>' | awk -F'<ssid>' '{ print $2 }' | awk -F'</ssid>' '{ print $1 }'`
export RTMP_CONFIG_PASS=`cat ${RTMP_CONFIG_FILE} | grep '<psk>' | awk -F'<psk>' '{ print $2 }' | awk -F'</psk>' '{ print $1 }'`
export RTMP_CONFIG_SIZE=`cat ${RTMP_CONFIG_FILE} | grep '<resolution>' | awk -F'<resolution>' '{ print $2 }' | awk -F'</resolution>' '{ print $1 }'`
export RTMP_CONFIG_RATE=`cat ${RTMP_CONFIG_FILE} | grep '<rate>' | awk -F'<rate>' '{ print $2 }' | awk -F'</rate>' '{ print $1 }'`

echo -e "\n\n\n=================================================================" | tee -a $RTMP_LOG
echo Call_Time:  `date` | tee -a $RTMP_LOG
echo -e "=================================================================" | tee -a $RTMP_LOG


# stop Wi-Fi
if [ "${1}" == "stop" ]; then
    source ${SCRIPT_PATH}/rtmp.stop.sh ${1} | tee -a $RTMP_LOG
    exit 0
fi

echo `cat ${RTMP_CONFIG_FILE}` | tee -a $RTMP_LOG
# check for known connections
ifconfig | grep "Ethernet"
if [ $? -eq 0 ]; then
    echo "Either WLAN or USB connection exists" | tee -a $RTMP_LOG
    /usr/bin/SendToRTOS rtmp 3
    source ${SCRIPT_PATH}/rtmp.connect.sh | tee -a $RTMP_LOG
    touch /tmp/ethernet.connected
else
    echo "Create a connection" | tee -a $RTMP_LOG
    # start Wi-Fi
    source ${SCRIPT_PATH}/rtmp.start.sh | tee -a $RTMP_LOG

fi

exit 0
