#!/bin/sh

echo "------------------------------------"
echo "RTMP Wi-Fi connect ..."
echo "HOST-MAC   = ${RTMP_CONFIG_CMAC}"
echo "SSID       = ${RTMP_CONFIG_SSID}"
echo "PASSWORD   = ${RTMP_CONFIG_PASS}"
echo "CHANNEL-5G = ${RTMP_CHNNEL_5000}"
echo "NAME       = ${RTMP_CONFIG_NAME}"
echo "IP         = ${RTMP_IPADDR_FLAG}"
echo "IP-WAIT    = ${RTMP_IPADDR_WAIT}"
echo "SCAN       = ${RTMP_DOSCAN_FLAG}"
echo "SCAN-WAIT  = ${RTMP_DOSCAN_WAIT}"
echo "------------------------------------"

STATION_CONFIG_CMAC=${RTMP_CONFIG_CMAC}
STATION_CONFIG_SSID=${RTMP_CONFIG_SSID}
STATION_CONFIG_PASS=${RTMP_CONFIG_PASS}
STATION_CONFIG_FREQ=${RTMP_CHNNEL_5000}
STATION_CONFIG_NAME=${RTMP_CONFIG_NAME}
STATION_CONFIG_ADDR=${RTMP_IPADDR_FLAG}
STATION_CONFIG_SCAN=${RTMP_DOSCAN_FLAG}
STATION_DOSCAN_WAIT=${RTMP_DOSCAN_WAIT}
STATION_IPADDR_WAIT=${RTMP_IPADDR_WAIT}
STATION_CONFIG_CDEV=nl80211
STATION_CONFIG_AUTO=/tmp/rtmp.station.auto.scan.conf
STATION_CONFIG_CRUN=/var/run/wpa_supplicant
STATION_CONFIG_CWPA=/tmp/rtmp.wpa_supplicant.conf
STATION_CONFIG_DATA=/tmp/rtmp.station.scan
STATION_CONFIG_FIND=/tmp/rtmp.station.find

RTSP_CONF()
{
    if [ "${RTMP_CONFIG_SIZE}" == "720p" ]; then
        /usr/bin/SendToRTOS rtmp 80
    elif [ "${RTMP_CONFIG_SIZE}" == "1080p" ]; then
        /usr/bin/SendToRTOS rtmp 81
    elif [ "${RTMP_CONFIG_SIZE}" == "360p" ]; then
        /usr/bin/SendToRTOS rtmp 83
    else
        /usr/bin/SendToRTOS rtmp 82
    fi

    if [ "${RTMP_CONFIG_RATE}" -eq 3 ]; then
        /usr/bin/SendToRTOS rtmp 96
    elif [ "${RTMP_CONFIG_RATE}" -eq 2 ]; then
        /usr/bin/SendToRTOS rtmp 97
    elif [ "${RTMP_CONFIG_RATE}" -eq 1 ]; then
        /usr/bin/SendToRTOS rtmp 98
    else
        /usr/bin/SendToRTOS rtmp 99
    fi
}

WPA_SCAN ()
{
    local fDONE=""

    while [ "${fDONE}" != "OK" ]; do
        fDONE=`wpa_cli -iwlan0 scan | awk '{print $1}'`
        echo "Connect scan wait $((${1} * ${2}))"
        sleep 1
    done
}

WPA_SCAN_DUMP ()
{
    sleep ${1}
    echo "Connect scan dump $((${1} * ${2}))"
    wpa_cli -iwlan0 scan_r >> ${STATION_CONFIG_DATA}
}

