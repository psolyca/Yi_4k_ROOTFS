#!/bin/sh
echo "send to rtos" ${1}
if [ -x /usr/bin/SendToRTOS ]; then
    /usr/bin/SendToRTOS rtmp ${1}
fi
