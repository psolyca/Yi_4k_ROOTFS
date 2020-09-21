#!/bin/sh

export SCRIPT_PATH=/usr/local/share/script
# Created by qr_scan
export RTMP_CONFIG_FILE=/tmp/rtmp_info.conf
export RTMP_LOG=/tmp/SD0/rtmp.log
# Network active before RTMP (keep it active after RTMP stop)
export RTMP_NETWORK_ACTIVE=/tmp/network.active

# check live configure
if [ ! -e ${RTMP_CONFIG_FILE} ]; then
    /usr/bin/SendToRTOS rtmp 4
    exit 0
fi

export WIFI_MAC=${3}
export AP_COUNTRY=${4}
export RTMP_CONFIG_SSID=`cat ${RTMP_CONFIG_FILE} | grep '<ssid>' | awk -F'<ssid>' '{ print $2 }' | awk -F'</ssid>' '{ print $1 }'`
export RTMP_CONFIG_PASS=`cat ${RTMP_CONFIG_FILE} | grep '<psk>' | awk -F'<psk>' '{ print $2 }' | awk -F'</psk>' '{ print $1 }'`
export RTMP_CONFIG_SIZE=`cat ${RTMP_CONFIG_FILE} | grep '<resolution>' | awk -F'<resolution>' '{ print $2 }' | awk -F'</resolution>' '{ print $1 }'`
export RTMP_CONFIG_RATE=`cat ${RTMP_CONFIG_FILE} | grep '<rate>' | awk -F'<rate>' '{ print $2 }' | awk -F'</rate>' '{ print $1 }'`

check_network()
{
    # check for known connections
    local wlan=0
    local usb=0
    ifconfig | grep "wlan0"
    if [ $? -eq 0 ]; then
        echo "WLAN connection exists" | tee -a $RTMP_LOG
        wlan=1
    fi
    ifconfig | grep "usb0"
    if [ $? -eq 0 ]; then
        echo "USB connection exists" | tee -a $RTMP_LOG
        usb=2
    fi
    return $(( wlan + usb ))
}

echo -e "\n\n\n=================================================================" | tee -a $RTMP_LOG
echo Call_Time:  `date` | tee -a $RTMP_LOG
echo -e "=================================================================" | tee -a $RTMP_LOG

# stop Wi-Fi
if [ ${1} == "stop" ]; then
    source ${SCRIPT_PATH}/rtmp.stop.sh ${1} | tee -a $RTMP_LOG
    exit 0
fi

check_network
network=$?

# With official smartphone Yi action app :
#       RTMP_CONFIG_SSID = "myESSID"; force reconnection
# With custom QR generator value are integrated in RTMP_CONFIG_SSID = [myESSID][+sta/ap][+/-usb][-rtmp]:
#       "default" : RTMP_CONFIG_SSID = ""; use existing connection or connect to default sta in wifi.conf
#       "sta" or "ap" : RTMP_CONFIG_SSID = "myESSID"; force reconnection
#       "usb" : usb [dis]connection
#       "rtmp" : [rtmp]
rtmp=1
etherOusb=0
wifiMode="-"
while true; do
    case ${RTMP_CONFIG_SSID} in
        *-rtmp)
            export RTMP_CONFIG_SSID=`echo ${RTMP_CONFIG_SSID} | rev | cut -c 6- | rev`
            rtmp=0
            echo "rtmp: ${rtmp} and RTMP_CONFIG_SSID: ${RTMP_CONFIG_SSID}" | tee -a $RTMP_LOG
            ;;
        *+usb)
            export RTMP_CONFIG_SSID=`echo ${RTMP_CONFIG_SSID} | rev | cut -c 5- | rev`
            etherOusb=1
            echo "etherOusb(1): ${etherOusb} and RTMP_CONFIG_SSID: ${RTMP_CONFIG_SSID}" | tee -a $RTMP_LOG
            ;;
        *-usb)
            export RTMP_CONFIG_SSID=`echo ${RTMP_CONFIG_SSID} | rev | cut -c 5- | rev`
            etherOusb=-1
            echo "etherOusb(-1): ${etherOusb} and RTMP_CONFIG_SSID: ${RTMP_CONFIG_SSID}" | tee -a $RTMP_LOG
            ;;
        *+ap)
            export RTMP_CONFIG_SSID=`echo ${RTMP_CONFIG_SSID} | rev | cut -c 4- | rev`
            wifiMode="ap"
            echo "wifiMode(ap): ${wifiMode} and RTMP_CONFIG_SSID: ${RTMP_CONFIG_SSID}" | tee -a $RTMP_LOG
            ;;
        *+sta)
            export RTMP_CONFIG_SSID=`echo ${RTMP_CONFIG_SSID} | rev | cut -c 5- | rev`
            wifiMode="sta"
            echo "wifiMode (sta): ${wifiMode} and RTMP_CONFIG_SSID: ${RTMP_CONFIG_SSID}" | tee -a $RTMP_LOG
            ;;
        *)
            break
            ;;
    esac
