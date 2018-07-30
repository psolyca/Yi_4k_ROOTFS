#!/bin/sh

if [ -x /usr/bin/SendToRTOS ]; then
    if [ $# -eq 2 ]; then
        echo "chip detected: ${1} ${2}"
        if [[ "${1:0:4}" == "4334" ]]; then
            echo "${1} ${2}" > /tmp/module.43340
        else
            echo "${1} ${2}" > /tmp/module.43455
        fi
        /usr/bin/SendToRTOS module ${1} ${2} &
    else
        echo "chip detected: unknown"
        echo "unknown" > /tmp/module.43340
        /usr/bin/SendToRTOS module &
    fi
fi

exit 0
