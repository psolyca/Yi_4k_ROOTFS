#!/bin/sh

DEFAULT_WIFI_CONF="${WIFI_TEST_STATION_PATH_SYSTEM}/wifi_test_station.conf"
TARGET_WIFI_CONF="/tmp/wifi_test_station.conf"

if [ ! -e ${TARGET_WIFI_CONF} ]; then
    rm -rf ${TARGET_WIFI_CONF}
fi

cp -rf ${DEFAULT_WIFI_CONF} ${TARGET_WIFI_CONF}

for i in $@
do
    param=${i%=*}
    value=${i#*=}
    echo "SET Wi-Fi Config > ${param}=${value}"
    sed -i 's/^'${param}='.*$/'$i'/g' ${TARGET_WIFI_CONF}
done

