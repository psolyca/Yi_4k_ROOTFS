#!/bin/sh
echo "${1}"
#/usr/local/share/script/ffmpeg_zbar.sh ${1}
rm /tmp/rtmp_info.conf
bar_code ${1}
rm ${1}
