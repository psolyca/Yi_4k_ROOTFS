#!/bin/sh

CHIP_TYPE=43340

if [ ! -e /tmp/wifi.preloaded ]; then
    /usr/local/share/script/preload.sh
fi
rm -f /tmp/wifi.preloaded

LOG_ENABLE_SCRIPT="/tmp/SD0/save_log_enable.script"
LOG_OUT_FILE="/tmp/SD0/load.log"

KO=bcmdhd.ko
# BCM will get name by configure.
BCM=bcmdhd
P_FW="firmware_path=/usr/local/${BCM}/fw"
P_FW_SD="firmware_path=/tmp/fw"
P_NVRAM="nvram_path=/usr/local/${BCM}/nv"
P_NVRAM_SD="nvram_path=/tmp/nvram.txt"
P_IF="iface_name=wlan"
P_DBG="dhd_msg_level=0x01"
conf=`cat /tmp/wifi.conf | grep -Ev "^#"`
export mac=`echo "${conf}" | grep WIFI_MAC | cut -c 10-`

if [ -e $LOG_ENABLE_SCRIPT  ]; then
    echo "$conf" >> $LOG_OUT_FILE
fi

load_mod()
{
    echo "load_mod > MAC = ${WIFI_MAC}    CHIP = ${CHIP_TYPE}"

    insmod /lib/modules/${KO} ${P_FW}_apsta43340.bin ${P_NVRAM}ram43340.txt ${P_IF} ${P_DBG} $1 amba_initmac=${WIFI_MAC}
}

if [ -e $LOG_ENABLE_SCRIPT  ]; then
    echo "enter wifi firmware loading" >> $LOG_OUT_FILE
fi

case $1 in
    sta)
        if [ -e $LOG_ENABLE_SCRIPT  ]; then
            echo "loading sta" >> $LOG_OUT_FILE
        fi
        load_mod op_mode=1
        ;;
    p2p)
        load_mod op_mode=1
        ;;
    *)
        # Set as AP
        if [ -e $LOG_ENABLE_SCRIPT  ]; then
            echo "loading ap" >> $LOG_OUT_FILE
        fi
        load_mod op_mode=2
        ;;
esac

# Needed for App.
touch /tmp/wifi.loaded

# Disable WiFi CPU offloading
if [ -e /sys/module/bcmdhd/parameters/g_txglom_max_agg_num ]; then
    echo 0 >/sys/module/bcmdhd/parameters/g_txglom_max_agg_num
fi
if [ -e /sys/module/bcmdhd/parameters/tx_coll_max_time ] && [ -e /proc/ambarella/clock ]; then
    gclk_cortex=`cat /proc/ambarella/clock | grep gclk_cortex|awk '{print $2}'`
    if [ "${gclk_cortex}" != "" ] && [ ${gclk_cortex} -gt 504000000 ]; then
        echo 0 > /sys/module/bcmdhd/parameters/tx_coll_max_time
    fi
fi
