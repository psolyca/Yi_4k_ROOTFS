#!/bin/sh

export WIFI_CONFIG_PATH=/usr/local/share/script
export RTMP_CONFIG_FILE=/tmp/rtmp_info.conf
export WIFI_CONFIG_FILE=/usr/local/share/script/wifi.conf
export RTMP_CONFIG_GPIO=`cat "${WIFI_CONFIG_FILE}" | grep -Ev "^#" | grep WIFI_EN_GPIO | cut -c 14-`
export RTMP_STATUS_FLAG=1
export RTMP_IPADDR_FLAG=
export RTMP_DOSCAN_FLAG=yes
export RTMP_DOSCAN_WAIT=60
export RTMP_IPADDR_WAIT=30
export RTMP_CONFIG_WMMC=3
export RTMP_CONFIG_WLAN=6
export RTMP_CHNNEL_5000=none
export RTMP_CONFIG_CMAC=

# stop Wi-Fi
${WIFI_CONFIG_PATH}/rtmp.stop.sh ${1}
if [ "${1}" == "stop" ]; then
    exit 0
fi

# check live configure
if [ ! -e ${RTMP_CONFIG_FILE} ]; then
    /usr/bin/SendToRTOS rtmp 4
    exit 0
fi

export CHIP_TYPE=${2}
export WIFI_MAC=${3}
export AP_COUNTRY=${4}
export RTMP_CONFIG_NAME=${5}
export RTMP_CONFIG_SSID=`cat ${RTMP_CONFIG_FILE} | grep '<ssid>' | awk -F'<ssid>' '{ print $2 }' | awk -F'</ssid>' '{ print $1 }'`
export RTMP_CONFIG_PASS=`cat ${RTMP_CONFIG_FILE} | grep '<psk>' | awk -F'<psk>' '{ print $2 }' | awk -F'</psk>' '{ print $1 }'`
export RTMP_CONFIG_SIZE=`cat ${RTMP_CONFIG_FILE} | grep '<resolution>' | awk -F'<resolution>' '{ print $2 }' | awk -F'</resolution>' '{ print $1 }'`
export RTMP_CONFIG_RATE=`cat ${RTMP_CONFIG_FILE} | grep '<rate>' | awk -F'<rate>' '{ print $2 }' | awk -F'</rate>' '{ print $1 }'`

# start Wi-Fi
${WIFI_CONFIG_PATH}/rtmp.start.sh

exit 0
