#!/bin/sh

if [ "${1}" == "fast" ]; then
    if [ -e /sys/module/bcmdhd ]; then
        wl up
    fi

    /tmp/wifi_start.sh && exit 0
fi

export WIFI_CONFIGURE_PATH="/tmp/wifi.conf"

SYNC_CONIG ()
{
    # FL0
    if [ -e /tmp/FL0/wifi.conf ]; then
        echo "Load wifi.conf from FL0 ..."
        rm -rf ${WIFI_CONFIGURE_PATH}
        cp -rf /tmp/FL0/wifi.conf ${WIFI_CONFIGURE_PATH}
    fi
    # SDCard
    if [ -e /tmp/fuse_d/wifi.conf ]; then
        echo "Load wifi.conf from SDCard ..."
        rm -rf ${WIFI_CONFIGURE_PATH}
        cp -rf /tmp/fuse_d/wifi.conf ${WIFI_CONFIGURE_PATH}
    fi
    # system
    if [ ! -e ${WIFI_CONFIGURE_PATH} ]; then
        echo "Load wifi.conf from system ..."
        cp -rf /usr/local/share/script/wifi.conf ${WIFI_CONFIGURE_PATH}
    fi
}

wait_mmc_add ()
{
    /usr/local/share/script/t_gpio.sh ${WIFI_EN_GPIO} 0
    /usr/local/share/script/t_gpio.sh ${WIFI_EN_GPIO} 1
    if [ -e /proc/ambarella/mmc_fixed_cd ]; then
        mmci=`grep mmc /proc/ambarella/mmc_fixed_cd |awk $'{print $1}'|cut -c 4|tail -n 1`
        echo "${mmci} 1" > /proc/ambarella/mmc_fixed_cd
    else
        echo 1 > /sys/module/ambarella_config/parameters/sd1_slot0_fixed_cd
    fi
    echo 24000000 > /sys/module/ambarella_sd/parameters/sdio_host_max_frequency
    echo 24000000 > /sys/kernel/debug/mmc0/clock
    n=0
    while [ -z "`ls /sys/bus/sdio/devices`" ] && [ $n -ne 30 ]; do
        n=$(($n + 1))
        sleep 0.1
    done
}

wait_wlan0 ()
{
    n=0
    ifconfig wlan0
    waitagain=$?
    while [ $waitagain -ne 0 ] && [ $n -ne 60 ]; do
        n=$(($n + 1))
        sleep 0.1
        ifconfig wlan0
        waitagain=$?
    done
}

SYNC_CONIG

conf=`cat ${WIFI_CONFIGURE_PATH} | grep -Ev "^#"`
export `echo "${conf}"|grep -v PASSW|grep -v SSID|grep -vI $'^\xEF\xBB\xBF'`
export PASSWORD=`echo "${conf}" | grep PASSWORD | cut -c 10-`
export AP_PASSWD=`echo "${conf}" | grep AP_PASSWD | cut -c 11-`
export AP_COUNTRY=`echo "${conf}" | grep AP_COUNTRY | cut -c 12-`
export ESSID=`echo "${conf}" | grep ESSID | cut -c 7-`
export AP_SSID=`echo "${conf}" | grep AP_SSID | cut -c 9-`
export AP_CHANNEL_5G=`echo "${conf}" | grep AP_CHANNEL_5G | cut -c 15-`
export STA_DEVICE_NAME=`echo "${conf}" | grep STA_DEVICE_NAME | cut -c 17-`
export WIFI_MODE="sta"

if [ "${WIFI_SWITCH_GPIO}" != "" ]; then
    WIFI_SWITCH_VALUE=`/usr/local/share/script/t_gpio.sh ${WIFI_SWITCH_GPIO}`
    echo "GPIO ${WIFI_SWITCH_GPIO} = ${WIFI_SWITCH_VALUE}"
    if [ "${WIFI_SWITCH_VALUE}" == "0" ]; then
        #send network turned off to RTOS
        if [ -x /usr/bin/SendToRTOS ]; then
            /usr/bin/SendToRTOS net_off
        elif [ -x /usr/bin/boot_done ]; then
            boot_done 1 2 1
        fi
        exit 0
    fi
fi

if [ "${1}" == "ssid" ]; then
    export    AP_SSID="${2}"
    export    AP_XY_SSID="${1}"
    echo "AP_SSID=${AP_SSID}"
    echo "AP_XY_SSID=${AP_XY_SSID}"
fi
if [ "${3}" == "5G" ]; then
    export    AP_CHANNEL_5G=1
    echo "AP_CHANNEL_5G=${AP_CHANNEL_5G}"
elif [ "${3}" == "2.4G" ]; then
    export    AP_CHANNEL_5G=0
fi
if [ -e /sys/module/bcmdhd/parameters/g_txglom_max_agg_num ]; then
    echo 0 >/sys/module/bcmdhd/parameters/g_txglom_max_agg_num
fi
if [ "${WIFI_EN_GPIO}" != "" ] && [ -z "`ls /sys/bus/sdio/devices`" ]; then
    wait_mmc_add
fi

#check wifi mode
/usr/local/share/script/load.sh "${WIFI_MODE}"

waitagain=1
if [ -n "`ls /sys/bus/sdio/devices`" ] || [ -e /sys/bus/usb/devices/*/net ]; then
    wait_wlan0
fi
if [ $waitagain -ne 0 ]; then
    echo "There is no WIFI interface!pls check wifi dirver or fw"
    exit 1
fi

echo "Found  WIFI interface!"
if [ "${WIFI_MODE}" == "sta" ] ; then
    /usr/local/share/script/sta_xc_start.sh $@
else
    /usr/local/share/script/ap_xy_start.sh $@
fi
