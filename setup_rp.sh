#!/bin/bash

#Enable SSH
sudo touch /boot/ssh

ORIG_MAC_ADDR=$(cat /sys/class/net/eth0/address)

read -p 'New MAC address: ' NEW_MAC_ADDR

echo Changing MAC address from $ORIG_MAC_ADDR to $NEW_MAC_ADDR

ip link set down dev eth0
ip link set dev eth0 address $NEW_MAC_ADDR
ip link set up dev eth0

echo Persistently changing MAC address

sudo echo "[Match]" >> /etc/systemd/network/00-mac.link
sudo echo "MACAddress=$ORIG_MAC_ADDR" > /etc/systemd/network/00-mac.link
sudo echo "[Link]" > /etc/systemd/network/00-mac.link
sudo echo "MACAddress=$NEW_MAC_ADDR" > /etc/systemd/network/00-mac.link
sudo echo "NamePolicy=kernel database onboard slot path" > /etc/systemd/network/00-mac.link






