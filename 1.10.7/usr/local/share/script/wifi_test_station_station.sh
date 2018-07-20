#!/bin/sh

STATION_CONFIG_SSID=${STA_SSID}
STATION_CONFIG_PASS=${STA_PASSWD}
STATION_CONFIG_FREQ=${STA_FREQ}
STATION_CONFIG_NAME=${STA_NAME}
STATION_CONFIG_ADDR=${STA_IP}
STATION_CONFIG_SCAN=${STA_SCAN}

STATION_CONFIG_CDEV=nl80211
STATION_CONFIG_AUTO=/tmp/station.auto.scan.conf
STATION_CONFIG_CRUN=/var/run/wpa_supplicant
STATION_CONFIG_CWPA=/tmp/wpa_supplicant.conf
STATION_CONFIG_TEMP=/tmp/station.temp
STATION_CONFIG_DATA=/tmp/station.scan
STATION_CONFIG_LIST=/tmp/station.list
STATION_CONFIG_MATE=/tmp/station.mate
STATION_CONFIG_FIND=/tmp/station.find

STATION_NOTIFY_KILL_SELF=0
STATION_NOTIFY_CONN_IPOK=1
STATION_NOTIFY_AWPA_CONF=-1
STATION_NOTIFY_MWPA_CONF=-2
STATION_NOTIFY_SCAN_TOUT=-3
STATION_NOTIFY_CONN_IPNG=-4

