#!/bin/sh

i=0

while [ 1 ];
do
	killall iperf
	/usr/bin/iperf -s &

	sleep 1

	p=`ps | grep 'iperf -s' | grep -v grep`

	if [ ! -z "${p}" ]; then
		echo "IPERF_S_STARTED"
		SendToRTOS iperf 1
		break
	else
		i=`expr $i + 1`
	fi

	if [ $i -gt 3 ]; then
		echo "IPERF_S_FAILED"
		SendToRTOS iperf 0
		break;
	fi
done
