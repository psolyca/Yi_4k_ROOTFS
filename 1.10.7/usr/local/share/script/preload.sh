#!/bin/sh

# Needed for P2P.
modprobe cfg80211 ieee80211_regdom="US"

/usr/local/share/script/wifi_softmac.sh

# Needed for load.sh
touch /tmp/wifi.preloaded

