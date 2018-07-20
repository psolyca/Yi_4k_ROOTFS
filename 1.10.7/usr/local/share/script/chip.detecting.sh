#!/bin/sh

SYSTEM_PATH=/usr/local/share/script
CONFIG_PATH="${SYSTEM_PATH}/wifi.conf"
DRIVER_NAME=bcmdhd
DRIVER_PATH="firmware_path=null"
DRIVER_CONF="nvram_path=null"
DRIVER_WLAN="iface_name=null"
DRIVER_DMSG="dhd_msg_level=0x01"

if [ ! -e /usr/local/bcmdhd/fw_apsta43455.bin ]; then
    /usr/local/share/script/chip.detected.sh
    exit 0
fi

MMC_ADD ()
{
    if [ "${WIFI_EN_STATUS}" == "" ]; then
        WIFI_EN_STATUS=1
    fi

    /usr/local/share/script/t_gpio.sh ${WIFI_EN_GPIO} $(($(($WIFI_EN_STATUS + 1)) % 2))
    /usr/local/share/script/t_gpio.sh ${WIFI_EN_GPIO} ${WIFI_EN_STATUS}

    mmci=`grep mmc /proc/ambarella/mmc_fixed_cd |awk $'{print $1}'|cut -c 4|tail -n 1`
    echo "${mmci} 1" > /proc/ambarella/mmc_fixed_cd

    n=0
    while [ -z "`ls /sys/bus/sdio/devices`" ] && [ $n -ne 30 ]; do
        n=$(($n + 1))
        sleep 0.1
    done
}

MMC_REMOVE ()
{
    if [ ! -e /sys/module/bt8xxx ]; then
        mmci=`grep mmc /proc/ambarella/mmc_fixed_cd |awk $'{print $1}'|cut -c 4|tail -n 1`
        echo "${mmci} 0" > /proc/ambarella/mmc_fixed_cd

        if [ "${WIFI_EN_STATUS}" == "" ]; then
            WIFI_EN_STATUS=1
        fi

        /usr/local/share/script/t_gpio.sh ${WIFI_EN_GPIO} $(($(($WIFI_EN_STATUS + 1)) % 2))

        n=0
        while [ "`ls /sys/bus/sdio/devices`" != "" ] && [ $n -ne 30 ]; do
            n=$(($n + 1))
            sleep 0.1
        done
    fi
}

CONFIG_DATA=`cat "${CONFIG_PATH}" | grep -Ev "^#"`
export `echo "${CONFIG_DATA}"|grep -v PASSW|grep -v SSID|grep -vI $'^\xEF\xBB\xBF'`

if [ -z "`ls /sys/bus/sdio/devices`" ]; then
    MMC_ADD
fi

# Needed for P2P.
modprobe cfg80211 ieee80211_regdom="US"

#H2: 24Mhz is more stable
if [ `grep gclk_sdio /proc/ambarella/clock|awk '{print $2}'` -gt 24000000 ] && \
    [ "`zcat /proc/config.gz | grep CONFIG_ARCH_AMBARELLA_S5=y`" != "" ]; then
        if [ -e /sys/kernel/debug/mmc1 ]; then
        echo 24000000 > /sys/kernel/debug/mmc1/clock
    else
        echo 24000000 > /sys/kernel/debug/mmc0/clock
    fi
fi

insmod /lib/modules/${DRIVER_NAME}.ko ${DRIVER_PATH} ${DRIVER_CONF} ${DRIVER_WLAN} ${DRIVER_DMSG} op_mode=2 amba_initmac=${WIFI_MAC}

# Disable WiFi CPU offloading
if [ -e /sys/module/bcmdhd/parameters/tx_coll_max_time ] && [ -e /proc/ambarella/clock ]; then
    gclk_cortex=`cat /proc/ambarella/clock | grep gclk_cortex|awk '{print $2}'`
    if [ "${gclk_cortex}" != "" ] && [ ${gclk_cortex} -gt 504000000 ]; then
        echo 0 > /sys/module/bcmdhd/parameters/tx_coll_max_time
    fi
fi

#fix A9S bcm43340 SDIO command 53 timeout issue
if [ `grep gclk_sdio /proc/ambarella/clock|awk '{print $2}'` -ge 44000000 ] && \
    [ "`zcat /proc/config.gz | grep CONFIG_PLAT_AMBARELLA_S2E=y`" != "" ] && \
    [ -e /sys/module/bcmdhd/parameters/info_string ] && \
    [ "`grep 1.88.45.11 /sys/module/bcmdhd/parameters/info_string`" != "" ] && \
    [ "`grep a94c /sys/module/bcmdhd/parameters/info_string`" != "" ]; then
        if [ -e /sys/kernel/debug/mmc1 ]; then
            echo 43636363 > /sys/kernel/debug/mmc1/clock
        else
            echo 43636363 > /sys/kernel/debug/mmc0/clock
        fi
fi

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

rmmod ${DRIVER_NAME}

MMC_REMOVE

exit 0
