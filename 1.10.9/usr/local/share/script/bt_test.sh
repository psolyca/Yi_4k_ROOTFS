#!/bin/sh
killall bsa_server
killall brcm_patchram_plus
sleep 1
source /usr/local/share/script/t_gpio.sh 12 0
sleep 0.2
source /usr/local/share/script/t_gpio.sh 12 1
sleep 0.2
brcm_patchram_plus --enable_hci --baudrate 115200 --use_baudrate_for_download --patchram /usr/local/bcmdhd/bt.hcd --no2bytes --enable_lpm /dev/ttyS1 --bd_addr `cat /tmp/wifi1_mac`
/usr/bin/SendToRTOS photo
