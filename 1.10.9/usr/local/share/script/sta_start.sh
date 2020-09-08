#!/bin/sh

CONFIG_CDEV=nl80211
STATION_CONFIG_AUTO=/tmp/wpa_scan.conf
STATION_CONFIG_CRUN=/var/run/wpa_supplicant
STATION_CONFIG_CWPA=/tmp/wpa_supplicant.conf
STATION_CONFIG_DATA=/tmp/station.scan
STATION_CONFIG_FIND=/tmp/station.find

check_country_setting_channel()
{
	echo $AP_COUNTRY
	case $AP_COUNTRY in
		HK | ID | MY | UA | IN | MX | VN | BY | MM | BD | IR)
		wl country XZ/0
		;;
		ES | FR | PL | DE | IT | GB | PT | GR | NL | HU | SK | NO | FI)
		wl country EU/0
		;;
		CA)
		wl country CA/2
		;;
		CN)
		wl country CN
		;;
		CZ)
		wl country CZ
		;;
		US)
		wl country US
		;;
		RU)
		wl country RU
		;;
		JP)
		wl country JP/5
		;;
		KR)
		wl country KR/24
		;;
		IL)
		wl country IL
		;;
		SE)
		wl country SE
		;;
		SG)
		wl country SG
		;;
		TR)
		wl country TR/7
		;;
		TW)
		wl country TW/2
		;;
		AU)
		wl country AU
		;;
		BR)
		wl country BR
		;;
		TH)
		wl country TH
		;;
		PH)
		wl country PH
		;;
	esac
}

wait_ip_done ()
{
	local fWaiting=0
	local fDATA=""
	while [ "${fDATA}" == "" ] && [ $fWaiting -le 10 ]; do
		fDATA=`ifconfig wlan0|grep "inet addr"`
		echo "Connect ip wait ${fWaiting}"
		fWaiting=$(($fWaiting + 1))
		sleep 1
	done

	if [ "${fDATA}" != "" ]; then
		echo "Connect ip done"
		#send net status update message (Network ready, STA mode)
		/usr/bin/SendToRTOS net_ready ${ESSID}
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
	local fMATE=`echo "${fSCAN}" | tr '\t' ' ' | grep -w " ${ESSID}$"`
	local fCMin=1
	local fCMax=`echo "${fMATE}" | wc -l`
	local fFMin=2400
	local fFMax=6000
	local fGOOD=""
	local fRSSI=-90
	local fTEMP=0

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

	echo "AUTO SCAN >> ESSID = ${ESSID}   PASSWORD = ${PASSWORD}   rssitmp = ${fRSSI}"
}

WPA_AUTO_SCAN()
{

	local fTick=5
	local fCMin=0
	local fCMax=$((60 / ${fTick}))

	echo "p2p_disabled=1" > ${STATION_CONFIG_AUTO}
	wpa_supplicant -D${CONFIG_CDEV} -iwlan0 -C ${STATION_CONFIG_CRUN} -B -c ${STATION_CONFIG_AUTO}

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
		echo -e "\033[031m failed to detect SSID ${ESSID}, force FAKE ESSID to be able to control the cam (manual stop). \033[0m"
		/usr/bin/SendToRTOS net_ready "FAKE"
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

	fSSID=${ESSID}
	fPASS=${PASSWORD}
	fEMAC=`echo "${fFIND}" | tr '\t' ' ' | cut -d ' ' -f 1`
	fCWEP=`echo "${fFIND}" | grep WEP`
	fCWPA=`echo "${fFIND}" | grep WPA`
	fWPA2=`echo "${fFIND}" | grep WPA2`
	fCCMP=`echo "${fFIND}" | grep CCMP`

	echo -e "\033[031m ${fFIND} \033[0m"
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

	rm -f ${STATION_CONFIG_AUTO}
	echo "p2p_disabled=1" >> ${STATION_CONFIG_CWPA}
}

WPA_GO ()
{
	killall -9 wpa_supplicant 2>/dev/null
	wpa_supplicant -D${CONFIG_CDEV} -iwlan0 -c${STATION_CONFIG_CWPA} -B
	if [ "$STA_IP" != "" ]; then
		ifconfig wlan0 $STA_IP netmask 255.255.255.0
	else
		if [ "$STA_DEVICE_NAME" != " " ]; then
			udhcpc -i wlan0 -A 1 -b -x hostname:${STA_DEVICE_NAME}
		else
			udhcpc -i wlan0 -A 1 -b -x hostname:'XiaoYi SportCam 2'
		fi
	fi
	wait_ip_done
}

# Already configured, fire the connection
if [ "${1}" != "" ] && [ -e ${STATION_CONFIG_CWPA} ]; then
	WPA_GO
	exit 0
fi

ifconfig wlan0 up
check_country_setting_channel
WPA_AUTO_SCAN
if [ $? -ne 0 ]; then
	exit 1
fi

WPA_CONFIG

WPA_GO
