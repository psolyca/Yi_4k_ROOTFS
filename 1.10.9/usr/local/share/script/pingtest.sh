#########################################################################
# File Name: ambalink_sdk_3_10/pkg/network_turnkey/source/usr/local/share/script/pingtest.sh
# Author: Apple wang
# mail: wang.baoqi@xiaoyi.com
# Created Time: Wed 04 May 2016 10:31:29 AM CST
#########################################################################
#!/bin/sh
result=`ping 8.8.8.8 -c 1`
tmp=`echo "$result" | grep "loss"`
if [ "$tmp" != " " ]; then 
    var1=`echo "$tmp" | awk -F"," '{print $2}'`
    var=`echo "$var1" | awk -F" " '{print $1}'`
    if [ $var -eq 1 ]; then
	    if [ -x /usr/bin/SendToRTOS ]; then
		    /usr/bin/SendToRTOS rtmp 5
        fi
    else
	    if [ -x /usr/bin/SendToRTOS ]; then
		     /usr/bin/SendToRTOS rtmp 6
        fi

    fi
else
    echo "fail"
	if [ -x /usr/bin/SendToRTOS ]; then
		 /usr/bin/SendToRTOS rtmp 6
    fi
fi
