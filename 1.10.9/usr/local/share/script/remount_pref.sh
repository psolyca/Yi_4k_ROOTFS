#!/bin/sh

umount /pref
if [ ! -d /tmp/FL0/pref ]; then
    mkdir -p /tmp/FL0/pref
fi
mount --bind /tmp/FL0/pref /pref
