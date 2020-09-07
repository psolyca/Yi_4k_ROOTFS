#!/bin/sh

kernel_ver=$(uname -r)
ETHER_IP=`cat /tmp/wifi.conf | grep "ETHER_IP" | cut -c 10-`

start()
{
    echo device > /proc/ambarella/usbphy0

    /usr/local/share/script/insert_usb_modules.sh start

    if [ -r /lib/modules/$kernel_ver/kernel/drivers/usb/gadget/g_ether.ko ]; then
        modprobe g_ether
        ifconfig usb0 $ETHER_IP up

        echo "\"ifconfig usb0 $ETHER_IP\" after host detects usb ethernet device."
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

