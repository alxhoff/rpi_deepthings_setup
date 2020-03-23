#!/bin/bash


if [ "$EUID" -ne 0 ]
	then echo "Please run as root"
	exit
fi

CUR_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
CONNECTED_NODES=($(bash $CUR_DIR/../get_nodes.sh eth0))

echo "Nodes found: ${CONNECTED_NODES[*]}"

for NODE in "${CONNECTED_NODES[@]}"
do
    echo "Restarting $NODE"
    bash $CUR_DIR/../ssh_command.sh $NODE 'sudo reboot'
done

reboot
