#!/bin/sh

CONFIGURE_PATH="/tmp/wifi.conf"

if [ ! -e ${CONFIGURE_PATH} ]; then
    echo "Load wifi.conf from system ..."
    cp -rf /usr/local/share/script/wifi.conf ${CONFIGURE_PATH}
fi

for i in $@
do
    param=${i%=*}
    value=${i#*=}
    echo "SET Wi-Fi Config > ${param}=${value}"
    sed -i 's/^'${param}='.*$/'$i'/g' ${CONFIGURE_PATH}
done

