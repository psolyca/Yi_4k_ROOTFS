#!/bin/sh

WIFI_LOG_FILE="/tmp/SD0/wifi.log"
SCRIPT_PATH=/usr/local/share/script
CRON_PATH=/var/spool/cron/crontabs

RESTART()
{
	${SCRIPT_PATH}/wifi_stop.sh
	${SCRIPT_PATH}/wifi_start.sh
}

check ()
{
	# Signal level check
	# Signal should be over -67 dBm (-30 to -67)
	signal=`cat /proc/net/wireless | grep wlan0 | tr -s " " | cut -d " " -f 5 | cut -d "." -f 1`
	if [ $signal -lt -67 ]; then
		echo "Signal too low, restart wifi." | tee -a $WIFI_LOG_FILE
		RESTART
	fi

	wlan=`/sbin/ifconfig wlan0 | grep inet\ addr | wc -l`
	if [ $wlan -eq 0 ]; then
		echo "Connection lost, restart wifi." | tee -a $WIFI_LOG_FILE
		RESTART
	fi
}

start ()
{
	killall crond
	echo "* * * * * /bin/bash ${SCRIPT_PATH}/wifi_check.sh check" > /tmp/crontab
	/usr/bin/crontab /tmp/crontab
	sleep 0.5
	/usr/sbin/crond
}

stop ()
{
	if [ -e ${CRON_PATH}/root ]; then
		killall crond
		/usr/bin/crontab -r
		sleep 0.5
		/usr/sbin/crond
	fi
}

case "$1" in
	start)
		echo "Start wifi check"
		start
		;;
	stop)
		echo "Stop wifi check"
		stop
		;;
	check)
		echo "Check ethernet status"
		check
		;;
	*)
		echo "Usage $0 {start|stop|check}"
		exit 1
esac

exit $?