WPA_SCAN_FIND ()
{
    local fSCAN=`cat ${STATION_CONFIG_DATA} | grep -Ev "^#"`
    local fMATE=`echo "${fSCAN}" | tr '\t' ' ' | grep -w " ${STATION_CONFIG_SSID}$"`
    local fCMin=1
    local fCMax=`echo "${fMATE}" | wc -l`
    local fFMin=2400
    local fFMax=6000
    local fGOOD=""
    local fRSSI=-90
    local fTEMP=0

    if [ "${STATION_CONFIG_FREQ}" == "yes" ]; then
        fFMin=5000
        fFMax=6000
    elif [ "${STATION_CONFIG_FREQ}" == "no" ]; then
        fFMin=2400
        fFMax=3000
    fi

    while [ ${fCMin} -le ${fCMax} ]; do
        fITEM=`echo "${fMATE}" | sed -n "${fCMin}p"`
        fFREQ=`echo "${fITEM}" | tr '\t' ' ' | cut -d ' ' -f 2`
        fRSSI=`echo "${fITEM}" | tr '\t' ' ' | cut -d ' ' -f 3`
        fCMin=$((${fCMin} + 1))
        if [ "${fITEM}" == "" ] || [ "${fFREQ}" == "" ] || [ "${fRSSI}" == "" ]; then
            continue
        fi
        if [ ${fFREQ} -ge ${fFMin} ] && [ ${fFREQ} -le ${fFMax} ]; then
            if [ "${fGOOD}" != "" ]; then
                fTEMP=`echo "${fGOOD}" | tr '\t' ' ' | cut -d ' ' -f 3`
                if [ ${fTEMP} -lt ${fRSSI} ]; then
                    fGOOD=${fITEM}
                fi
            else
                fGOOD=${fITEM}
            fi
        fi
    done

    if [ "${fGOOD}" != "" ]; then
        echo "${fGOOD}" > ${STATION_CONFIG_FIND}
    fi
}

WPA_AUTO_SCAN ()
{
    local fTick=5
    local fCMin=0
    local fCMax=$((${STATION_DOSCAN_WAIT} / ${fTick}))

    rm -rf ${STATION_CONFIG_DATA}
    rm -rf ${STATION_CONFIG_FIND}

    echo "p2p_disabled=1" > ${STATION_CONFIG_AUTO}
    wpa_supplicant -D${STATION_CONFIG_CDEV} -iwlan0 -C ${STATION_CONFIG_CRUN} -B -c ${STATION_CONFIG_AUTO}

    while [ ${fCMin} -lt ${fCMax} ]; do
        if [ $((${fCMin} % 2)) -eq 0 ]; then
            WPA_SCAN  ${fTick} ${fCMin}
        fi

        WPA_SCAN_DUMP ${fTick} ${fCMin}

        WPA_SCAN_FIND

        if [ -e ${STATION_CONFIG_FIND} ]; then
            break
        fi

        fCMin=$((${fCMin} + 1))
    done

    if [ -e ${STATION_CONFIG_FIND} ]; then
        echo "Connect scan done"
        return 0
    else
        echo "Connect scan fail"
        /usr/bin/SendToRTOS rtmp 128
        return 1
    fi
}

