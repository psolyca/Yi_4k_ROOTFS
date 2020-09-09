#!/bin/sh

CONFIG_CDEV=nl80211
AP_CONFIG_HOST=/tmp/hostapd.conf
AP_CONFIG_CWPA=/tmp/wpa_supplicant.ap.conf

wpa_supplicant_conf()
{
    #generate /tmp/wpa_supplicant.ap.conf
    echo "ctrl_interface=/var/run/wpa_supplicant" > ${AP_CONFIG_CWPA}
    echo "ap_scan=2" >> ${AP_CONFIG_CWPA}

    #AP_MAXSTA
    echo "max_num_sta=${AP_MAXSTA}" >> ${AP_CONFIG_CWPA}

    echo "network={" >> ${AP_CONFIG_CWPA}
    #AP_SSID
    echo "AP_SSID=${AP_SSID}"
    if [ "$AP_SSID" == "YDXJ_AP" ]; then
        APS=`echo $(($RANDOM))`
        APS="YDXJ_$(((($APS % 3) * 1000000) + (($APS % 4) * 100000) + (($APS % 5) * 10000) + 0476))"
        echo "$APS"
        export AP_SSID="$APS"
        if [ $AP_CHANNEL_5G -eq 1 ]; then
            export AP_SSID="${APS}_5G"
        fi
    fi
    echo "ssid=\"${AP_SSID}\"" >> ${AP_CONFIG_CWPA}

    /usr/local/share/script/channel43340.sh
    AP_CHANNEL=$?

    # cf. http://en.wikipedia.org/wiki/List_of_WLAN_channels
    if [ $AP_CHANNEL -lt 14 ]; then
        # 2.4G: 2412 + (ch-1) * 5
        echo "frequency=$((2412 + ($AP_CHANNEL - 1) * 5))" >> ${AP_CONFIG_CWPA}
    else
        # 5G: 5000 + ch * 5
        echo "frequency=$((5000 + $AP_CHANNEL * 5))" >> ${AP_CONFIG_CWPA}
    fi

    #WEP, WPA, No Security
    if [ "${AP_PUBLIC}" != "yes" ]; then
        # proto defaults to: WPA RSN
        echo "proto=WPA2" >> ${AP_CONFIG_CWPA}
        echo "pairwise=CCMP" >> ${AP_CONFIG_CWPA}
        echo "group=CCMP" >> ${AP_CONFIG_CWPA}
        echo "psk=\"${AP_PASSWD}\"" >> ${AP_CONFIG_CWPA}
        echo "key_mgmt=WPA-PSK" >> ${AP_CONFIG_CWPA}
    else
        echo "key_mgmt=NONE" >> ${AP_CONFIG_CWPA}
    fi
    echo "mode=2" >> ${AP_CONFIG_CWPA}
    echo "}" >> ${AP_CONFIG_CWPA}
    echo "p2p_disabled=1" >> ${AP_CONFIG_CWPA}

}

apply_ap_conf()
{
    #LOCAL_IP
    killall udhcpc
    ifconfig wlan0 $LOCAL_IP
    #route add default gw $LOCAL_IP

    #LOCAL_NETMASK
    ifconfig wlan0 netmask $LOCAL_NETMASK

    #DHCP_IP_START DHCP_IP_END

    nets=`ls /sys/class/net/|grep -v lo|grep -v wlan|grep -v p2p|grep -v ap`
    for lte in ${nets}; do
        eth=`echo "${lte}" | grep eth`
        if [ "${eth}" == "" ]; then
            #qualcomm ppp0 or wwan0
            mobile=1
            break
        else
            #altair eth1
            cdc_ether=`readlink /sys/class/net/${eth}/device/driver|grep cdc_ether`
            if [ "${cdc_ether}" != "" ]; then
                mobile=1
                break
            fi
        fi
    done

    if [ "${mobile}" == "1" ]; then
        dnsmasq -5 -K --log-queries --dhcp-range=$DHCP_IP_START,$DHCP_IP_END,infinite
    else
        dnsmasq --nodns -5 -K -R -n --dhcp-range=$DHCP_IP_START,$DHCP_IP_END,infinite
    fi

    wpa_supplicant_conf

    wpa_supplicant -D${CONFIG_CDEV} -iwlan0 -c${AP_CONFIG_CWPA} -B

    #send net status update message (Network ready, AP mode)
    /usr/bin/SendToRTOS net_ready ${AP_SSID}

    return 0
}

#Load the parameter settings
apply_ap_conf
rval=$?
echo -e "rval=${rval}\n"
if [ ${rval} -ne 0 ]; then
    killall -9 hostapd wpa_supplicant dnsmasq 2>/dev/null
    apply_ap_conf
fi
