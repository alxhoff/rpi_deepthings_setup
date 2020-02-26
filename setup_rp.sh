#!/bin/bash

if [ "$EUID" -ne 0 ]
	then echo "Please run as root"
	exit
fi

echo "#### Getting prereqs ####"

echo Base prereqs
apt-get update --fix-missing
apt-get upgrade -y
apt-get install -y build-essential git python3-pip clang ninja-build

echo Python prereqs
ln -sf /usr/bin/python3.7 /usr/bin/python
pip install --upgrade git+https://github.com/Maratyszcza/PeachPy
pip install --upgrade git+https://github.com/Maratyszcza/confu

#Enable SSH
touch /boot/ssh

#Set MAC
ORIG_MAC_ADDR=$(cat /sys/class/net/eth0/address)

read -p 'New MAC address: ' NEW_MAC_ADDR

printf "Changing MAC address from $ORIG_MAC_ADDR to $NEW_MAC_ADDR"

if [ "$ORIG_MAC_ADDR" = "$NEW_MAC_ADDR" ]; then
	printf "....Already set\n"
else
	printf "\n"
	ip link set down dev eth0
	wait
	ip link set dev eth0 address $NEW_MAC_ADDR
	wait
	ip link set up dev eth0
	wait
fi

if ! [[ -f "/etc/systemd/network/00-mac.link" ]]; then
	echo Persistently changing MAC address

	echo "[Match]" > /etc/systemd/network/00-mac.link
	echo "MACAddress=$ORIG_MAC_ADDR" >> /etc/systemd/network/00-mac.link
	echo "[Link]" >> /etc/systemd/network/00-mac.link
	echo "MACAddress=$NEW_MAC_ADDR" >> /etc/systemd/network/00-mac.link
	echo "NamePolicy=kernel database onboard slot path" >> /etc/systemd/network/00-mac.link
	wait
fi

#Set up DeepThings
printf "Getting DeepThings"

if [[ -d "DeepThings" ]]; then
	printf "....Already exists\n"
else
	printf "\n"
	git clone https://gitlab.lrz.de/de-tum-ei-eda-esl/DeepThings.git
	wait
fi

cd DeepThings
git submodule init
git submodule update
cd darknet-nnpack
git clone https://github.com/thomaspark-pkj/NNPACK-darknet.git
cd NNPACK-darknet
confu setup
python ./configure.py --backend auto
ninja
cp -a lib/* /usr/lib/
cp include/nnpack.h /usr/include/
cp deps/pthreadpool/include/pthreadpool.h /usr/include/
cd ../../
make clean_all
make

#Get demo
wget -P models https://raw.githubusercontent.com/zoranzhao/DeepThings/master/models/yolo.cfg
wget -P models -O yolo.weights https://pjreddie.com/media/files/yolov2.weights


