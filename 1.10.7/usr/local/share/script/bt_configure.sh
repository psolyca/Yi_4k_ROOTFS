#!/bin/sh

XMLPATH=/tmp/ble_rc_devices.xml
cp /usr/local/share/script/ble_rc_devices.xml /tmp/

for i in $@
do
    param=${i%=*}
    value=${i#*=}
    echo "SET BT Config > ${param}=${value}"
    sed -i 's/<'${param}'>.*<\/'${param}'>/<'${param}'>'$value'<\/'$param'>/g' $XMLPATH
done


