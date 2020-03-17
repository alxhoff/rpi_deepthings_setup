#!/bin/bash

if [ "$EUID" -ne 0 ]
	then echo "Please run as root"
	exit
fi

if [ ! -z "$1" ]
then
	pushd $1
fi

echo "#### Getting prereqs ####"

echo Base prereqs
apt-get update --fix-missing
wait
sleep 2
apt-get upgrade -y
wait
sleep 2
apt-get install -y build-essential git python3-pip clang ninja-build vim
wait
sleep 2

echo Python prereqs
ln -sf /usr/bin/python3.7 /usr/bin/python
python -m pip install --upgrade git+https://github.com/Maratyszcza/PeachPy
wait
sleep 2
python -m pip install --upgrade git+https://github.com/Maratyszcza/confu
wait
sleep 2

#Set up DeepThings
printf "Getting DeepThings"

if [[ -d "DeepThings" ]]; then
	printf "....Already exists\n"
else
	printf "\n"
	git clone https://github.com/rafzi/DeepThings
	wait
fi

cd DeepThings
git submodule init
git submodule update
cd darknet-nnpack
if [ ! -d "NNPACK-darknet" ]; then
	git clone https://github.com/thomaspark-pkj/NNPACK-darknet.git
fi
cd NNPACK-darknet
confu setup
python ./configure.py --backend auto
ninja
cp -a lib/* /usr/lib/
cp include/nnpack.h /usr/include/
cp deps/pthreadpool/include/pthreadpool.h /usr/include/
cd ../../ #cd into DeepThings
make clean_all
make
chmod -R 777 /home/pi/DeepThings

if [ ! -z "$1" ]
then
	popd # home directory
fi

cd ..
touch done