NOTIFY_RTOS ()
{
    if [ $# -gt 0 ]; then
        if [ $# -gt 1 ]; then
            /usr/bin/SendToRTOS test_station $1 $2
        else
            /usr/bin/SendToRTOS test_station $1
        fi
    fi
}

LIST_PRINT ()
{
    local fCMin=1
    local fCMax=`cat ${STATION_CONFIG_LIST} | wc -l`
    local fITEM=""
    local fSCAN="yes"
    local fSSID=""
    local fPASS=""
    local fFREQ=""
    local fADDR=""
    local fNAME=""

    if [ ${STATION_CONFIG_SCAN} -le 0 ]; then
        fSCAN="no"
    fi

    echo "////////////////////////////////////////"
    echo "/"
    echo "/ station mode(auto scan: ${fSCAN})"
    echo "/"

    while [ ${fCMin} -le ${fCMax} ]; do
        fITEM=`sed -n "${fCMin}p" ${STATION_CONFIG_LIST}`
        fSSID=`echo "${fITEM}" | tr '\t' ' ' | cut -d ' ' -f 1`
        fPASS=`echo "${fITEM}" | tr '\t' ' ' | cut -d ' ' -f 2`
        fFREQ=`echo "${fITEM}" | tr '\t' ' ' | cut -d ' ' -f 3`
        fADDR=`echo "${fITEM}" | tr '\t' ' ' | cut -d ' ' -f 4`
        fNAME=`echo "${fITEM}" | tr '\t' ' ' | cut -d ' ' -f 5`

            echo "/ SSID       = ${fSSID}"
            echo "/ Password   = ${fPASS}"
        if [ ${fFREQ} -le 0 ]; then
            echo "/ Frequency  = 2.4G"
        else
            echo "/ Frequency  = 5G"
        fi
        if [ "${fADDR}" != "" ] && [ "${fADDR}" != "NULL" ]; then
            echo "/ IP Address = ${fADDR}"
        else
            echo "/ IP Address = auto"
        fi
        if [ "${fNAME}" != "" ] && [ "${fNAME}" != "NULL" ]; then
            echo "/ Name       = ${fNAME}"
        fi
        if [ ${fCMin} -lt ${fCMax} ]; then
            echo "/"
        fi
        fCMin=$((${fCMin} + 1))
    done

    echo "////////////////////////////////////////"
}

CREATE_LIST ()
{
    local fFREQ=0

    if [ ${STATION_CONFIG_FREQ} -gt 0 ]; then
        fFREQ=1
    fi

    rm -rf ${STATION_CONFIG_LIST}
    echo "${STATION_CONFIG_SSID} ${STATION_CONFIG_PASS} ${fFREQ} ${STATION_CONFIG_ADDR} ${STATION_CONFIG_NAME}" > ${STATION_CONFIG_LIST}
}

WPA_SCAN ()
{
    local fDATA=""

    rm -rf ${STATION_CONFIG_TEMP}

    while [ "${fDATA}" != "OK" ]; do
        sleep 1
        wpa_cli scan | awk '{print $1}' > ${STATION_CONFIG_TEMP}
        fDATA=`sed -n '2p' ${STATION_CONFIG_TEMP}`
    done
}

WPA_SCAN_EXPORT ()
{
    sleep 4
    wpa_cli scan_r >> ${STATION_CONFIG_DATA}
}

WPA_SCAN_MATE ()
{
    local fCMin=1
    local fCMax=`cat ${STATION_CONFIG_MATE} | wc -l`
    local fITEM=""
    local fSAVE=""
    local fGOOD=""
    local fFREQ=0
    local fRSSI=0
    local fTEMP=0
    local fFMin=2400
    local fFMax=3000

    if [ $# -gt 0 ] && [ $1 -gt 0 ]; then
        fFMin=5000
        fFMax=6000
    fi

    while [ ${fCMin} -le ${fCMax} ]; do
        fITEM=`sed -n "${fCMin}p" ${STATION_CONFIG_MATE}`
        fFREQ=`echo "${fITEM}" | tr '\t' ' ' | cut -d ' ' -f 2`
        fRSSI=`echo "${fITEM}" | tr '\t' ' ' | cut -d ' ' -f 3`
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
        fCMin=$((${fCMin} + 1))
    done

    if [ "${fGOOD}" != "" ]; then
        echo "${fGOOD}" >> ${STATION_CONFIG_FIND}
    fi
}

WPA_SCAN_FIND ()
{
    local fCMin=1
    local fCMax=`cat ${STATION_CONFIG_LIST} | wc -l`
    local fSCAN=`cat ${STATION_CONFIG_DATA} | grep -Ev "^#"`
    local fITEM=""
    local fSSID=""
    local fMATE=""
    local fGOOD=""
    local fRSSI=-90
    local fTEMP=0
    local fFREQ=0

    rm -rf ${STATION_CONFIG_FIND}

    while [ ${fCMin} -le ${fCMax} ]; do
        fITEM=`sed -n "${fCMin}p" ${STATION_CONFIG_LIST}`
        fSSID=`echo "${fITEM}" | tr '\t' ' ' | cut -d ' ' -f 1`
        fFREQ=`echo "${fITEM}" | tr '\t' ' ' | cut -d ' ' -f 3`
        fMATE=`echo "${fSCAN}" | tr '\t' ' ' | grep -w " ${fSSID}$"`
        if [ "${fMATE}" != "" ]; then
            echo "${fMATE}" > ${STATION_CONFIG_MATE}
            WPA_SCAN_MATE ${fFREQ}
        fi
        fCMin=$((${fCMin} + 1))
    done

    fCMin=1
    fCMax=`cat ${STATION_CONFIG_FIND} | wc -l`
    while [ ${fCMin} -le ${fCMax} ]; do
        fITEM=`sed -n "${fCMin}p" ${STATION_CONFIG_FIND}`
        fTEMP=`echo "${fITEM}" | tr '\t' ' ' | cut -d ' ' -f 3`
        if [ ${fTEMP} -gt ${fRSSI} ]; then
            fGOOD=${fITEM}
            fRSSI=${fTEMP}
        fi
        fCMin=$((${fCMin} + 1))
    done

    rm -rf ${STATION_CONFIG_FIND}

    if [ "${fGOOD}" != "" ]; then
        echo "${fGOOD}" > ${STATION_CONFIG_FIND}
    fi
}

WPA_AUTO_SCAN ()
{
    local fTick=5
    local fCMin=1
    local fCMax=15

    rm -rf ${STATION_CONFIG_DATA}
    rm -rf ${STATION_CONFIG_FIND}

    echo "p2p_disabled=1" >> ${STATION_CONFIG_AUTO}
    wpa_supplicant -D${STATION_CONFIG_CDEV} -iwlan0 -C ${STATION_CONFIG_CRUN} -B -c ${STATION_CONFIG_AUTO}

    while [ ${fCMin} -le ${fCMax} ]; do
        fCMin=$((${fCMin} - 1))
        if [ $((${fCMin} % ${fTick})) -eq 0 ]; then
            WPA_SCAN
        fi
        fCMin=$((${fCMin} + 1))

        WPA_SCAN_EXPORT

        WPA_SCAN_FIND

        if [ -e ${STATION_CONFIG_FIND} ]; then
            break
        fi
        fCMin=$((${fCMin} + 1))
    done
}

WPA_CONFIG ()
{
    local fCMin=1
    local fCMax=`cat ${STATION_CONFIG_LIST} | wc -l`
    local fFIND=`sed -n "1p" ${STATION_CONFIG_FIND}`
    local fITEM=""
    local fSSID=""
    local fPASS=""
    local fEMAC=""
    local fLIST=""
    local fCWEP=""
    local fCWPA="WPA"
    local fWPA2="WPA2"
    local fCCMP="CCMP"
    local fTKIP=""
    local fADDR=""
    local fNAME=""
    local fSCAN=0

    rm -rf ${STATION_CONFIG_CWPA}

    if [ $# -le 0 ]; then
        return
    fi

    if [ $1 -le 0 ] && [ ${fCMax} -gt 0 ]; then
        return
    fi

    if [ $1 -le 0 ]; then
        fITEM=`sed -n "1p" ${STATION_CONFIG_LIST}`
        fSSID=`echo "${fITEM}" | tr '\t' ' ' | cut -d ' ' -f 1`
        fPASS=`echo "${fITEM}" | tr '\t' ' ' | cut -d ' ' -f 2`
        fADDR=`echo "${fITEM}" | tr '\t' ' ' | cut -d ' ' -f 4`
        fNAME=`echo "${fITEM}" | tr '\t' ' ' | cut -d ' ' -f 5`
        fEMAC=""
        fCWEP=""
        fCWPA="WPA"
        fWPA2="WPA2"
        fCCMP="CCMP"
        fTKIP=""
    else
        while [ ${fCMin} -le ${fCMax} ]; do
            fITEM=`sed -n "${fCMin}p" ${STATION_CONFIG_LIST}`
            fSSID=`echo "${fITEM}" | tr '\t' ' ' | cut -d ' ' -f 1`
            fLIST=`echo "${fFIND}" | tr '\t' ' ' | grep -w " ${fSSID}$"`
            if [ "${fLIST}" != "" ]; then
                fEMAC=`echo "${fFIND}" | tr '\t' ' ' | cut -d ' ' -f 1`
                fCWEP=`echo "${fFIND}" | grep WEP`
                fCWPA=`echo "${fFIND}" | grep WPA`
                fWPA2=`echo "${fFIND}" | grep WPA2`
                fCCMP=`echo "${fFIND}" | grep CCMP`
                fTKIP=`echo "${fFIND}" | grep TKIP`
                fPASS=`echo "${fITEM}" | tr '\t' ' ' | cut -d ' ' -f 2`
                fADDR=`echo "${fITEM}" | tr '\t' ' ' | cut -d ' ' -f 4`
                fNAME=`echo "${fITEM}" | tr '\t' ' ' | cut -d ' ' -f 5`
                fSCAN=1
                break
            fi
            fCMin=$((${fCMin} + 1))
        done
    fi

    if [ "${fPASS}" == "" ]; then
        return
    fi

    if [ "${fADDR}" != "" ] && [ "${fADDR}" != "NULL" ]; then
        STATION_CONFIG_ADDR=${fADDR}
    else
        STATION_CONFIG_ADDR=
    fi
    if [ "${fNAME}" != "" ] && [ "${fNAME}" != "NULL" ]; then
        STATION_CONFIG_NAME=${fNAME}
    else
        STATION_CONFIG_NAME=
    fi

    echo "ctrl_interface=${STATION_CONFIG_CRUN}" > ${STATION_CONFIG_CWPA}
    echo "network={" >> ${STATION_CONFIG_CWPA}
    echo "ssid=\"${fSSID}\"" >> ${STATION_CONFIG_CWPA}
    if [ "${fEMAC}" != "" ]; then
        echo "bssid=${fEMAC}" >> ${STATION_CONFIG_CWPA}
    fi
    if [ ${fSCAN} -gt 0 ]; then
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
        rm -rf ${STATION_CONFIG_AUTO}
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
            udhcpc -i wlan0 -h '${STATION_CONFIG_NAME}' -A 1 -b
        else
            udhcpc -i wlan0 -A 1 -b
        fi
    fi
}

WAIT_IP_DONE()
{
    local fCMin=1
    local fCMax=10
    local fDATA=""

    while [ "${fDATA}" == "" ] && [ ${fCMin} -le ${fCMax} ]; do
        fDATA=`ifconfig wlan0 | grep "inet addr"`
        fCMin=$((${fCMin} + 1))
        sleep 1
    done

    if [ "${fDATA}" == "" ]; then
        return 0
    else
        return 1
    fi
}

LOCAL_IP ()
{
    local fIP=`ifconfig -a | grep inet | grep -v 127.0.0.1 | grep -v inet6 | awk '{print $2}' | tr -d "addr:"`
    STATION_CONFIG_ADDR=${fIP}
}

CREATE_LIST

#LIST_PRINT

if [ ${STATION_CONFIG_SCAN} -gt 0 ]; then
    WPA_AUTO_SCAN
    if [ -e ${STATION_CONFIG_FIND} ]; then
        WPA_CONFIG 1
        if [ ! -e ${STATION_CONFIG_CWPA} ]; then
            NOTIFY_RTOS ${STATION_NOTIFY_AWPA_CONF}
            exit 0
        fi
    else
        NOTIFY_RTOS ${STATION_NOTIFY_SCAN_TOUT}
        exit 0
    fi
else
    WPA_CONFIG 0
    if [ ! -e ${STATION_CONFIG_CWPA} ]; then
        NOTIFY_RTOS ${STATION_NOTIFY_MWPA_CONF}
        exit 0
    fi
fi

WPA_GO

WAIT_IP_DONE

if [ $? -gt 0 ]; then
    LOCAL_IP
    NOTIFY_RTOS ${STATION_NOTIFY_CONN_IPOK} ${STATION_CONFIG_ADDR}
else
    NOTIFY_RTOS ${STATION_NOTIFY_CONN_IPNG}
fi

exit 0
