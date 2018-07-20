#!/bin/sh

killall bsa_start.sh

if [ $? -ne 0 ]; then
       killall bsa_start.sh
fi

killall bsa_server

if [ $? -ne 0 ]; then
       killall bsa_server

fi


