#!/bin/sh
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

wait_ip_done ()
{
	n=0
	wlan0_ready=`ifconfig wlan0|grep "inet addr"`
	while [ "${wlan0_ready}" == "" ] && [ $n -ne 10 ]; do
		wlan0_ready=`ifconfig wlan0|grep "inet addr"`
		n=$(($n + 1))
		sleep 1
	done

	if [ "${wlan0_ready}" != "" ]; then
		#send net status update message (Network ready, STA mode)
		if [ -x /usr/bin/SendToRTOS ]; then
			/usr/bin/SendToRTOS sta_connected $REMASK
		elif [ -x /usr/bin/boot_done ]; then
			boot_done 1 2 1
		fi
	else
		echo "Cannot get IP within 10 sec, skip boot_done"
	fi
}
checkfuse=`cat /proc/mounts | grep /tmp/fuse_d`
if [ "${checkfuse}" == "" ]; then
	fuse_d="/tmp/SD0"
else
	fuse_d="/tmp/fuse_d"
fi

if [ "${1}" != "" ] && [ -e /tmp/wpa_supplicant.conf ]; then
	cat /tmp/wpa_supplicant.conf
	wpa_supplicant -D${driver} -iwlan0 -c/tmp/wpa_supplicant.conf -B
    if [ "$STA_DEVICE_NAME" != " " ]; then
        udhcpc -i wlan0 -h "${STA_DEVICE_NAME}" -A 1 -b
    else
        udhcpc -i wlan0 -h 'XiaoYi SportCam 2' -A 1 -b
    fi
	wait_ip_done
	exit 0
fi
REMASK=0
FORCE_RESCAN_TIMES=8
wpa_def_scan()
{
	if [ -e /sys/module/bcmdhd ]; then
		echo "p2p_disabled=1" > /tmp/wpa_scan.conf
		wpa_supplicant -D${driver} -iwlan0 -C /var/run/wpa_supplicant -B -c /tmp/wpa_scan.conf
	else
		wpa_supplicant -D${driver} -iwlan0 -C /var/run/wpa_supplicant -B
	fi
	wpa_cli scan
	echo "start 10 seconds scan for ${ESSID}"
	sleep 3
	scan_result=`wpa_cli scan_r`
	scan_entry=`echo "${scan_result}" | tr '\t' ' ' | grep " ${ESSID}$" | tail -n 1`
	echo "${scan_result}"
	n=1
	while [ "${scan_entry}" == "" ] && [ $n -ne 8 ]; do
		echo; sleep 1
		n=$(($n + 1))
		scan_result=`wpa_cli scan_r`
		echo "${scan_result}"
		scan_entry=`echo "${scan_result}" | tr '\t' ' ' | grep " ${ESSID}$" | tail -n 1`
	done
}
wpa_auto_scan()
{
	echo "p2p_disabled=1" > /tmp/wpa_scan.conf
	wpa_supplicant -D${driver} -iwlan0 -C /var/run/wpa_supplicant -B -c /tmp/wpa_scan.conf
	wpa_cli scan
	rm /tmp/wpa_scan.conf
	sleep 6
	n=`cat /pref/wifi_sta_list.conf | wc -l`
	name=`sed -n '1p' /pref/wifi_sta_list.conf`
	scan_retry=1
	wpa_cli scan_r > /tmp/tmp.scan
	sleep 0.1
	scan_result=`cat /tmp/tmp.scan | grep -Ev "^#"`
	#echo "${scan_result}"
	j=1
	rssitmp=-90
	while [ "$scan_retry" -le "$n" ]; do
		ESSIDTMP=`echo "${name}" | cut -f 1`
		PASSWORDTMP=`echo "${name}" | cut -f 2`
		REMASKTMP=`echo "${name}" | cut -f 3`
		scan_entry_tmp=`echo "${scan_result}" | tr '\t' ' ' | grep -w " ${ESSIDTMP}$" | tail -n 1`
		#echo "${scan_result}"
		if [ "${scan_entry_tmp}" != "" ]; then
			rssi=`echo "${scan_result}"  | grep -w "${ESSIDTMP}" | cut -f 3`
			echo "rssi ====>> $rssi"
			if [ "$rssi" -ge "$rssitmp" ]; then
				ESSID=$ESSIDTMP
				PASSWORD=$PASSWORDTMP
				REMASK=$REMASKTMP
				rssitmp=$rssi
				scan_entry=$scan_entry_tmp
			fi
		fi
		j=$(($j + 1))
		p="p"
		scan_retry=$(($scan_retry + 1))
		name=`sed -n "$j$p" /pref/wifi_sta_list.conf`
	done
	rm /tmp/tmp.scan

	echo "AUTO SCAN >> ESSID = ${ESSID}   PASSWORD = ${PASSWORD}   REMASK = ${REMASK}   rssitmp = ${rssitmp}"
}
WPA_SCAN ()
{
	if [ -e /pref/wifi_sta_list.conf ]; then
		wpa_auto_scan
	else
		wpa_def_scan
	fi
}

WPA_GO ()
{
	killall -9 wpa_supplicant 2>/dev/null
	wpa_supplicant -D${driver} -iwlan0 -c/tmp/wpa_supplicant.conf -B
    if [ "$STA_DEVICE_NAME" != " " ]; then
	    udhcpc -i wlan0 -h "${STA_DEVICE_NAME}" -A 1 -b
    else
	    udhcpc -i wlan0 -h 'XiaoYi SportCam 2' -A 1 -b
    fi
	wait_ip_done
}


check_country_setting_channel
WPA_SCAN
killall wpa_supplicant
if [ "${scan_entry}" == "" ]; then
	scan_retry_count=0
	while [ "${scan_entry}" == "" ] && [ $scan_retry_count -ne $FORCE_RESCAN_TIMES ]; do
		echo "will retry for $FORCE_RESCAN_TIMES times, start re-scan $scan_retry_count"
		WPA_SCAN
		killall wpa_supplicant
		scan_retry_count=$(($scan_retry_count + 1))
	done
fi

if [ "${scan_entry}" == "" ]; then
	echo -e "\033[031m failed to detect SSID ${ESSID}, use /usr/local/share/script/wpa_supplicant.conf: \033[0m"
	cp /usr/local/share/script/wpa_supplicant.conf /tmp/
	cat /tmp/wpa_supplicant.conf
	WPA_GO
	exit 0
fi

echo -e "\033[031m ${scan_entry} \033[0m"
echo "ctrl_interface=/var/run/wpa_supplicant" > /tmp/wpa_supplicant.conf
echo "network={" >> /tmp/wpa_supplicant.conf
echo "ssid=\"${ESSID}\"" >> /tmp/wpa_supplicant.conf
echo "scan_ssid=1" >> /tmp/wpa_supplicant.conf
WEP=`echo "${scan_entry}" | grep WEP`
WPA=`echo "${scan_entry}" | grep WPA`
WPA2=`echo "${scan_entry}" | grep WPA2`
CCMP=`echo "${scan_entry}" | grep CCMP`
TKIP=`echo "${scan_entry}" | grep TKIP`

if [ "${WPA}" != "" ]; then
	#WPA2-PSK-CCMP	(11n requirement)
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

