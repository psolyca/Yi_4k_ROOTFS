#!/bin/bash

#make_rootfs -- simple script to handle permission of special files
#In git, users and permissions are not preserved so all files have the owner of
# the git owner.
#But the root filesystem must be owned by root user and special files in /dev
# should have correct permssions
#
#For testing purpose, unsquash then squash the file system do not give the same
# hash result.

if [ $# -ne 2 ]
then
   echo "Usage: $0 <folder to squash> <name of squash file>"
   exit
fi

if ! [ -z "$1" ]
then 
    #Change permission before squashing the file system
    sudo chown -R root:root $1
    sudo chmod 0622 $1/dev/console
    sudo chmod 0666 $1/dev/null
    #Squashing the file system
    if ! [ -z "$2" ]
    then
        sudo mksquashfs $1 $2  -comp lzo -no-xattrs 
    fi
    #Change permission back to normal
    user=$(id | sed 's/^uid=[0-9]*(//;s/).*$//')
    group=$(id | sed 's/.*gid=[0-9]*(//;s/).*$//')
    sudo chown -R ${user}:${group} $1
fi
