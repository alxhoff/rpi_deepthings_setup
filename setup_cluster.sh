#!/bin/bash

if [ "$EUID" -ne 0 ]
	then echo "Please run as root"
	exit
fi

PKG_OK=$(dpkg-query -W --showformat='${Status}\n' sshpass|grep "install ok installed")
if [ "" == "$PKG_OK" ]; then
	    sudo apt-get install -y sshpass
fi

CUR_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
CONNECTED_NODES=($(bash $CUR_DIR/get_nodes.sh eth0))

echo "Nodes found: ${CONNECTED_NODES[*]}"

setup_dev() {
	bash $CUR_DIR/ssh_command.sh $1 'sudo rm -rf ~/*'
    wait
    bash $CUR_DIR/ssh_command.sh $1 'wget https://raw.githubusercontent.com/alxhoff/rpi_deepthings_setup/master/setup_deepthings.sh &>/dev/null'
    wait
    bash $CUR_DIR/ssh_command.sh $1 'sudo chmod +x setup_deepthings.sh'
    wait
    bash $CUR_DIR/ssh_command.sh $1 'sudo ./setup_deepthings.sh &>/dev/null &'
    wait
}

for NODE in "${CONNECTED_NODES[@]}"
do
    echo Setting up $NODE
    setup_dev $NODE &
done

./setup_deepthings.sh ../ &
wait

# Get demo
while [ ! -d /home/pi/DeepThings/models ]
do
    sleep 1
done

if [ ! -f /home/pi/DeepThings/models/yolo.cfg ]; then
wget -O /home/pi/DeepThings/models/yolo.cfg https://raw.githubusercontent.com/zoranzhao/DeepThings/master/models/yolo.cfg
fi

if [ ! -f /home/pi/DeepThings/models/yolov2.weights ]; then
wget -O /home/pi/DeepThings/models/yolo.weights https://pjreddie.com/media/files/yolov2.weights
fi

for NODE in "${CONNECTED_NODES[@]}"
do
    echo $NODE
    while [[ ! $(sudo bash $CUR_DIR/ssh_command.sh $NODE 'ls /home/pi | grep done') ]]; do
        sleep 1
    done
    sshpass -p "raspberry" sudo scp -r /home/pi/DeepThings/models pi@$NODE:/home/pi/DeepThings/
done

exit 0
