#!/bin/sh
killall iperf
/usr/bin/iperf -c $1 -t 10 -i 1
