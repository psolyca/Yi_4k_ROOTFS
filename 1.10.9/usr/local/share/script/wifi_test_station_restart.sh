#!/bin/sh

export WIFI_TEST_STATION_PATH_SYSTEM=/usr/local/share/script

if [ -e ${WIFI_TEST_STATION_PATH_SYSTEM}/wifi_stop.sh ]; then
    echo "[TEST STATION] Stop Wi-Fi from system ..."
    ${WIFI_TEST_STATION_PATH_SYSTEM}/wifi_stop.sh $@
fi

if [ -e ${WIFI_TEST_STATION_PATH_SYSTEM}/wifi_test_station_start.sh ]; then
    echo "[TEST STATION] Start Wi-Fi from system ..."
    ${WIFI_TEST_STATION_PATH_SYSTEM}/wifi_test_station_start.sh $@
fi
