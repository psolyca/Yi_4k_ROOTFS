#############################################
# File Name: save_bt_log.sh
# Created Time: Fri 02 Sep 2016 02:21:06 PM CST
# Author: ZhangNan
#############################################
#!/bin/bash

BT_LOG_FILE="/tmp/SD0/bt.log"

if [ $# -eq 0]; then
    echo "nothing to be called....exit"
    exit 1;
fi

echo -e "\n\n\n=================================================================" | tee -a $BT_LOG_FILE
echo Call_Time:  `date` | tee -a $BT_LOG_FILE
echo Call_Script:  $@ | tee -a $BT_LOG_FILE
echo -e "=================================================================" | tee -a $BT_LOG_FILE

source $@ | tee -a $BT_LOG_FILE

if [ $? -eq 0 ]; then
    echo -e "\n----------------------------call result ok-----------------------" | tee -a $BT_LOG_FILE
else
    echo -e "\n----------------------------call result error--------------------" | tee -a $BT_LOG_FILE
fi
