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

CUR_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
bash $CUR_DIR/setup_ipv4_forwarding.sh
