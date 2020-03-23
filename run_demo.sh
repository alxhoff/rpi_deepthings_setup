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
    echo " (-tc) 		bandwidth limit imposed using tc in mbit"
    echo " (-c)                 .conf file to be used for test architecture "
    echo " (-t)                 Timeout for deepthing execution on each node, default is 120 seconds"
    exit 0
}

reset_tc_rules()
{
       bash $CUR_DIR/ssh_command.sh $1 'sudo tc qdisc del dev eth0 root > /dev/null 2>&1'
}

set_tc_rules() 
{
	reset_tc_rules $1
       	bash $CUR_DIR/ssh_command.sh $1 'sudo tc qdisc add dev eth0 root handle 1: htb default 12'
       	bash $CUR_DIR/ssh_command.sh $1 "sudo tc class add dev eth0 parent 1:1 classid 1:12 htb rate $2mbit ceil $2mbit"
       	bash $CUR_DIR/ssh_command.sh $1 'sudo tc qdisc add dev eth0 parent 1:12 netem limit 10000000'
}

automatic_run()
{
    EDGE_ID=0

    #Current device is set as gateway
    GATEWAY_IP=$(ip addr show eth0 | grep "inet\b" | awk '{print $2}' | cut -d/ -f1)

    #All other devs on eth0 are edge devices
    EDGE_NODE_IPS=($(bash $CUR_DIR/get_nodes.sh eth0))

    if  [ ! -z "$TC_LIMIT" ]; then
	#echo "Using TC with limit @ $TC_LIMIT"
	set_tc_rules $GATEWAY_IP $TC_LIMIT
    	for IP in "${EDGE_NODE_IPS[@]}"
    	do
    	    set_tc_rules $IP $TC_LIMIT
    	done
    else 
	#echo "Not using TC, resetting interface"
	reset_tc_rules $GATEWAY_IP
    	for IP in "${EDGE_NODE_IPS[@]}"
    	do
    	    reset_tc_rules $IP
    	done
    fi

    DATA_EDGE_IP="${EDGE_NODE_IPS[0]}"
    HOST_IP=$DATA_EDGE_IP
    NON_DATA_EDGE_IPS="${EDGE_NODE_IPS[@]:1}"

    start_gateway $GATEWAY_IP
    start_data_edge $DATA_EDGE_IP $EDGE_ID
    EDGE_ID=$((EDGE_ID+1))
    for IP in ${NON_DATA_EDGE_IPS[@]}
    do
        start_n_data_edge $IP $EDGE_ID
        EDGE_ID=$((EDGE_ID+1))
    done

    #echo "Start commands sent, waiting a little bit before starting"
    sleep 30

    start_host $HOST_IP
    #echo "Host started, waiting for $DEFAULT_TIMEOUT seconds for timeout"

    sleep $DEFAULT_TIMEOUT
}

start_host()
{
	bash $CUR_DIR/ssh_command.sh $1 "cd /home/pi/DeepThings && timeout $DEFAULT_TIMEOUT ./deepthings -mode start" > /home/pi/host.log 2>&1 &
	#echo "HOST @ $1: ./deepthings -mode start"
}

start_gateway()
{
	bash $CUR_DIR/ssh_command.sh $1 "cd /home/pi/DeepThings && timeout $DEFAULT_TIMEOUT ./deepthings -mode gateway -total_edge $TOTAL_EDGE -n $FTP_N -m $FTP_M -l $LAYERS" > /home/pi/gateway.log 2>&1 &
	#echo "GATEWAY @ $1: ./deepthings -mode gateway -total_edge $TOTAL_EDGE -n $FTP_N -m $FTP_M -l $LAYERS"
}

start_data_edge()
{
	bash $CUR_DIR/ssh_command.sh $1 "cd /home/pi/DeepThings && timeout $DEFAULT_TIMEOUT ./deepthings -mode data_src -total_edge $TOTAL_EDGE -edge_id $2 -n $FTP_N -m $FTP_M -l $LAYERS" > /home/pi/data_src.log 2>&1 &
	#echo "DATA EDGE @ $1: ./deepthings -mode data_src -total_edge $TOTAL_EDGE -edge_id $2 -n $FTP_N -m $FTP_M -l $LAYERS"
}

start_n_data_edge()
{
	bash $CUR_DIR/ssh_command.sh $1 "cd /home/pi/DeepThings && timeout $DEFAULT_TIMEOUT ./deepthings -mode non_data_src -total_edge $TOTAL_EDGE -edge_id $2 -n $FTP_N -m $FTP_M -l $LAYERS" > /home/pi/n_data_src_$2.log 2>&1 &
	#echo "EDGE DEV #$2 @ $1: ./deepthings -mode non_data_src -total_edge $TOTAL_EDGE -edge_id $2 -n $FTP_N -m $FTP_M -l $LAYERS"
}


DEFAULT_TIMEOUT=120

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
    -t) shift
        DEFAULT_TIMEOUT=$1
        shift
        ;;
    -tc) shift
	TC_LIMIT=$1
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
                set_tc_rules $DEV_IP
		start_gateway $DEV_IP
                ;;

            E )
                EDGE_DEV_NUM="${BASH_REMATCH[3]}"
                EDGE_DEV_MODE="${BASH_REMATCH[4]}"
                echo "Edge device $EDGE_DEV_NUM $DEV_IP"

                case ${EDGE_DEV_MODE} in

                d )
                    echo "Data source"
                    set_tc_rules $DEV_IP
		    start_data_edge $DEV_IP $EDGE_DEV_NUM
                    ;;

                n )
                    echo "Non-data source"
                    set_tc_rules $DEV_IP
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
