#!/bin/sh

kernel_ver=$(uname -r)

WIFI_CONFIGURE_PATH="/tmp/wifi.conf"
ether=`cat ${WIFI_CONFIGURE_PATH} | grep -E "^ETHER"`
export `echo "${ether}"`

wait_ip_done ()
{
	local fWaiting=0
	local fDATA=""
	while [ "${fDATA}" == "" ] && [ $fWaiting -le 10 ]; do
		fDATA=`ifconfig usb0 | grep "inet addr"`
		echo "Connect ip wait ${fWaiting}"
		fWaiting=$(($fWaiting + 1))
		sleep 1
	done

	if [ "${fDATA}" != "" ]; then
		echo "Connect ip done for usb0"
	else
		echo "Connect ip fail for usb0"
	fi
}

usb_dhcp()
{
    ifconfig usb0 netmask 255.255.255.0
    udhcpc -i usb0 -A 1 -b -x hostname:${ETHER_DEVICE_NAME}
}

usb_static()
{
    ifconfig usb0 $ETHER_IP
    ifconfig usb0 netmask 255.255.255.0
    dnsmasq -i usb0 --nodns -5 -R -n --dhcp-range=$ETHER_DHCP_IP_START,$ETHER_DHCP_IP_END,infinite
}

start()
{
    echo device > /proc/ambarella/usbphy0

    /usr/local/share/script/insert_usb_modules.sh start

    if [ -r /lib/modules/$kernel_ver/kernel/drivers/usb/gadget/g_ether.ko ]; then
        modprobe g_ether
        ifconfig usb0 up
        if [ -z $ETHER_IP ]; then
            usb_dhcp
        else
            usb_static
        fi
        wait_ip_done

    fi
}

stop()
{
    ifconfig usb0 down
    rmmod g_ether
}

case "$1" in
    start)
        echo "Start ethernet over USB"
        start
        ;;
    stop)
        echo "Stop ethernet over USB"
        stop
        ;;
    *)
        echo "Usage $0 {start|stop}"
        exit 1
esac

exit $?

