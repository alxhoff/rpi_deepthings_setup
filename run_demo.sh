#!/bin/bash

TOTAL_EDGE=0
FTP_N=0
FTP_M=0
LAYERS=0

while getopts ":he:t:n:m:l:" opt; do

    case ${opt} in

    h )
        echo "Usage:"
        echo "  -e                  Total edge number"
        echo "  -n                  FTP dimension N"
        echo "  -m                  FTP dimension M"
        echo "  -l                  Number of fused layers"
        ;;

    \? )
        echo "Invalid option: -$OPTARG" 1>&2
        exit 1
        ;;

    e ) TOTAL_EDGE=$OPTARG
        ;;

    n ) FTP_N=$OPTARG
        ;;

    m ) FTP_M=$OPTARG
        ;;

    l ) LAYERS=$OPTARG
        ;;

    esac

done

shift $((OPTIND -1))

REGEX="(([H,G,E])([0-9]+)?([n,d]{1})?) (([0-9]+)\.([0-9]+)\.([0-9]+)\.([0-9]+))"

while read p; do
    if [[ $p =~ $REGEX ]]
    then
        DEV_TYPE="${BASH_REMATCH[2]}"
        DEV_IP="${BASH_REMATCH[5]}"

        case ${DEV_TYPE} in

        H )
            echo "Host device $DEV_IP"
            # ssh -n -f pi@$DEV_IP "sh -c 'cd /DeepThings; nohup ./deepthings -mode start > /dev/null 2>&1 &'"
            ;;

        G )
            echo "Gateway device $DEV_IP"
            # ssh -n -f pi@$DEV_IP "sh -c 'cd /DeepThings; nohup ./deepthings -mode gateway -total_edge $TOTAL_EDGE -n $FTP_N -m $FTP_M -l $LAYERS > /dev/null 2>&1 &'"
            ;;

        E )
            EDGE_DEV_NUM="${BASH_REMATCH[3]}"
            EDGE_DEV_MODE="${BASH_REMATCH[4]}"
            echo "Edge device $EDGE_DEV_NUM $DEV_IP"

            case ${EDGE_DEV_MODE} in

            d )
                echo "Data source"
                # ssh -n -f pi@$DEV_IP "sh -c 'cd /DeepThings; nohup ./deepthings -mode data_source -edge_id $EDGE_DEV_NUM -n $FTP_N -m $FTP_M -l $LAYERS > /dev/null 2>&1 &'"
                ;;

            n )
                echo "Non-data source"
                # ssh -n -f pi@$DEV_IP "sh -c 'cd /DeepThings; nohup ./deepthings -mode non_data_source -edge_id $EDGE_DEV_NUM -n $FTP_N -m $FTP_M -l $LAYERS > /dev/null 2>&1 &'"
                ;;

            esac

            ;;

        esac
    fi
done < devices.conf
