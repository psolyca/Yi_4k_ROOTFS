#############################################
# File Name: save_wifi_log.sh
# Created Time: Fri 02 Sep 2016 02:21:06 PM CST
# Author: ZhangNan
#############################################
#!/bin/bash

WIFI_LOG_FILE="/tmp/SD0/wifi.log"

if [ $# -eq 0]; then
    echo "nothing to be called....exit"
    exit 1;
fi

echo -e "\n\n\n=================================================================" | tee -a $WIFI_LOG_FILE
echo Firmware version: [sed] | tee -a $WIFI_LOG_FILE
echo Call_Time:  `date` | tee -a $WIFI_LOG_FILE
echo Call_Script:  $@ | tee -a $WIFI_LOG_FILE
echo -e "=================================================================" | tee -a $WIFI_LOG_FILE

source $@ | tee -a $WIFI_LOG_FILE

if [ $? -eq 0 ]; then
    echo -e "\n----------------------------call result ok-----------------------" | tee -a $WIFI_LOG_FILE
else
    echo -e "\n----------------------------call result error--------------------" | tee -a $WIFI_LOG_FILE
fi