done

echo `cat ${RTMP_CONFIG_FILE} | tr " " "\n"` | tee -a $RTMP_LOG
if [ ${RTMP_CONFIG_SSID} == "None" ]; then
    echo "No ESSID." | tee -a $RTMP_LOG
    if [ $(( network % 2 )) -eq 0 ]; then
        if [ $wifiMode == "-" ]; then
            echo "Set wifi default mode" | tee -a $RTMP_LOG
            wifiMode="sta"
        fi
        echo "Start wifi in $wifiMode mode" | tee -a $RTMP_LOG
        ${SCRIPT_PATH}/rtmp.start.sh "${wifiMode}" "conf" | tee -a $RTMP_LOG
    else
        if [ $wifiMode != "-" ]; then
            rm -f ${RTMP_NETWORK_ACTIVE}
            echo "Wifi already active, restart it" | tee -a $RTMP_LOG
            ${SCRIPT_PATH}/rtmp.stop.sh | tee -a $RTMP_LOG
            ${SCRIPT_PATH}/rtmp.start.sh "${wifiMode}" "conf" | tee -a $RTMP_LOG
        fi
        echo "Wifi active, use it" | tee -a $RTMP_LOG
    fi
else
    echo "Wifi (re)connection" | tee -a $RTMP_LOG
    rm -f ${RTMP_NETWORK_ACTIVE}
    if [ $(( network % 2 )) -eq 1 ]; then
        echo "Wifi already active, stop it" | tee -a $RTMP_LOG
        ${SCRIPT_PATH}/rtmp.stop.sh | tee -a $RTMP_LOG
    fi
    echo "Start wifi." | tee -a $RTMP_LOG
    ${SCRIPT_PATH}/rtmp.start.sh "${wifiMode}" "-" | tee -a $RTMP_LOG
fi

if [ $network -lt 2 ] && [ $etherOusb -gt 0 ]; then
    echo "USB connection" | tee -a $RTMP_LOG
    ${SCRIPT_PATH}/usb_ether.sh start | tee -a $RTMP_LOG
fi
if [ $network -ge 2 ] && [ $etherOusb -lt 0 ]; then
    echo "USB disconnection" | tee -a $RTMP_LOG
    ${SCRIPT_PATH}/usb_ether.sh stop | tee -a $RTMP_LOG
fi

/usr/bin/SendToRTOS rtmp 3
if [ $rtmp -eq 1 ]; then
    echo "Finalize RTMP" | tee -a $RTMP_LOG
    ${SCRIPT_PATH}/rtmp.connect.sh | tee -a $RTMP_LOG
    if [ $network -ne 0 ]; then
        touch ${RTMP_NETWORK_ACTIVE}
    fi
else
    echo "Do not start RTMP" | tee -a $RTMP_LOG
    touch ${RTMP_NETWORK_ACTIVE}
    sleep 5
    /usr/bin/SendToRTOS rtmp 7
fi

exit 0
