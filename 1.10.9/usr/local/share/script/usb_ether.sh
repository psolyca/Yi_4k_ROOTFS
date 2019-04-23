#!/bin/sh

ether_ip="$2"

start()
{
    echo device > /proc/ambarella/usbphy0
    modprobe usbcore
    modprobe ehci-hcd
    #modprobe ohci-hcd
    modprobe udc-core
    modprobe ambarella_udc
    modprobe libcomposite
    modprobe g_ether
    ifconfig usb0 $ether_ip up

    echo "\"ifconfig usb0 $ether_ip\" after host detects usb ethernet device."
}

stop()
{
    ifconfig usb0 down
    rmmod g_ether
}

case "$1" in
    start)
        start
        ;;
    stop)
        stop
        ;;
    *)
        echo "Usage $0 {start|stop}"
        exit 1
esac

exit $?

