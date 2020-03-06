#!/bin/bash

print_usage()
{
    echo "Usage : $0 [-e -n -m -l (-c)]"
    echo ""
    echo "  -e                  Total edge number"
    echo "  -n                  FTP dimension N"
    echo "  -m                  FTP dimension M"
    echo "  -l                  Number of fused layers"
    echo "  (-c)                .conf file to be used for test architecture "
    exit 0
}

automatic_run()
{
    echo "Automatic run!"

    #Current device is set as gateway

    #Host dev is connected to wlan0

    #All other devs on eth0 are edge devices
}

key="$1"
while [[ $# -gt 0 ]]
    do
    key="$1"

    case $key in

    -h|--help )
        print_usage
        shift
        ;;
    -e ) shift
        TOTAL_EDGE=$1
        shift
        ;;
    -n ) shift
        FTP_N=$1
        shift
        ;;
    -m ) shift
        FTP_M=$1
        shift
        ;;
    -l ) shift
        LAYERS=$1
        shift
        ;;
    -c ) shift
        CONF_FILE=$1
        shift
        ;;
    * )
        echo "Invalid option: $key" 1>&2
        exit 1
        ;;
    esac
done

if [ -z "$TOTAL_EDGE" ] || [ -z "$FTP_N" ] || [ -z "$FTP_M" ] || [ -z "$LAYERS" ]; then
    echo "Not all required options given, see --help for usage"
    exit 1
else
    echo "Running with $TOTAL_EDGE edge device, $FTP_N x $FTP_M FTP dimensions and $LAYERS layers"
fi

if ! test -z "$CONF_FILE"
then

    if ! test -f "$CONF_FILE"; then
        echo "Conf file doesn't exist"
        exit 1
    fi

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
else
    automatic_run
fi
