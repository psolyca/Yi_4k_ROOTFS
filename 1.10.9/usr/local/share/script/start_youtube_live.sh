#!/bin/sh
RTMPINFO=/tmp/rtmp_info.conf
if [ -e $RTMPINFO ]; then
    export URL=`cat $RTMPINFO | grep '<rtmpurl>' | awk -F'<rtmpurl>' '{ print $2 }' | awk -F'</rtmpurl>' '{ print $1 }'`
	export NAME=`cat $RTMPINFO | grep '<name>' | awk -F'<name>' '{ print $2 }' | awk -F'</name>' '{ print $1 }'`
	export RESOLUTION=`cat $RTMPINFO | grep '<resolution>' | awk -F'<resolution>' '{ print $2 }' | awk -F'</resolution>' '{ print $1 }'`
	export RATE=`cat $RTMPINFO | grep '<rate>' | awk -F'<rate>' '{ print $2 }' | awk -F'</rate>' '{ print $1 }'`
	export RTMPCMD="rtmpcmd://?resolution=$RESOLUTION&rate=$RATE&"
fi
/usr/bin/youtube_live  "${URL}" "${RTMPCMD}" &
