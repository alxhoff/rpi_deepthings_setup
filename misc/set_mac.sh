#!/bin/bash

#Enable SSH
touch /boot/ssh

#Set MAC
ORIG_MAC_ADDR=$(cat /sys/class/net/eth0/address)

read -p 'New MAC address: ' NEW_MAC_ADDR

if [ "$ORIG_MAC_ADDR" = "$NEW_MAC_ADDR" ]; then
	printf "....Already set\n"
else

	printf "Changing MAC address from $ORIG_MAC_ADDR to $NEW_MAC_ADDR\n"
	ip link set down dev eth0
	wait
	ip link set dev eth0 address $NEW_MAC_ADDR
	wait
	ip link set up dev eth0
	wait

	if ! [[ -f "/etc/systemd/network/00-mac.link" ]]; then
		echo Persistently changing MAC address

		echo "[Match]" > /etc/systemd/network/00-mac.link
		echo "MACAddress=$ORIG_MAC_ADDR" >> /etc/systemd/network/00-mac.link
		echo "[Link]" >> /etc/systemd/network/00-mac.link
		echo "MACAddress=$NEW_MAC_ADDR" >> /etc/systemd/network/00-mac.link
		echo "NamePolicy=kernel database onboard slot path" >> /etc/systemd/network/00-mac.link
		wait
	fi
fi

