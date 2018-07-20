#!/bin/sh

if [ $# -lt 2 ]; then
	echo "Usage: ./cmd patternFile logFile"
	echo ""
	exit
fi

if [ ! -e $1 ]; then
	echo "pattern file $1 is not exist!!"
	echo ""
	exit
fi

if [ ! -e $2 ]; then
	echo "log file $1 is not exist!!"
	echo ""
	exit
fi


# get patterns
i=0
flag=1
while read LINE
do
	#lp[$i]="${LINE}"
	#i=$(($i+1))

	grep -q "${LINE}" $2
	if [ $? -eq 0 ]; then
		echo "  Match!"
		flag=0
		break
	else
		echo "  Miss"
		#/usr/bin/SendToRTOS 1
	fi
done < $1

/usr/bin/SendToRTOS burnin ${flag}
