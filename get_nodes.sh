#!/bin/bash

PKG_OK=$(dpkg-query -W --showformat='${Status}\n' arp-scan|grep "install ok installed")
if [ "" == "$PKG_OK" ]; then
	    sudo apt-get -qq -y install arp-scan
fi

IPs=$(sudo arp-scan --interface=$1 --localnet --numeric --quiet --ignoredups | grep -E '([a-f0-9]{2}:){5}[a-f0-9]{2}' | awk '{print $1}')
echo $IPs

