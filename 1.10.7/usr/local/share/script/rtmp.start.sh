#!/bin/sh

echo "------------------------------------"
echo "RTMP start Wi-Fi ..."
echo "GPIO        = ${RTMP_CONFIG_GPIO}"
echo "STATUS      = ${RTMP_STATUS_FLAG}"
echo "IP          = ${RTMP_IPADDR_FLAG}"
echo "IP-WAIT     = ${RTMP_IPADDR_WAIT}"
echo "SYSTEM_PATH = ${RTMP_SYSTEM_PATH}"
echo "MMC-WAIT    = ${RTMP_CONFIG_WMMC}"
echo "WLAN0-WAIT  = ${RTMP_CONFIG_WLAN}"
echo "------------------------------------"

WAIT_MMC_ADD ()
{
    if [ -e /sys/module/bcmdhd/parameters/g_txglom_max_agg_num ]; then
        echo 0 >/sys/module/bcmdhd/parameters/g_txglom_max_agg_num
    fi

    /usr/local/share/script/t_gpio.sh ${RTMP_CONFIG_GPIO} $(($((${RTMP_STATUS_FLAG} + 1)) % 2))
    /usr/local/share/script/t_gpio.sh ${RTMP_CONFIG_GPIO} ${RTMP_STATUS_FLAG}

    if [ -e /proc/ambarella/mmc_fixed_cd ]; then
        mmci=`grep mmc /proc/ambarella/mmc_fixed_cd |awk $'{print $1}'|cut -c 4|tail -n 1`
        echo "${mmci} 1" > /proc/ambarella/mmc_fixed_cd
    else
        echo 1 > /sys/module/ambarella_config/parameters/sd1_slot0_fixed_cd
    fi

    echo 24000000 > /sys/module/ambarella_sd/parameters/sdio_host_max_frequency
    echo 24000000 > /sys/kernel/debug/mmc0/clock

    local fWait=0
    while [ -z "`ls /sys/bus/sdio/devices`" ] && [ ${fWait} -lt ${RTMP_CONFIG_WMMC} ]; do
        fWait=$((${fWait} + 1))
        sleep 1
    done

    if [ -z "`ls /sys/bus/sdio/devices`" ]; then
        return 1
    else
        return 0
    fi
}

WAIT_WLAN0 ()
{
    local fTimeout=0
    local fWaiting=1

    while [ ${fWaiting} -ne 0 ] && [ ${fTimeout} -lt ${RTMP_CONFIG_WLAN} ]; do
        ifconfig wlan0
        fWaiting=$?
        fTimeout=$((${fTimeout} + 1))
        sleep 1
    done

    if [ ${fWaiting} -ne 0 ]; then
        return 1
    else
        return 0
    fi
}

WAIT_MMC_ADD
if [ $? -ne 0 ]; then
    /usr/bin/SendToRTOS rtmp 4
    exit 0
fi

${WIFI_CONFIG_PATH}/load.sh sta
if [ -n "`ls /sys/bus/sdio/devices`" ] || [ -e /sys/bus/usb/devices/*/net ]; then
    echo "Driver load success ..."
else
    /usr/bin/SendToRTOS rtmp 4
    exit 0
fi

WAIT_WLAN0
if [ $? -ne 0 ]; then
    /usr/bin/SendToRTOS rtmp 4
    exit 0
fi

wl country ${AP_COUNTRY}

${WIFI_CONFIG_PATH}/rtmp.connect.sh $@

exit 0
