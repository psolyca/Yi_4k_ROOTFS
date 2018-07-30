#!/bin/sh
if [ $# -eq 4 ] && [ "$*" == "03 00 00 00" ]; then
	SendToRTOS photo
elif [ $# -eq 9 ] && [ "$*" == "01 00 00 00 00 00 00 00 00" ]; then
	SendToRTOS record
fi
