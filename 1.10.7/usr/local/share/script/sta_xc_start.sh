#!/bin/sh

if [ -e /sys/module/ar6000 ]; then
    driver=wext
elif [ -e /sys/module/dhd ]; then
    driver=wext
    wl ap 0
    wl mpc 0
    wl frameburst 1
    wl up
else
    driver=nl80211
fi

wl country CN

wait_ip_done ()
{
    local n=0
    local code=0
    local data=0;
    wlan0_ready=`ifconfig wlan0|grep "inet addr"`
    while [ "${wlan0_ready}" == "" ] && [ $n -lt 10 ]; do
        wlan0_ready=`ifconfig wlan0|grep "inet addr"`
        n=$(($n + 1))
        data=$((${n} + 1100))
        sleep 1
        /usr/bin/SendToRTOS sta_step ${data}
    done

    data=$((${code} + 1200))
    /usr/bin/SendToRTOS sta_step ${data}

    if [ "${wlan0_ready}" != "" ]; then
        if [ "${CTYPE_VAL}" != "" ]; then
            /usr/bin/SendToRTOS sta_connected ${CTYPE_VAL} $((${DTIME_VAL} + 1000))
            code=1
        else
            /usr/bin/SendToRTOS sta_connected $REMASK 1000
            code=2
        fi
    else
        echo "Cannot get IP within 10 sec, skip boot_done"
        if [ "${CTYPE_VAL}" != "" ]; then
            /usr/bin/SendToRTOS sta_connected ${CTYPE_VAL} $((${DTIME_VAL} + 4000))
            code=3
        else
            /usr/bin/SendToRTOS sta_connected $REMASK 4000
            code=4
        fi
    fi
}

checkfuse=`cat /proc/mounts | grep /tmp/fuse_d`
if [ "${checkfuse}" == "" ]; then
    fuse_d="/tmp/SD0"
else
    fuse_d="/tmp/fuse_d"
fi

REMASK=0
scan_entry=""
CTYPE_KEY="${1:0:5}"
CTYPE_VAL="${1:6}"
DSCAN_KEY="${2:0:9}"
DSCAN_VAL=${2:10}
DTIME_KEY="${3:0:8}"
DTIME_VAL=${3:9}
DSSID_KEY="${4:0:5}"
DSSID_VAL="${4:6}"
DPASWD_KEY="${5:0:9}"
DPASWD_VAL="${5:10}"
BSSID_VAL=""
Freq_MIN=2400
Freq_MAX=6000
Freq_CUR=0
SAME_SSID_COUNT=1
FIND_AP_FLAG=0

#if [ ${AP_CHANNEL_5G} -gt 0 ]; then
#    Freq_MIN=5000
#    Freq_MAX=6000
#fi

if [ ${DSCAN_VAL} -le 0 ]; then
    DSCAN_VAL=14
    DTIME_VAL=0
fi

echo "arg[1] = ${1} <${CTYPE_KEY},  ${CTYPE_VAL}>"
echo "arg[2] = ${2} <${DSCAN_KEY},  ${DSCAN_VAL}>"
echo "arg[3] = ${3} <${DTIME_KEY},  ${DTIME_VAL}>"
echo "arg[4] = ${4} <${DSSID_KEY},  ${DSSID_VAL}>"
echo "arg[5] = ${5} <${DPASWD_KEY}, ${DPASWD_VAL}>"
echo "frequency: min<${Freq_MIN}>  max<${Freq_MAX}> "

