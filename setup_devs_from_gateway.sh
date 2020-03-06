#!/bin/bash

CUR_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
CONNECTED_NODES=($(bash $CUR_DIR/get_nodes.sh))

for NODE in "${CONNECTED_NODES[@]}"
do
	echo Setting up $NODE
	expect -c 'spawn ssh pi@$NODE "ls ~/"; expect "assword:"; send "password\r"; interact'
done
