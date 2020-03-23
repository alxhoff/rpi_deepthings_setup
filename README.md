The scripts contained within this repository are used to setup a test cluster of Raspberry Pis to test the distributed inference proposed [here](https://github.com/rafzi/DeepThings).

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
| Host   |   -- WiFi SSID:`RPi Gateway` -->  |Gateway |  ------- eth0 ------>  |  Rpi   |
|   PC   |         (192.168.4.0/24)          |  RPi   |    (192.168.1.0/24)    | Cluster|
+--------+                                   +--------+    seperate switch     +--------+

```

# Setup

Initially the gateway RPi must be set up as it plays a crucial role. The gateway RPi acts as both a DHCP server for its `wlan0` and `eth0` interfaces, which are used for connecting to the cluster via ssh over WiFi and establishing the ethernet network between the cluster's RPis. Secondly it is then setup to provide an internet bridge for the cluster such that each device can pull the required dependencies for runing DeepThings.

## Setting up gateway RPi

The inital step requires the setting up of the gateway's networks such that it is accessible via ssh over the `RPiGateway` WiFi network. Initially on a terminal you must pull the [`setup_gateway.sh`](setup_gateway.sh) script onto the device and execute it.

``` bash
wget https://raw.githubusercontent.com/alxhoff/rpi_deepthings_setup/master/setup_gateway.sh
sudo ./setup_gateway.sh
```

After this you should be able to connect to the WiFi network `RPiGateway` (using password:`password`) and ssh into the gateway RPi via `ssh pi@192.168.1.1` (default RPi password is `raspberry`). 

Now the gateway RPi needs to be configured such that it can forward ipv4 traffic from its cluster interface to the internet. The [`setup_gateway.sh`](setup_gateway.sh) script calls the [`setup_ipv4_forwarding.sh`](setup_ipv4_forwarding.sh) script that asks for you to specify the MAC address of the interface connected to the internet (your dongle) and then will proceed to forward traffic to that connection from the closed `eth0` network within the cluster.

## Setting up cluster

The cluster (including the gateway device) need to have DeepThings setup and the depedency packages installed. This is done with [`setup_deepthings.sh`](setup_deepthings.sh) which is quite a straight forward process. To invoke the running on this on all devices in the cluster invoke the [`setup_cluster.sh`](setup_cluster.sh) script. This script will distribute and run [`setup_deepthings.sh`](setup_deepthings.sh) on all cluster devices (include gateway). After this you should be ready to go running tests. 

### Rebuilding DeepThings for cluser size

The size of the edge node cluster (total RPi count - 1 (gateway node)) will need to be modified to perform tests. As DeepThings hardcodes the device IPs and more specifically the device count, see [here](https://github.com/alxhoff/DeepThings/blob/64d4bdfd29dc7c6326a9257931ee4157e45ccb7e/include/configure.h#L34). The IP addresse array [here](https://github.com/alxhoff/DeepThings/blob/64d4bdfd29dc7c6326a9257931ee4157e45ccb7e/include/configure.h#L26) shouldn't need to be modified unless the cluster's architecture changes. The helper script [`rebuild_cluster`](rebuild_cluster.sh) takes two arguments that are passed to `make` as [`MAX_EDGE_NUM`](https://github.com/alxhoff/DeepThings/blob/64d4bdfd29dc7c6326a9257931ee4157e45ccb7e/include/configure.h#L33) and [`SKIP_FUSING`](https://github.com/alxhoff/DeepThings/blob/64d4bdfd29dc7c6326a9257931ee4157e45ccb7e/src/weight_partitioner.c#L155), `-m` specifies the number of edge devices that are to be used (the IP's of which will be the first n entries in the IP address array) and `-s` will skip fusing.

For example, to rebuild DeepThings across the cluster for 3 devices, skipping fusion, would be done with:

```bash
sudo ./rebuild_cluster -m 3 -s

```

# Running Tests

Test involve the setup of a test system architecture where each device must be given its role in the DeepThings system. See [DeepThings](https://github.com/rafzi/DeepThings#running) for the manual setup of a test. To help automate this the script [`run_demo.sh`](run_demo.sh) allows for automatic disstribution of a test or the preconfiguration of a test through a `.conf` file, such as [`devices.conf`](devices.conf).

Automatic distribution happens when [`run_demo.sh`](run_demo.sh) is called witout a configuration file, passing in using the `-c` option, see `--help` for more information. If automatic distribution is not used then the `.conf` file is used to identify what type of device each device should be configured as. Each line of the file uses the following converntion.

```
{H,G,E{x}{d,n}} IPv4_address
```
where H defines the host device, G defines a gateway device and Ex{d,s} defines eith a data-source or non-data-source edge device. Note each edge device requires a numeric identifier starting at 0 and either a `d` for data-source edge nodes or an `n` for non-data-source edge nodes. 

The example [`devices.conf`](devices.conf) is as follows:
```
H 192.168.1.201
G 192.168.1.2
E0d 192.168.1.12
E1n 192.168.1.13
```
Meaning that the DeepThing's test architecture has a host device @ 192.168.1.201, a gateway device @ 102.168.1.2, a data-source edge device with the numeric identifier 0 @ 192.168.1.12 and finally a non-data-source edge device with the numeric identifier 1 @ 192.168.1.13.

