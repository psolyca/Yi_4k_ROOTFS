#!/bin/sh

KO=bcmdhd
rmmod $KO

#rmmod cfg80211

rm -f /tmp/wifi.loaded
rm -f /tmp/wifi.preloaded

