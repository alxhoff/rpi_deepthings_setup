#!/bin/bash
	
if [ "$EUID" -ne 0 ]
	then echo "Please run as root"
	exit
fi

FTP_N=3
FTP_M=3
FUSED_LAYERS=16

print_usage()
{
	echo "Usage : $0 [-d -t (-n) (-m) (-l)]"
	echo ""
	echo " -d 	maximum number of devices"
	echo " -t 	number of tests to be performed per configuration"
	echo " -n 	FTP dimension N, defaults to 3"
	echo " -m 	FTP dimension M, defaults to 3"
	echo " -l 	Number of fused layers, defaults to 16"
}

CUR_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

key=$1
while [[ $# -gt 0 ]]
	do
	key="$1"

	case $key in

	-h|--help)
		print_usage
		exit 1
		;;
	-d|--dev-count)
		shift
		DEVICE_COUNT=$1	
		shift
		;;
	-t|--num-tests)
		shift
		TEST_NUM=$1
		shift
		;;
	-n|--ftp-n)
		shift
		FTP_N=$1
		shift
		;;
	-m|--ftp-m)
		shift
		FTP_M=$1
		shift
		;;
	-l|--fused-layers)
		shift
		FUSED_LAYERS=$1
		shift
		;;
	*)
		print_usage
		exit 1
	esac
done

if [ -z "$DEVICE_COUNT" ] || [ -z "$TEST_NUM" ]; then
	echo "Not all required options given, see --help for usage"
	echo 1
fi

for DEVICE in $(seq 1 $DEVICE_COUNT)
do
	echo "Rebuilding cluster for $DEVICE devs, not skipping fusion"
	bash $CUR_DIR/rebuild_cluster.sh -m $DEVICE
	wait
	sleep 10 #To be safe all devices are finished

	for TEST in $(seq 1 $TEST_NUM)
	do
		echo ""
		echo "###################################################"
		echo "Running test $TEST for $DEVICE devs without skipping"
		echo "###################################################"
		echo ""
		bash run_demo.sh -e $DEVICE -n $FTP_N -m $FTP_M -l $FUSED_LAYERS
	done

	echo "Rebuilding cluster for $DEVICE devs, skipping fusion"
	bash $CUR_DIR/rebuild_cluster.sh -m $DEVICE -s
	wait
	sleep 10 #To be safe all devices are finished

	for TEST in $(seq 1 $TEST_NUM)
	do
		echo ""
		echo "###################################################"
		echo "Running test $TEST for $DEVICE devs with skipping"
		echo "###################################################"
		echo ""
		bash run_demo.sh -e $DEVICE -n $FTP_N -m $FTP_M -l $FUSED_LAYERS
	done
done	
