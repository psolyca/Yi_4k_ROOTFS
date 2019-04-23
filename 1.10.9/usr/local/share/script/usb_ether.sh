#!/bin/sh

echo device > /proc/ambarella/usbphy0
modprobe usbcore
modprobe ehci-hcd
#modprobe ohci-hcd
modprobe udc-core
modprobe ambarella_udc
modprobe libcomposite
modprobe g_ether
ifconfig usb0 192.168.40.1 netmask 255.255.255.0 up

echo "\"ifconfig usb0 your_ip\" after host detects usb ethernet device."

