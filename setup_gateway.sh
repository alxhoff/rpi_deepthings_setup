#!/bin/bash

if [ "$EUID" -ne 0 ]
	then echo "Please run as root"
	exit
fi

echo 'country=DE' | tee -a /etc/wpa_supplicant/wpa_supplicant.conf
rfkill unblock 0

apt-get install -y hostapd dnsmasq expect

systemctl stop dnsmasq
wait
systemctl stop hostapd
wait

cp dhcpcd.conf /etc/dhcpcd.conf

service dhcpcd restart
wait

cp dnsmasq-eth0.conf /etc/dnsmasq.d/dnsmasq-eth0.conf
cp dnsmasq-wlan0.conf /etc/dnsmasq.d/dnsmasq-wlan0.conf

systemctl start dnsmasq
wait

cp hostapd.conf /etc/hostapd/hostapd.conf

echo 'DAEMON_CONF="/etc/hostapd/hostapd.conf"' | tee -a /etc/default/hostapd

systemctl unmask hostapd
wait
systemctl enable hostapd
wait
systemctl start hostapd
wait

systemctl status hostapd
systemctl status dnsmasq

#Add routing rules such that all 192.168.1.* traffic routes through eth0
#ip route add 192.168.1.0/24 via 192.168.1.1 dev eth0
