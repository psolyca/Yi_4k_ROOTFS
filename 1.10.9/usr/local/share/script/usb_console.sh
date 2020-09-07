#!/bin/sh -x

kernel_ver=$(uname -r)
SYS_USB_G_TYPE="serial"
SYS_USB_G_PARAMETER="use_acm=1"

killall syslogd
echo device > /proc/ambarella/usbphy0

/usr/local/share/script/insert_usb_modules.sh start

if [ -r /lib/modules/$kernel_ver/kernel/drivers/usb/gadget/g_$SYS_USB_G_TYPE.ko ]; then
    modprobe g_$SYS_USB_G_TYPE $SYS_USB_G_PARAMETER
fi

su root -c "/sbin/getty -n -L 115200 /dev/ttyGS0 &"
klogd
syslogd -O /dev/ttyGS0
