#!/bin/bash

if [ "$EUID" -ne 0 ]
	then echo "Please run as root"
	exit
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


