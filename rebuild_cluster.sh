#!/bin/bash

if [ "$EUID" -ne 0 ]
	then echo "Please run as root"
	exit
fi

CUR_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
CONNECTED_NODES=($(bash $CUR_DIR/get_nodes.sh eth0))

BUILD_OPTIONS=""

build_cluster(){
    for NODE in "${CONNECTED_NODES[@]}"
    do
	echo "Started build on $NODE with build options '$BUILD_OPTIONS'"
        bash $CUR_DIR/ssh_command.sh $NODE "make -C /home/pi/DeepThings clean_all &> /dev/null" 
        wait
        bash $CUR_DIR/ssh_command.sh $NODE "make -C /home/pi/DeepThings $BUILD_OPTIONS &> /dev/null &" 
    done

    make -C /home/pi/DeepThings clean_all &> /dev/null
    make -C /home/pi/DeepThings $BUILD_OPTIONS &> /dev/null
}

while [[ $# -gt 0 ]]
    do
    key="$1"

    case $key in
        -s)
            BUILD_OPTIONS="${BUILD_OPTIONS} SKIP_FUSING=1"
            shift
            ;;
        -m)
            shift
            BUILD_OPTIONS="${BUILD_OPTIONS} MAX_EDGE_NUM=$1"
            shift
            ;;
        *)
            echo "error"
            exit 1
    esac
done

build_cluster

echo "Cluster rebuilt"
