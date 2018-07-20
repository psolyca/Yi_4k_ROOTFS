#!/bin/sh

if [ -e /tmp/rtmp_info.conf ]; then
/usr/local/share/script/sendtortos.sh 1
/usr/local/share/script/start_rtmp.sh
else
echo "can't find rtmp_info.conf!"
/usr/local/share/script/sendtortos.sh 2
fi

