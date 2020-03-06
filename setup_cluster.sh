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
CONNECTED_NODES=($(bash $CUR_DIR/get_nodes.sh))

echo "Nodes found: ${CONNECTED_NODES[*]}"

setup_dev() {
	bash $CUR_DIR/ssh_command.sh $1 'sudo rm -rf ~/*'
 	bash $CUR_DIR/ssh_command.sh $1 'wget https://raw.githubusercontent.com/alxhoff/rpi_deepthings_setup/master/setup_deepthings.sh'
	bash $CUR_DIR/ssh_command.sh $1 'sudo chmod +x setup_deepthings.sh'
	# sshpass_command $1 'sudo ./setup_deepthings.sh'
}

./setup_deepthings.sh &

for NODE in "${CONNECTED_NODES[@]}"
do
	echo Setting up $NODE
	setup_dev $NODE &
done

exit 0
