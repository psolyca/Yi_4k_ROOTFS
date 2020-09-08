#!/bin/sh

CONFIGURE_PATH="/tmp/wifi.conf"

if [ ! -e ${CONFIGURE_PATH} ]; then
    echo "Load wifi.conf from system ..."
    cp -rf /usr/local/share/script/wifi.conf ${CONFIGURE_PATH}
fi

# Values are
# AP_CHANNEL_5G=1; can be set in the menu
# AP_SSID=YDXJ_0779251_5G; hardcoded value should be changed
# AP_PASSWD=1234567890; hardcoded value should be changed
# AP_COUNTRY=FR; can be set in the menu
# WIFI_MAC=58:70:C6:00:00:00; hardcoded value should not be changed
# WIFI_MODE=sta; can be set in the menu
# CHIP_TYPE=43340; hardcoded value should not be changed
for i in $@
do
    param=${i%=*}
    value=${i#*=}
    echo "SET Wi-Fi Config > ${param}=${value}"
    sed -i 's/^'${param}='.*$/'$i'/g' ${CONFIGURE_PATH}
done

