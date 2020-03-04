# TODO

- Setup script
  - ARP scan dev list
  - Setup script per dev
- Host dev test scripts

# Setup Architecture

There is a central controlling RPi that acts as a SSH AP as well as an internet bridge for the rest of the Pis.

All of the RPis in the cluster should be connected via their onboard ethernet ports (`eth0`) to an offline switch such that this closed network can be administered via the gateway RPi. The gateway RPi should then be connected via a seperate dongle to a network that can provide internet.

To setup the gateway RPi you must first connect it manaually to an internet connection and run the script [`setup_gateway.sh`](setup_gateway.sh).

```
                                             +--------+
                                             |Internet|
                                             +--------+
                                                  |
                                             eth1 (dongle)
                                                  | - ipv4 forwarding via gateway - |
                                                  v                                 V
+--------+                                   +--------+                        +--------+
| Your   |   -- WiFi SSID:`RPi Gateway` -->  |Gateway |  ------- eth0 ------>  |  Rpi   |
|   PC   |         (192.168.4.0/24)          |  RPi   |    (192.168.1.0/24)    | Cluster|
+--------+                                   +--------+    seperate switch     +--------+

```

# Setup

Initially the host RPi must be set up as it plays a crucial role. The gateway RPi acts as both a DHCP server for its `wlan0` and `eth0` interfaces, which are used for connecting to the cluster via ssh over WiFi and establishing the ethernet network between the cluster's RPis. Secondly it is then setup to provide an internet bridge for the cluster such that each device can pull the required dependencies for runing DeepThings.

## Setting up gateway RPi

The inital step requires the setting up of the gateway's networks such that it is accessible via ssh over the `RPiGateway` WiFi network. Initially on a terminal you must pull the [`setup_gateway.sh`](setup_gateway.sh) script onto the device and execute it.

``` bash
https://raw.githubusercontent.com/alxhoff/rpi_deepthings_setup/master/setup_gateway.sh
sudo ./setup_gateway.sh
```

After this you should be able to connect to the WiFi network `RPiGateway` (using password:`password`) and ssh into the gateway RPi via `ssh pi@192.168.1.1` (default RPi password is `raspberry`). 

Now the gateway RPi needs to be configured such that it can forward ipv4 traffic from its cluster interface to the internet. The [`setup_gateway.sh`](setup_gateway.sh) script calls the [`setup_ipv4_forwarding.sh`](setup_ipv4_forwarding.sh) script that asks for you to specify the MAC address of the interface connected to the internet (your dongle) and then will proceed to forward traffic to that connection from the closed `eth0` network within the cluster.

## Setting up cluster

The cluster (including the gateway device) need to have DeepThings setup and the depedency packages installed. This is done with [`setup_deepthings.sh`](setup_deepthings.sh) which is quite a straight forward process. To invoke the running on this on all devices in the cluster invoke the [`setup_cluster.sh`](setup_cluster.sh) script. This script will distribute and run [`setup_deepthings.sh`](setup_deepthings.sh) on all cluster devices (include gateway).
