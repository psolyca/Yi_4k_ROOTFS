#!/bin/sh

echo "------------------------------------"
echo "RTMP stop Wi-Fi ..."
echo "GPIO     = ${RTMP_CONFIG_GPIO}"
echo "STATUS   = ${RTMP_STATUS_FLAG}"
echo "MMC-WAIT = ${RTMP_CONFIG_WMMC}"
echo "------------------------------------"

WAIT_MMC_REMOVE ()
{
    if [ -e /proc/ambarella/mmc_fixed_cd ]; then
        mmci=`grep mmc /proc/ambarella/mmc_fixed_cd |awk $'{print $1}'|cut -c 4|tail -n 1`
        echo "${mmci} 0" > /proc/ambarella/mmc_fixed_cd
    else
        echo 0 > /sys/module/ambarella_config/parameters/sd1_slot0_fixed_cd
    fi

    /usr/local/share/script/t_gpio.sh ${RTMP_CONFIG_GPIO} $(($((${RTMP_STATUS_FLAG} + 1)) % 2))

    local fWait=0
    while [ "`ls /sys/bus/sdio/devices`" != "" ] && [ ${fWait} -lt ${RTMP_CONFIG_WMMC} ]; do
        fWait=$((${fWait} + 1))
        sleep 1
    done
}

udhcpc -i wlan0 -R &
killall youtube_live
sleep 2
killall udhcpc

#  Note: wpa_supplicant from bcmdhd does not set interface down when exit.
if [ -e /sys/module/bcmdhd ]; then
    # Note: Need wl to set interface "real down".
    wl down
    wpa_cli -i wlan0 terminate
    ifconfig wlan0 down
fi

killall hostapd dnsmasq udhcpc wpa_supplicant wpa_cli wpa_event.sh 2> /dev/null
echo "killall hostapd dnsmasq udhcpc wpa_supplicant wpa_cli wpa_event.sh"
rm -f /tmp/DIRECT.ssid /tmp/DIRECT.passphrase /tmp/wpa_p2p_done /tmp/wpa_last_event
killall hostapd dnsmasq udhcpc wpa_supplicant wpa_cli wpa_event.sh 2> /dev/null

if [ "${1}" != "nounload" ]; then
    /usr/local/share/script/unload.sh
fi

WAIT_MMC_REMOVE

#send net status update message (Network turned off)
if [ -x /usr/bin/SendToRTOS ]; then
    /usr/bin/SendToRTOS net_off
fi

# notify rtos live module
if [ "${1}" == "stop" ]; then
    /usr/bin/SendToRTOS rtmp 10
    if [ -e ${RTMP_CONFIG_FILE} ]; then
        rm -rf ${RTMP_CONFIG_FILE}
    fi
fi

exit 0
