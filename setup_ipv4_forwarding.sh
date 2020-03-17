#!/bin/bash

if [ "$EUID" -ne 0 ]
	then echo "Please run as root"
	exit
fi

read -p 'MAC address of internet interface: ' MAC_ADDR

INTERNET_MAC="$(find /sys/class/net -mindepth 1 -maxdepth 1 ! -name lo -printf "%P: " -execdir cat {}/address \; | grep $MAC_ADDR)"
CLUSTER_MAC="$(find /sys/class/net -mindepth 1 -maxdepth 1 ! -name lo -printf "%P: " -execdir cat {}/address \; | grep eth | grep -v $MAC_ADDR)"

REGEX="(.+): ([0-9a-f]{2}):([0-9a-f]{2}):([0-9a-f]{2}):([0-9a-f]{2}):([0-9a-f]{2}):([0-9a-f]{2})"

if [[ $INTERNET_MAC =~ $REGEX ]]
then
	INTERNET_NAME="${BASH_REMATCH[1]}"
fi

if [[ $CLUSTER_MAC =~ $REGEX ]]
then
	CLUSTER_NAME="${BASH_REMATCH[1]}"
fi

echo "Forwarding ipv4 traffic from '$CLUSTER_NAME' to '$INTERNET_NAME'"

exit 0

echo Flushing iptables
iptables -F
echo Flushing nat iptables
iptables -t nat -F
echo Adding complex routing stuffz
iptables -t nat -A POSTROUTING -o $INTERNET_NAME -j MASQUERADE
iptables -A FORWARD -i $INTERNET_NAME -o $CLUSTER_NAME -m state --state RELATED,ESTABLISHED -j ACCEPT
iptables -A FORWARD -i $CLUSTER_NAME -o $INTERNET_NAME -j ACCEPT

echo "enabling ipv4 forwarding"
echo 1 | tee -a /proc/sys/net/ipv4/ip_forward

systemctl restart dnsmasq

echo Internet forwarding done!