wpa_auto_scan()
{
    echo "p2p_disabled=1" > /tmp/wpa_scan.conf
    wpa_supplicant -D${driver} -iwlan0 -C /var/run/wpa_supplicant -B -c /tmp/wpa_scan.conf
    sleep 1
    scan_ok=" "
    while [ "$scan_ok" != "OK" ]; do
        wpa_cli scan | awk '{print $1}' >> /tmp/tmp.conf
        scan_ok=`sed -n '2p' /tmp/tmp.conf`
        sleep 2
        echo "Get scan $scan_ok"
    done
    rm -rf /tmp/tmp.conf
    rm /tmp/wpa_scan.conf
    rm -rf /tmp/tmp.scan

    cn=0
    while [ $cn -lt ${DSCAN_VAL} ]; do
        /usr/bin/SendToRTOS sta_step $(($cn + 1400))
        if [ $cn -eq 5 ]; then
            scan_ok=" "
            while [ "$scan_ok" != "OK" ]; do
                wpa_cli scan | awk '{print $1}' >> /tmp/tmp.conf
                scan_ok=`sed -n '2p' /tmp/tmp.conf`
                sleep 2
                echo "Get scan $scan_ok"
            done
            rm -rf /tmp/tmp.conf
        fi
        sleep 4
        wpa_cli scan_r > /tmp/tmp.scan

        n=`cat /pref/wifi_sta_list.conf | wc -l`
        name=`sed -n '1p' /pref/wifi_sta_list.conf`
        scan_retry=1
        scan_result=`cat /tmp/tmp.scan | grep -Ev "^#"`

        if [ -e /tmp/fuse_d/STA.DEBUG/debug.scan ]; then
            echo ">> Scan result ..."
            echo "${scan_result}"
        fi

        j=1
        rssitmp=-90
        scan_entry=""
        while [ "$scan_retry" -le "$n" ]; do
            ESSIDTMP=`echo "${name}" | cut -f 1`
            PASSWORDTMP=`echo "${name}" | cut -f 2`
            REMASKTMP=`echo "${name}" | cut -f 3`
            scan_entry_tmp=`echo "${scan_result}" | tr '\t' ' ' | grep -w " ${ESSIDTMP}$" | tail -n 1`

            #echo "${scan_result}"
            if [ $# -ge 1 ] && [ "${CTYPE_KEY}" == "stype" ]; then
                if [ "${CTYPE_VAL}" != "${REMASKTMP}" ]; then
                    scan_entry_tmp=""
                fi
            fi

            if [ "${scan_entry_tmp}" != "" ]; then
                rssi=-90
                SAME_SSID_COUNT=1
                FIND_AP_FLAG=0
                rssi=`echo "${scan_result}"  | grep -w "${ESSIDTMP}" | cut -f 3`
                # rssi=`echo "${rssi}" | head -${SAME_SSID_COUNT}`
                rssi=`echo "${rssi}" | sed -n ${SAME_SSID_COUNT}p`
                Freq_CUR=`echo "${scan_result}"  | grep -w "${ESSIDTMP}" | cut -f 2`
                # Freq_CUR=`echo "${Freq_CUR}" | head -${SAME_SSID_COUNT}`
                Freq_CUR=`echo "${Freq_CUR}" | sed -n ${SAME_SSID_COUNT}p`
                while [ "${rssi}" != "" ] && [ "${Freq_CUR}" != "" ] && [ ${FIND_AP_FLAG} -le 0 ]; do
                    echo "rssi > ${rssi}        freq > ${Freq_CUR}"
                    if [ ${Freq_CUR} -gt ${Freq_MIN} ] && [ ${Freq_CUR} -lt ${Freq_MAX} ]; then
                        BSSID_VAL=`echo "${scan_result}" | grep -w "${Freq_CUR}" | grep -w "${ESSIDTMP}" | cut -f 1`
                        BSSID_VAL=`echo "${BSSID_VAL}" | head -1`
                        echo "bssid = ${BSSID_VAL}   scan = ${scan_entry_tmp}"
                        /usr/bin/SendToRTOS sta_step 1600
                        if [ "$rssi" -ge "$rssitmp" ]; then
                            ESSID=$ESSIDTMP
                            PASSWORD=$PASSWORDTMP
                            REMASK=$REMASKTMP
                            rssitmp=$rssi
                            scan_entry=$scan_entry_tmp
                            /usr/bin/SendToRTOS sta_step 1700
                            FIND_AP_FLAG=1
                            cn=13
                        fi
                    fi
                    SAME_SSID_COUNT=$((${SAME_SSID_COUNT} + 1))
                    rssi=`echo "${scan_result}"  | grep -w "${ESSIDTMP}" | cut -f 3`
                    # rssi=`echo "${rssi}" | head -${SAME_SSID_COUNT}`
                    rssi=`echo "${rssi}" | sed -n ${SAME_SSID_COUNT}p`
                    Freq_CUR=`echo "${scan_result}"  | grep -w "${ESSIDTMP}" | cut -f 2`
                    # Freq_CUR=`echo "${Freq_CUR}" | head -${SAME_SSID_COUNT}`
                    Freq_CUR=`echo "${Freq_CUR}" | sed -n ${SAME_SSID_COUNT}p`
                done
            fi
            j=$(($j + 1))
            p="p"
            scan_retry=$(($scan_retry + 1))
            name=`sed -n "$j$p" /pref/wifi_sta_list.conf`
        done
        cn=$(($cn + 1))
    done
    /usr/bin/SendToRTOS sta_step 1500
    rm /tmp/tmp.scan
    killall wpa_supplicant
    echo "AUTO SCAN >> ESSID = ${ESSID}   PASSWORD = ${PASSWORD}   REMASK = ${REMASK}   rssitmp = ${rssitmp}   BSSID = ${BSSID_VAL}"
}

WPA_SCAN ()
{
    local code=0
    local data=0;
    if [ -e /pref/wifi_sta_list.conf ]; then
        wpa_auto_scan
    else
        if [ "${CTYPE_VAL}" != "" ]; then
            /usr/bin/SendToRTOS sta_connected ${CTYPE_VAL} $((${DTIME_VAL} + 2000))
            code=1
        else
            /usr/bin/SendToRTOS sta_connected $REMASK $((${DTIME_VAL} + 2000))
            code=2
        fi
        data=$((${code} + 1300))
        /usr/bin/SendToRTOS sta_step ${data}
        exit 0
    fi
}

WPA_GO ()
{
    killall -9 wpa_supplicant 2>/dev/null
    wpa_supplicant -D${driver} -iwlan0 -c/tmp/wpa_supplicant.conf -B
    udhcpc -i wlan0 -A 1 -b
    wait_ip_done
}

if [ "${DSSID_KEY}" != "dssid" ] || [ "${DSSID_VAL}" == "" ] || [ "${DPASWD_KEY}" != "dpassword" ] || [ "${DPASWD_VAL}" == "" ]; then
    WPA_SCAN
    if [ "${scan_entry}" == "" ]; then
        if [ "${CTYPE_VAL}" != "" ]; then
            /usr/bin/SendToRTOS sta_connected ${CTYPE_VAL} $((${DTIME_VAL} + 3000))
            /usr/bin/SendToRTOS sta_step 1800
        else
            /usr/bin/SendToRTOS sta_connected $REMASK $((${DTIME_VAL} + 3000))
            /usr/bin/SendToRTOS sta_step 1900
        fi
        exit 0
    fi

    echo -e "\033[031m ${scan_entry} \033[0m"
    echo "ctrl_interface=/var/run/wpa_supplicant" > /tmp/wpa_supplicant.conf
    echo "network={" >> /tmp/wpa_supplicant.conf
    echo "ssid=\"${ESSID}\"" >> /tmp/wpa_supplicant.conf
    if [ "${BSSID_VAL}" != "" ]; then
        echo "bssid=${BSSID_VAL}" >> /tmp/wpa_supplicant.conf
    fi
    echo "scan_ssid=1" >> /tmp/wpa_supplicant.conf
    WEP=`echo "${scan_entry}" | grep WEP`
    WPA=`echo "${scan_entry}" | grep WPA`
    WPA2=`echo "${scan_entry}" | grep WPA2`
    CCMP=`echo "${scan_entry}" | grep CCMP`
    TKIP=`echo "${scan_entry}" | grep TKIP`
    /usr/bin/SendToRTOS sta_step 2000
else
    echo "ctrl_interface=/var/run/wpa_supplicant" > /tmp/wpa_supplicant.conf
    echo "network={" >> /tmp/wpa_supplicant.conf
    echo "ssid=\"${DSSID_VAL}\"" >> /tmp/wpa_supplicant.conf
    if [ "${BSSID_VAL}" != "" ]; then
        echo "bssid=${BSSID_VAL}" >> /tmp/wpa_supplicant.conf
    fi
    echo "scan_ssid=0" >> /tmp/wpa_supplicant.conf
    WEP=""
    WPA="WPA"
    WPA2="WPA2"
    CCMP="CCMP"
    TKIP=""
    PASSWORD=${DPASWD_VAL}
    /usr/bin/SendToRTOS sta_step 1000
fi

if [ "${WPA}" != "" ]; then
    #WPA2-PSK-CCMP    (11n requirement)
    #WPA-PSK-CCMP
    #WPA2-PSK-TKIP
    #WPA-PSK-TKIP
    echo "key_mgmt=WPA-PSK" >> /tmp/wpa_supplicant.conf

    if [ "${WPA2}" != "" ]; then
        echo "proto=WPA2" >> /tmp/wpa_supplicant.conf
    else
        echo "proto=WPA" >> /tmp/wpa_supplicant.conf
    fi

    if [ "${CCMP}" != "" ]; then
        echo "pairwise=CCMP" >> /tmp/wpa_supplicant.conf
    else
        echo "pairwise=TKIP" >> /tmp/wpa_supplicant.conf
    fi

    echo "psk=\"${PASSWORD}\"" >> /tmp/wpa_supplicant.conf
fi

if [ "${WEP}" != "" ] && [ "${WPA}" == "" ]; then
    echo "key_mgmt=NONE" >> /tmp/wpa_supplicant.conf
        echo "wep_key0=${PASSWORD}" >> /tmp/wpa_supplicant.conf
        echo "wep_tx_keyidx=0" >> /tmp/wpa_supplicant.conf
fi

if [ "${WEP}" == "" ] && [ "${WPA}" == "" ]; then
    echo "key_mgmt=NONE" >> /tmp/wpa_supplicant.conf
fi

echo "}" >> /tmp/wpa_supplicant.conf

if [ -e /sys/module/bcmdhd ]; then
    rm -f /tmp/wpa_scan.conf
    echo "p2p_disabled=1" >> /tmp/wpa_supplicant.conf
    if [ "`uname -r`" != "2.6.38.8" ]; then
        echo "wowlan_triggers=any" >> /tmp/wpa_supplicant.conf
    fi
fi
if [ -e /sys/module/8189es ] || [ -e /sys/module/8723bs ]; then
    if [ "`uname -r`" != "2.6.38.8" ]; then
        echo "wowlan_triggers=any" >> /tmp/wpa_supplicant.conf
    fi
fi

WPA_GO

