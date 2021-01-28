#!/bin/bash

#build.sh -- simple script to create a squashed file from a root filesystem and a firmware.
#
#With git, users and permissions are not preserved.
#But the squashed filesystem must be owned by root user.
#2 character devices should be created, permissions are given during camera boot by
# makedev.
#
#To be able to build a firmware, an original one should have been unpacked with amba_fwpack_yi.py
# see https://github.com/psolyca/Xiaomi_Yi_4k_Camera.git
#The squashed file should replace the original one (_part_rfs.a9s).
#
#For information, unsquash then squash the file system do not give the same hash result.

rootfs=""
sqhfile=""
fwfile=""
fwbuild=1

blue="\e[38;5;26m"
red="\e[38;5;196m"
yellow="\e[38;5;226m"
normal="\e[0m"

exe() { echo -e "$yellow \$ ${@/eval/} $normal" ; "$@" ; }

function usage()
{
	printf "Usage: $0 -r folder -s file [-f firmware] [-o oldversion -n newversion] [-l strversion]\n"
	printf "\t-r folder to squash, usually 1.10.9\n"
	printf "\t-s name and path of the original squashed file, usually _part_rfs.a9s\n"
	printf "\t   if you are building a firmware with -f,\n"
	printf "\t   point to the path of the unpacked firmware with all *.a9s files.\n"
	printf "\t-f name of the custom firmware\n"
	printf "\t   if a name is given here, the firmware will also be built.\n"
	printf "\t   This option need also all parts of the firmware in the same place.\n"
	printf "\t   By default, the path to reach those parts will be the same as the squashed file path (-s).\n"
	printf "\t   To be able to build the firmware, python3 is needed.\n"
	printf "\t-o version of the original firmware, usually 1.10.9.\n"
	printf "\t   This option must be used in conjonction of the -n option.\n"
	printf "\t-n version of the custom firmware.\n"
	printf "\t-l string added to -n for logging purpose.\n"
}

while getopts "r:s:f:o:n:l:" opt; do
	case "$opt" in
		h|help)
			usage
			exit 0
			;;
		r) 
			rootfs=$OPTARG
			;;
		s)
			sqhfile="$(cd "$(dirname "$OPTARG")"; pwd)"/$(basename "$OPTARG")
			;;
		f)
			fwfile=$OPTARG
			;;
		o)
			oldversion=$OPTARG
			;;
		n)
			newversion=$OPTARG
			;;
		l)
			strversion=$OPTARG
			;;
		*)
			usage
			exit 0
			;;
	esac
done

if [ $OPTIND -eq 1 ];then
	usage
	exit 0
fi
shift $((OPTIND-1))

