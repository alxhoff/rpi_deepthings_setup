#!/bin/bash

CUR_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
CONNECTED_NODES=($(bash $CUR_DIR/get_nodes.sh))

BUILD_OPTIONS=""

build_cluster(){
    for NODE in "${CONNECTED_NODES[@]}"
    do
        pushd /home/pi/DeepThings
        make clean_all
        make $BUILD_OPTIONS
    done
}

while [[ $# -gt 0 ]]
    do
    key="$1"

    case $key in
        -s)
            BUILD_OPTIONS="${BUILD_OPTIONS} -DSKIP_FUSING"
            shift
            ;;
        -m)
            shift
            BUILD_OPTIONS="${BUILD_OPTIONS} -DMAX_DEVS=$1"
            shift
            ;;
        *)
            echo "error"
            exit 1
    esac
done
