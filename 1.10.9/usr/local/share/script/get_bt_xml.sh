#!/bin/sh
read_bt_xml_info()
{
    BTINFO=/tmp/ble_rc_devices.xml
    if [ -e $BTINFO ]; then
        export NAME=`cat $BTINFO | grep '<name>' | awk -F'<name>' '{ print $2 }' | awk -F'</name>' '{ print $1 }'`
        export TYPE=`cat $BTINFO | grep '<type>' | awk -F'<type>' '{ print $2 }' | awk -F'</type>' '{ print $1 }'`
        export ADDR=`cat $BTINFO | grep '<addr>' | awk -F'<addr>' '{ print $2 }' | awk -F'</addr>' '{ print $1 }'`
    fi
}

read_bt_xml_info
if [ -x /usr/bin/SendToRTOS ]; then
    /usr/bin/SendToRTOS bt_info $TYPE $ADDR $NAME
fi