if [ -n "$rootfs" ]; then
	printf "$blue Changing permission to root...$normal\n"
	sudo chown -R root:root $rootfs
	if ! [ -e $rootfs/dev/console ]; then
		printf "$blue Creating $rootfs/dev/console\n"
		sudo mknod $rootfs/dev/console c  5 1
	fi
	if ! [ -e $rootfs/dev/null ]; then
		printf "$blue Creating $rootfs/dev/null\n"
		sudo mknod $rootfs/dev/null c 1 3
	fi
	printf "$blue Creating different empty folder\n"
	pushd $rootfs > /dev/null
	exe eval sudo mkdir -p dev/pts etc/{dbus-1/session.d,ld.so.conf.d}
	exe eval sudo mkdir -p etc/network/{if-down.d,if-post-down.d,if-post-up.d,if-pre-down.d,if-pre-up.d,if-up.d}
	exe eval sudo mkdir -p home/{default,ftp} media mnt opt pref proc sys
	exe eval sudo mkdir -p run/dbus tmp/dbus
	exe eval sudo mkdir -p usr/{lib/{gio/modules,python2.7/config},lib32/{gio/modules,python2.7/config}}
	exe eval sudo mkdir -p usr/share/{dbus-1/{services,system-services},locale,udhcpc/default.script.d}
	exe eval sudo mkdir -p var/{cache/dbus,lib/{misc/dbus,pcmcia/dbus},lock/dbus,log/dbus,pcmcia/dbus,run/dbus,spool/{dbus,cron/crontabs},tmp/dbus}
	exe eval sudo mkdir -p var/www/{DCIM,live,mjpeg,pref,shutter}
	popd > /dev/null
	printf "$blue Copying files from submodules\n"
	exe eval sudo mkdir -p $rootfs/usr/lib/python2.7/site-packages/Yi4kAPI/
	exe eval sudo cp cmdYi/src/Yi4kAPI/__init__.py $rootfs/usr/lib/python2.7/site-packages/Yi4kAPI/
	exe eval sudo cp cmdYi/src/Yi4kAPI/yiAPI.py $rootfs/usr/lib/python2.7/site-packages/Yi4kAPI/
	exe eval sudo cp cmdYi/src/Yi4kAPI/yiAPICommand.py $rootfs/usr/lib/python2.7/site-packages/Yi4kAPI/
	exe eval sudo cp cmdYi/src/Yi4kAPI/yiAPIListener.py $rootfs/usr/lib/python2.7/site-packages/Yi4kAPI/
	exe eval sudo cp cmdYi/src/cmdyi.py $rootfs/usr/local/share/script/
	exe eval sudo chmod +x $rootfs/usr/local/share/script/cmdyi.py
	if [[ -n "$strversion" ]]; then
		printf "$blue Added $newversion-$strversion to save_wifi_log.sh\n"
		exe eval sudo sed -i "s/\\\[sed\\\]/\\\[$newversion-$strversion\\\]/g" $rootfs/usr/local/share/script/save_wifi_log.sh
	fi
	if [ -z "$sqhfile" ]; then
		printf "$red Squashing with a default name _part_rfs.a9s in current path.\n"
		printf "Building the firmware will not be allowed.$normal\n"
		sqhfile=$(pwd)"/_part_rfs.a9s"
		fwbuild=0
	fi
	if [ -e "$sqhfile" ]; then
		printf "$blue Removing previous $sqhfile.$normal\n"
		sudo rm $sqhfile
	fi
	printf "$blue Squashing the file system...$normal\n"
	exe eval sudo mksquashfs $rootfs $sqhfile  -comp lzo -no-xattrs
	printf "$blue Changing permission back to normal.$normal\n"
	user=$(id | sed 's/^uid=[0-9]*(//;s/).*$//')
	group=$(id | sed 's/.*gid=[0-9]*(//;s/).*$//')
	sudo chown -R ${user}:${group} $rootfs
	printf "$blue To not mess with git, all submodules files are deleted from rootfs\n"
	exe eval sudo rm -fr $rootfs/usr/lib/python2.7/site-packages/Yi4kAPI
	exe eval sudo rm $rootfs/usr/local/share/script/cmdyi.py
	printf "$blue Hard resetting to HEAD.\n"
	exe eval sudo git reset --hard HEAD
else
	printf "$red No folder to squash.$normal\n"
fi

if [ -n "$fwfile" ] && [ $fwbuild -eq 1 ]; then
	if ! [ -d "../Xiaomi_Yi_4k_Camera" ]; then
		printf "$red This script requires amba_fwpak_yi.py in a folder in the same level.\n"
		printf "Get it from https://github.com/psolyca/Xiaomi_Yi_4k_Camera.git\n"
		printf "clone to upper level folder, '../Xiaomi_Yi_4k_Camera'\n"
		printf "and checkout unpacker branch.$normal\n"
		exit 0
	else
		py=$(python3 -V 2>&1)
		if [[ $py =~ .*"command not found".* ]]; then
			printf "$red Python3 is not installed.$normal\n"
			exit 0
		else
			fwpartpath=$(dirname "$sqhfile")
			fwpartbase=$(basename "$fwpartpath")
			fwpath=$(dirname "$fwpartpath")
			if [[ -n $oldversion ]]; then
				if [[ -n $newversion ]]; then
					printf "$blue Custom firmware from version $oldversion to $newversion.$normal\n"
					exe eval cp $fwpartpath/_part_lrtos.a9s $fwpartpath/_part_lrtos.bak
					offset=$((`strings -t d $fwpartpath/_part_lrtos.a9s | grep -F $oldversion | grep -v '_' | awk '{print $1}'`))
					len=$(expr length $newversion)
					echo $newversion | dd of=$fwpartpath/_part_lrtos.a9s bs=1 seek=$offset count=$len conv=notrunc
				else
					printf "$red An old version number is given but not a new one. No customization of the version number.$normal\n"
				fi
			else
				printf "$red No old version number given. No customization of the version number.$normal\n"
			fi
			if [ -e "$fwpartpath/_header.a9h" ]; then
				exe eval python3 ../Xiaomi_Yi_4k_Camera/firmware_unpacker/amba_fwpak_yi.py -vvv -p -f $fwpath/$fwfile -d $fwpartbase
				exe eval cp $fwpartpath/_part_lrtos.bak $fwpartpath/_part_lrtos.a9s
			else
				printf "$red The folder $fwpartpath does not contain valid firmware parts.$normal\n"
				exit 0
			fi
		fi
	fi
fi
