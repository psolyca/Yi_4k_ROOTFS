#!/bin/sh

if [ "${WIFI_TEST_STATION_PATH_SYSTEM}" == "" ]; then
    export WIFI_TEST_STATION_PATH_SYSTEM=/usr/local/share/script
fi

DEFAULT_WIFI_CONF="${WIFI_TEST_STATION_PATH_SYSTEM}/wifi_test_station.conf"
TARGET_WIFI_CONF="/tmp/wifi_test_station.conf"

wait_mmc_add ()
{
    if [ "${WIFI_EN_STATUS}" == "" ]; then
        WIFI_EN_STATUS=1
    fi

    ${WIFI_TEST_STATION_PATH_SYSTEM}/t_gpio.sh ${WIFI_EN_GPIO} $(($(($WIFI_EN_STATUS + 1)) % 2))
    ${WIFI_TEST_STATION_PATH_SYSTEM}/t_gpio.sh ${WIFI_EN_GPIO} ${WIFI_EN_STATUS}

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
    while [ $waitagain -ne 0 ] && [ $n -ne 30 ]; do
        n=$(($n + 1))
        sleep 0.1
        ifconfig wlan0
        waitagain=$?
    done
}

KILL_STATION ()
{
    local fPS=`ps -ef | grep -r "${WIFI_TEST_STATION_PATH_SYSTEM}/wifi_test_station_station.sh" | grep -v grep`
    local fID=0

    if [ "${fPS}" != "" ]; then
        fID=`echo "${fPS}" | awk '{print $1}'`
        if [ "${fID}" != "" ]; then
            kill -9 ${fID}
            /usr/bin/SendToRTOS test_station "Kill test station done"
        fi
    fi
}

${WIFI_TEST_STATION_PATH_SYSTEM}/wifi_test_station_configure.sh $@

conf=`cat "${TARGET_WIFI_CONF}" | grep -Ev "^#"`
export `echo "${conf}"|grep -v PASSW|grep -v SSID|grep -vI $'^\xEF\xBB\xBF'`
export AP_PASSWD=`echo "${conf}" | grep AP_PASSWD | cut -c 11-`
export AP_SSID=`echo "${conf}" | grep AP_SSID | cut -c 9-`
export AP_COUNTRY=`echo "${conf}" | grep AP_COUNTRY | cut -c 12-`
export AP_CHANNEL_5G=`echo "${conf}" | grep AP_CHANNEL_5G | cut -c 15-`
export STA_SSID=`echo "${conf}" | grep STA_SSID | cut -c 10-`
export STA_PASSWD=`echo "${conf}" | grep STA_PASSWD | cut -c 12-`
export STA_FREQ=`echo "${conf}" | grep STA_FREQ | cut -c 10-`
export STA_NAME=`echo "${conf}" | grep STA_NAME | cut -c 10-`
export STA_SCAN=`echo "${conf}" | grep STA_SCAN | cut -c 10-`
export STA_IP=`echo "${conf}" | grep STA_IP | cut -c 8-`
export STA_COUNTRY=`echo "${conf}" | grep AP_COUNTRY | cut -c 12-`

echo "START > WIFI_EN_GPIO = ${WIFI_EN_GPIO}   WIFI_EN_STATUS = ${WIFI_EN_STATUS}"
if [ "${WIFI_EN_GPIO}" != "" ] && [ -z "`ls /sys/bus/sdio/devices`" ]; then
    wait_mmc_add
fi

#check wifi mode
${WIFI_TEST_STATION_PATH_SYSTEM}/load.sh "${WIFI_MODE}"

waitagain=1
if [ "`ls /sys/bus/sdio/devices`" != "" ] || [ "`ls /sys/bus/usb/devices 2>/dev/null`" != "" ]; then
    wait_wlan0
fi
if [ $waitagain -ne 0 ]; then
    echo "There is no WIFI interface!"
    exit 1
fi

echo "found WIFI interface!"

if [ "${WIFI_MODE}" == "sta" ] ; then
    KILL_STATION
    ${WIFI_TEST_STATION_PATH_SYSTEM}/wifi_test_station_station.sh $@
fi
