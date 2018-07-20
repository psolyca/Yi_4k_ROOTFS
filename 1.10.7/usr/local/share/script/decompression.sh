#!/bin/sh
SendToRTOS_Handle()
{
	if [ -x /usr/bin/SendToRTOS ]; then
		if [ $1 = 0 ]; then
			/usr/bin/SendToRTOS dec_complite
		else
			/usr/bin/SendToRTOS dec_failed
		fi
	else
		echo "SendToRTOS could found"
	fi
}

zip_firmware=$1
if [ -f "$zip_firmware" ]; then
	/bin/gzip -d $zip_firmware
	firmware=${zip_firmware%.*}
	if [ -f "$firmware" ]; then
		echo "gunzip file success"
		SendToRTOS_Handle 0
	else
		echo "gunzip file failed"
		SendToRTOS_Handle 1

	fi
else
	SendToRTOS_Handle 1
fi

