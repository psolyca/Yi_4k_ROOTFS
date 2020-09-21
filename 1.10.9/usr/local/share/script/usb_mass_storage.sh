#!/bin/sh
#
# Init S2 IPCAM...
#

if [ -f /etc/ambarella.conf ]; then
	. /etc/ambarella.conf
fi

start()
{
	kernel_ver=$(uname -r)

	echo host > /proc/ambarella/usbphy0

	/usr/local/share/script/insert_usb_module.sh start

	# The followings are for USB mass storage.
	if [ -r /lib/modules/$kernel_ver/kernel/drivers/scsi/scsi_mod.ko ]; then
		modprobe scsi_mod
	fi
	if [ -r /lib/modules/$kernel_ver/kernel/drivers/scsi/sd_mod.ko ]; then
		modprobe sd_mod
	fi
	if [ -r /lib/modules/$kernel_ver/kernel/drivers/usb/storage/usb-storage.ko ]; then
		modprobe usb-storage
	fi
}

stop()
{
	kernel_ver=$(uname -r)
	
	if [ -r /lib/modules/$kernel_ver/kernel/drivers/usb/storage/usb-storage.ko ]; then
		rmmod usb-storage
	fi
	if [ -r /lib/modules/$kernel_ver/kernel/drivers/scsi/sd_mod.ko ]; then
		rmmod sd_mod
	fi
	if [ -r /lib/modules/$kernel_ver/kernel/drivers/scsi/scsi_mod.ko ]; then
		rmmod scsi_mod
	fi
}

restart()
{
	stop
	start
}

case "$1" in
	start)
		start
		;;
	stop)
		stop
		;;
	restart|reload)
		restart
		;;
	*)
		echo "Usage: $0 {start|stop|restart}"
		exit 1
esac

exit $?

