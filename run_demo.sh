#!/bin/bash
    
CUR_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

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
    GATEWAY_IP=$(ip addr show eth0 | grep "inet\b" | awk '{print $2}' | cut -d/ -f1)

    echo "Gateway: $GATEWAY_IP"

    #Host dev is connected to wlan0
    HOST_IP=($(bash $CUR_DIR/get_nodes.sh wlan0))

    echo "Host: $HOST_IP"

    #All other devs on eth0 are edge devices
    EDGE_NODE_IPS=($(bash $CUR_DIR/get_nodes.sh eth0))

    echo "Edge devs: ${EDGE_NODE_IPS[*]}"
}

start_host()
{
        # ssh -n -f pi@$DEV_IP "sh -c 'cd /DeepThings; nohup ./deepthings -mode start > /dev/null 2>&1 &'"
	bash $CUR_DIR/ssh_command.sh $1 "nohup ./DeepThings/deepthings -mode start > /dev/null 2>&1 &"
}

start_gateway()
{
        # ssh -n -f pi@$DEV_IP "sh -c 'cd /DeepThings; nohup ./deepthings -mode gateway -total_edge $TOTAL_EDGE -n $FTP_N -m $FTP_M -l $LAYERS > /dev/null 2>&1 &'"
	bash $CUR_DIR/ssh_command.sh $1 "nohup ./DeepThings/deepthings -mode gateway -total_edge $TOTAL_EDGE -n $FTP_N -m $FTP_M -l $LAYERS > /dev/null 2>&1 &"
}

start_data_edge()
{
        # ssh -n -f pi@$DEV_IP "sh -c 'cd /DeepThings; nohup ./deepthings -mode data_source -edge_id $EDGE_DEV_NUM -n $FTP_N -m $FTP_M -l $LAYERS > /dev/null 2>&1 &'"
	bash $CUR_DIR/ssh_command.sh $1 "nohup .DeepThings/deepthings -mode data_source -edge_id $2 -n $FTP_N -m $FTP_M -l $LAYERS > /dev/null 2>&1 &"
}

start_n_data_edge()
{
        # ssh -n -f pi@$DEV_IP "sh -c 'cd /DeepThings; nohup ./deepthings -mode non_data_source -edge_id $EDGE_DEV_NUM -n $FTP_N -m $FTP_M -l $LAYERS > /dev/null 2>&1 &'"
	bash $CUR_DIR/ssh_command.sh $1 "nohup .DeepThings/deepthings -mode non_data_source -edge_id $2 -n $FTP_N -m $FTP_M -l $LAYERS > /dev/null 2>&1 &"
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
		start_host $DEV_IP
                ;;

            G )
                echo "Gateway device $DEV_IP"
		start_gateway $DEV_IP
                ;;

            E )
                EDGE_DEV_NUM="${BASH_REMATCH[3]}"
                EDGE_DEV_MODE="${BASH_REMATCH[4]}"
                echo "Edge device $EDGE_DEV_NUM $DEV_IP"

                case ${EDGE_DEV_MODE} in

                d )
                    echo "Data source"
		    start_data_edge $DEV_IP $EDGE_DEV_NUM
                    ;;

                n )
                    echo "Non-data source"
		    start_n_data_edge $DEV_IP $EDGE_DEV_NUM
                    ;;

                esac
                ;;

            esac
        fi
    done < devices.conf
else
    automatic_run
fi
