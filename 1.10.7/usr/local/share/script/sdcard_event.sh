#!/bin/sh

if [ "${1}" == "insert" ]; then
    if [ ! -e /tmp/fuse_d/DCIM ]; then
        mkdir -p /tmp/fuse_d/DCIM
    fi

    mount --bind /tmp/fuse_d/DCIM /var/www/DCIM

elif [ "${1}" == "remove" ]; then

    mount --move /tmp/fuse_d/DCIM /var/www/DCIM

fi
