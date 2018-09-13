#!/bin/sh

if [ "${1}" == "fast" ]; then
    if [ -e /sys/module/bcmdhd ]; then
        wl up
    fi

    /tmp/wifi_start.sh && exit 0
fi

export WIFI_CONFIGURE_PATH="/tmp/wifi.conf"

SYNC_CONFIG ()
{
	# Use the default configuration file for values which are set
	# by the menu or do not need to be changed
	# WIFI_MODE, WIFI_EN_GPIO, AP_COUNTRY, AP_CHANNEL_5G and WIFI_MAC
	# If a wifi.conf exists on the SDCard, these values superseed the
	# default one.

    # system (should already exists with wifi_configure.sh
    if [ ! -e ${WIFI_CONFIGURE_PATH} ]; then
        echo "Load wifi.conf from system ..."
        cp -rf /usr/local/share/script/wifi.conf ${WIFI_CONFIGURE_PATH}
	fi

	# SDCard
    if [ -e /tmp/fuse_d/wifi.conf ]; then
        echo "Load wifi.conf from SDCard ..."
        conf=`cat /tmp/fuse_d/wifi.conf | grep -Ev "^#"`
		for i in ${conf}
			do
				sed -i 's/^'${i%=*}='.*$/'$i'/g' ${WIFI_CONFIGURE_PATH}
		done
    fi
    dos2unix -u  ${WIFI_CONFIGURE_PATH}
	conf=`cat ${WIFI_CONFIGURE_PATH} | grep -Ev "^#"`
	export `echo "${conf}"`

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

SYNC_CONFIG

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
    echo "There is no WIFI interface! pls check wifi driver or fw"
    exit 1
fi

echo "Found  WIFI interface!"
if [ "${WIFI_MODE}" == "sta" ]; then
    /usr/local/share/script/sta_xy_start.sh $@
else
    /usr/local/share/script/ap_xy_start.sh $@
fi

if [ -e /tmp/fuse_d/events ]; then
    sleep 2
    echo "Starting events callback..."
    /sbin/start-stop-daemon -S -b -p /var/run/eventsCB.pid -m -a /usr/local/share/script/cmdyi.py
fi
