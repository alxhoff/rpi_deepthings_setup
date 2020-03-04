#!/bin/bash

if [ "$EUID" -ne 0 ]
	then echo "Please run as root"
	exit
fi

dd if=$1 of=$2 bs=4M conv=fsync
wait

mkdir -p /run/media/$USER/sd/boot
mkdir -p /run/media/$USER/sd/root

mount $21 /run/media/$USER/sd/boot
mount $22 /run/media/$USER/sd/root

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cp $DIR/rc.local /run/media/$USER/sd/root/etc/

umount /run/media/$USER/sd/boot
umount /run/media/$USER/sd/root