WPA_CONFIG ()
{
    local fFIND=`sed -n "1p" ${STATION_CONFIG_FIND}`
    local fSSID=""
    local fPASS=""
    local fEMAC=""
    local fCWEP=""
    local fCWPA="WPA"
    local fWPA2="WPA2"
    local fCCMP="CCMP"

    rm -rf ${STATION_CONFIG_CWPA}

    if [ "${STATION_CONFIG_SCAN}" == "yes" ]; then
        fSSID=${STATION_CONFIG_SSID}
        fPASS=${STATION_CONFIG_PASS}
        fEMAC=`echo "${fFIND}" | tr '\t' ' ' | cut -d ' ' -f 1`
        fCWEP=`echo "${fFIND}" | grep WEP`
        fCWPA=`echo "${fFIND}" | grep WPA`
        fWPA2=`echo "${fFIND}" | grep WPA2`
        fCCMP=`echo "${fFIND}" | grep CCMP`
    else
        fSSID=${STATION_CONFIG_SSID}
        fPASS=${STATION_CONFIG_PASS}
        fEMAC=${STATION_CONFIG_CMAC}
        fCWEP=""
        fCWPA="WPA"
        fWPA2="WPA2"
        fCCMP="CCMP"
    fi

    echo "ctrl_interface=${STATION_CONFIG_CRUN}" > ${STATION_CONFIG_CWPA}
    echo "network={" >> ${STATION_CONFIG_CWPA}
    echo "ssid=\"${fSSID}\"" >> ${STATION_CONFIG_CWPA}
    if [ "${fEMAC}" != "" ]; then
        echo "bssid=${fEMAC}" >> ${STATION_CONFIG_CWPA}
    fi
    if [ "${STATION_CONFIG_SCAN}" == "yes" ]; then
        echo "scan_ssid=1" >> ${STATION_CONFIG_CWPA}
    else
        echo "scan_ssid=0" >> ${STATION_CONFIG_CWPA}
    fi

    if [ "${fCWPA}" != "" ]; then
        echo "key_mgmt=WPA-PSK" >> ${STATION_CONFIG_CWPA}
        if [ "${fWPA2}" != "" ]; then
            echo "proto=WPA2" >> ${STATION_CONFIG_CWPA}
        else
            echo "proto=WPA" >> ${STATION_CONFIG_CWPA}
        fi
        if [ "${fCCMP}" != "" ]; then
            echo "pairwise=CCMP" >> ${STATION_CONFIG_CWPA}
        else
            echo "pairwise=TKIP" >> ${STATION_CONFIG_CWPA}
        fi
        echo "psk=\"${fPASS}\"" >> ${STATION_CONFIG_CWPA}
    fi
    if [ "${fCWEP}" != "" ] && [ "${fCWPA}" == "" ]; then
        echo "key_mgmt=NONE" >> ${STATION_CONFIG_CWPA}
        echo "wep_key0=${fPASS}" >> ${STATION_CONFIG_CWPA}
        echo "wep_tx_keyidx=0" >> ${STATION_CONFIG_CWPA}
    fi
    if [ "${fCWEP}" == "" ] && [ "${fCWPA}" == "" ]; then
        echo "key_mgmt=NONE" >> ${STATION_CONFIG_CWPA}
    fi
    echo "}" >> ${STATION_CONFIG_CWPA}

    if [ -e /sys/module/bcmdhd ]; then
        echo "p2p_disabled=1" >> ${STATION_CONFIG_CWPA}
        #if [ "`uname -r`" != "2.6.38.8" ]; then
        #    echo "wowlan_triggers=any" >> ${STATION_CONFIG_CWPA}
        #fi
    fi
}

WPA_GO ()
{
    killall -9 wpa_supplicant udhcpc dnsmasq wpa_cli 2>/dev/null
   #killall -9 wpa_supplicant 2>/dev/null
    wpa_supplicant -D${STATION_CONFIG_CDEV} -iwlan0 -c${STATION_CONFIG_CWPA} -B

    if [ "${STATION_CONFIG_ADDR}" != "" ]; then
        ifconfig wlan0 ${STATION_CONFIG_ADDR} netmask 255.255.255.0
    else
        if [ "${STATION_CONFIG_NAME}" != "" ]; then
            udhcpc -i wlan0 -A 1 -b -x hostname:${STATION_CONFIG_NAME}
        else
            udhcpc -i wlan0 -A 1 -b
        fi
    fi
}

WAIT_IP_DONE()
{
    local fCMin=1
    local fCMax=${STATION_IPADDR_WAIT}
    local fDATA=""

    while [ "${fDATA}" == "" ] && [ ${fCMin} -le ${fCMax} ]; do
        fDATA=`ifconfig wlan0 | grep "inet addr"`
        echo "Connect ip wait ${fCMin}"
        fCMin=$((${fCMin} + 1))
        sleep 1
    done

    if [ "${fDATA}" != "" ]; then
        echo "Connect ip done"
        /usr/bin/SendToRTOS sta_connected $REMASK
        sleep 0.5
        /usr/bin/SendToRTOS rtmp 3
        RTSP_CONF
    else
        fDATA=`/bin/dmesg | grep DEAUTH_IND`
        if [ "${fDATA}" != "" ]; then
            echo "Connect ip error"
            /usr/bin/SendToRTOS rtmp 129
        else
            echo "Connect ip fail"
            /usr/bin/SendToRTOS rtmp 130
        fi
    fi
}

if [ "${STATION_CONFIG_SCAN}" == "yes" ]; then
    WPA_AUTO_SCAN
    if [ $? -ne 0 ]; then
        exit 0
    fi
fi

WPA_CONFIG

WPA_GO

WAIT_IP_DONE

exit 0
