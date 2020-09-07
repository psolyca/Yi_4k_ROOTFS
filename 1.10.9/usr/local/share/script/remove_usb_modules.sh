#!/bin/sh
#
# Remove USB modules in S2 IPCAM...
#

kernel_ver=$(uname -r)

#Remove USB module

if [ -r /lib/modules/$kernel_ver/kernel/drivers/usb/gadget/libcomposite.ko ]; then
        rmmod libcomposite
fi
if [ -r /lib/modules/$kernel_ver/kernel/fs/configfs/configfs.ko ]; then
        rmmod configfs
fi
if [ -r /lib/modules/$kernel_ver/kernel/drivers/usb/gadget/ambarella_udc.ko ]; then
        rmmod ambarella_udc
fi
if [ -r /lib/modules/$kernel_ver/kernel/drivers/usb/gadget/udc-core.ko ]; then
        rmmod udc-core
fi
if [ -r /lib/modules/$kernel_ver/kernel/drivers/usb/host/ohci-hcd.ko ]; then
        rmmod ohci-hcd
fi
if [ -r /lib/modules/$kernel_ver/kernel/drivers/usb/host/ehci-hcd.ko ]; then
        rmmod ehci-hcd
fi
if [ -r /lib/modules/$kernel_ver/kernel/drivers/usb/core/usbcore.ko ]; then
        rmmod usbcore
fi
if [ -r /lib/modules/$kernel_ver/kernel/drivers/usb/usb-common.ko ]; then
        rmmod usb-common
fi