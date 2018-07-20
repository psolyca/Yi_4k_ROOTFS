#########################################################################
# File Name: copy_bt_conf.sh
# Author: Apple wang
# mail: wang.baoqi@xiaoyi.com
# Created Time: Sun 26 Jun 2016 10:23:55 AM CST
#########################################################################
#!/bin/sh
if [ -e /tmp/bt_hh_devices.xml ]; then
    cp /tmp/bt_hh_devices.xml /tmp/FL0/pref/
fi
if [ -e /tmp/bt_devices.xml ]; then
    cp /tmp/bt_devices.xml /tmp/FL0/pref/
fi
if [ -e /tmp/bt_config.xml ]; then
    cp /tmp/bt_config.xml /tmp/FL0/pref/
fi
if [ -e /tmp/bt_ble_client_devices.xml ]; then
    cp /tmp/bt_ble_client_devices.xml /tmp/FL0/pref/
fi

