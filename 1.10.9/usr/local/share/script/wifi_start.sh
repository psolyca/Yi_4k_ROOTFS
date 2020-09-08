#!/bin/sh

export SCRIPT_PATH=/usr/local/share/script
export WIFI_CONFIGURE_PATH="/tmp/wifi.conf"

WIFI_EN_GPIO=124

SYNC_CONFIG ()
{
    # Use the default configuration file for values which are set
    # by the menu or do not need to be changed
    # WIFI_MODE, AP_COUNTRY, AP_CHANNEL_5G and WIFI_MAC
    # If a wifi.conf exists on the SDCard, these values superseed the
    # default one.

    # system (should already exists with wifi_configure.sh)
    if [ ! -e ${WIFI_CONFIGURE_PATH} ]; then
        echo "Load wifi.conf from system ..."
        cp -rf ${SCRIPT_PATH}/wifi.conf ${WIFI_CONFIGURE_PATH}
    fi

    # FL0
    if [ -e /tmp/FL0/wifi.conf ]; then
        echo "Load wifi.conf from FL0 ..."
        conf=`cat /tmp/FL0/wifi.conf | grep -Ev "^#"`
        for i in ${conf}
            do
                if [ ${i#*=} != "" ]; then
                    sed -i 's/^'${i%=*}='.*$/'$i'/g' ${WIFI_CONFIGURE_PATH}
                fi
        done
    fi

    # SDCard
    if [ -e /tmp/fuse_d/wifi.conf ]; then
        echo "Load wifi.conf from SDCard ..."
        conf=`cat /tmp/fuse_d/wifi.conf | grep -Ev "^#"`
        # Temporary IFS change to allow SSID and Password which contains space
        tempIFS=$IFS
        IFS=$'\n'
        for i in ${conf}
            do
                if [ ${i#*=} != "" ]; then
                    sed -i 's/^'${i%=*}='.*$/'$i'/g' ${WIFI_CONFIGURE_PATH}
                fi
        done
        IFS=$tempIFS
    fi
    dos2unix -u  ${WIFI_CONFIGURE_PATH}
    conf=`cat ${WIFI_CONFIGURE_PATH} | grep -Ev "^#"`
    export `echo "${conf}"`
}

enable_wifi ()
{
    ${SCRIPT_PATH}/t_gpio.sh ${WIFI_EN_GPIO} 0
    ${SCRIPT_PATH}/t_gpio.sh ${WIFI_EN_GPIO} 1

    mmci=`grep mmc /proc/ambarella/mmc_fixed_cd |awk $'{print $1}'|cut -c 4|tail -n 1`
    echo "${mmci} 1" > /proc/ambarella/mmc_fixed_cd

    echo 24000000 > /sys/module/ambarella_sd/parameters/sdio_host_max_frequency
    echo 24000000 > /sys/kernel/debug/mmc0/clock

    local fWaiting=0
    while [ -z "`ls /sys/bus/sdio/devices`" ] && [ $fWaiting -le 30 ]; do
        fWaiting=$(($fWaiting + 1))
        sleep 0.1
    done

    if [ $fWaiting -eq 30 ]; then
        return 1
    else
        return 0
    fi
}

wait_wlan0 ()
{
    local fWaiting=0
    local fData=1
    while [ $fData -ne 0 ] && [ $fWaiting -lt 60 ]; do
        fWaiting=$(($fWaiting + 1))
        ifconfig wlan0
        fData=$?
        sleep 0.1
    done

    if [ $fWaiting -eq 60 ]; then
        return 1
    else
        return 0
    fi
}

events_manager ()
{
    if [ -e /tmp/fuse_d/events ]; then
        sleep 2
        echo "Starting events callback..."
        /sbin/start-stop-daemon -S -b -p /var/run/eventsCB.pid -m -a ${SCRIPT_PATH}/cmdyi.py
    fi
}

SYNC_CONFIG

if [ "${ETHER_MODE}" == "yes" ]; then
    /usr/local/share/script/usb_ether.sh start
    if [ "${KEEP_WIFI}" == "no" ]; then
        /usr/bin/SendToRTOS net_ready ${ETHER_IP}
        echo "Wifi will not be started"
        events_manager
        exit 0
    fi
fi

if [ -z "`ls /sys/bus/sdio/devices`" ]; then
    enable_wifi
    if [ $? -ne 0 ]; then
        echo "WiFi could not be enable"
        exit 1
    fi
fi

#check wifi mode
${SCRIPT_PATH}/load.sh "${WIFI_MODE}"

if [ -n "`ls /sys/bus/sdio/devices`" ]; then
    wait_wlan0
    if [ $? -ne 0 ]; then
        echo "There is no WIFI interface! pls check wifi driver or fw"
        exit 1
    fi
fi

echo "Found  WIFI interface!"
if [ "${WIFI_MODE}" == "sta" ]; then
    ${SCRIPT_PATH}/sta_start.sh $@
else
    ${SCRIPT_PATH}/ap_start.sh $@
fi

events_manager

