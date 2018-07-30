#!/bin/sh
echo "get mac from rtos : ${1}"
echo "open buletooh bsa"
HDA=${1}
MOD=${2}

if [ "${HDA}" = "00:00:00:00:00:00" ] ||  [ "${HDA}" = "" ]; then
    # TODO: from ROM or random
    HDA=`printf "58:70:C6:%02X:%02X:%02X" $(($RANDOM % 256)) $(($RANDOM % 256)) $(($RANDOM % 256))`
    echo $HDA
fi

/usr/local/share/script/t_gpio.sh 12 0
sleep 0.1
/usr/local/share/script/t_gpio.sh 12 1
sleep 0.1

if [ "${MOD}" == "43455" ] && [ -e /usr/local/bcmdhd/bt43455.hcd ]; then
    /usr/local/share/script/bsa_server_43455 -r 12 -d /dev/ttyS1 -p /usr/local/bcmdhd/bt43455.hcd -u /tmp/fuse/ -all=0 &
elif [ -e /usr/local/bcmdhd/bt43340.hcd ]; then
    /usr/local/share/script/bsa_server_43340 -d /dev/ttyS1 -p /usr/local/bcmdhd/bt43340.hcd -u /tmp/fuse/ -all=0 &
else
    /usr/local/share/script/bsa_server_43340 -d /dev/ttyS1 -p /usr/local/bcmdhd/bt.hcd -u /tmp/fuse/ -all=0 &
fi

sleep 4

if [ -e /tmp/SD0/factory/btr_mac ]; then
    mac=`cat /tmp/SD0/factory/btr_mac`
    /usr/local/share/script/ble_remote --addr $HDA --multi $mac &
else
    /usr/local/share/script/ble_remote --addr $HDA &
fi

