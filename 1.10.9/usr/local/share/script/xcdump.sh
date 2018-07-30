#!/bin/sh

SEED_MIN=0
SEED_MAX=9999

if [ ! $# -eq 3 ]; then
    echo "Invalid parameters: $#"
    exit 0
fi

if [ ! -d ${1} ]; then
    echo "XCar no logs now ..."
    exit 0
fi

if [ -d ${2} ]; then
    while [ ${SEED_MIN} -lt ${SEED_MAX} ]; do
        if [ ! -d ${3}${SEED_MIN}/ ]; then
            mkdir -p  ${3}${SEED_MIN}/
            cp    -rf ${2} ${3}${SEED_MIN}/
            echo "XCar backup old logs: ${1} -> ${3}${SEED_MIN}/"
            break
        fi
        SEED_MIN=$((${SEED_MIN} + 1))
    done
    rm -rf ${2}
fi

echo "XCar dump new logs: ${1} -> ${2}"
cp -rf ${1} ${2}
rm -rf ${1}
