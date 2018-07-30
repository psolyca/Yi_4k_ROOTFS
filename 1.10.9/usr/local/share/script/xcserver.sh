#!/bin/sh

if [ -e /tmp/fuse_d/XCServer ]; then
    echo "XCServer start from SD card ..."
    chmod +x /tmp/fuse_d/XCServer
    /tmp/fuse_d/XCServer &
elif [ -e /usr/bin/XCServer ]; then
    echo "XCServer start from system ..."
    /usr/bin/XCServer &
elif [ -e /usr/local/share/script/XCServer ]; then
    echo "XCServer start from local ..."
    /usr/local/share/script/XCServer &
else
    echo "XCServer can't find ..."
fi

