This was originally a fork of https://github.com/rsc-1/dispos-a-vpn, but was redone to use Tinfoil Security's VPN script.

It adds the following features:

* A cloud-config file for CoreOS that launches this container and the config server.
* A script written in Python (using the CherryPy framework) to serve up the config file, with the ability to lock out said server when the user is done without touching SSH.

## Usage

## Terminal:
Initialize the **ovpn-data** container that will hold the configuration files and certificates
```
docker run --name ovpn-data -v /etc/openvpn busybox
```
Start OpenVPN server process
```
docker run -d --volumes-from ovpn-data --privileged -p 8080:8080/tcp -p 443:443/tcp -p 1194:1194/udp --name VPN htmlgraphic/openvpn:0.5
```
Visit https://`<ip_address>`:8080 - download the configuration file. 

Next, stop the running instance and remove it. When you start the service again all your configuration files will be persevered in the data container. 

Start a new instance with only the VPN port open. 

```
docker stop VPN
docker rm VPN
docker run -d --restart=always --volumes-from ovpn-data --privileged -p 1194:1194/udp --name VPN htmlgraphic/openvpn:0.5
```

## Requirements:

* Access to a service such as EC2, DigitalOcean etc that allows you to provide user data to instances and provides CoreOS images.
* The contents of `userdata.yml`.

## Steps (EC2):

1. Go to the CoreOS site and use the dropdown on the `Download CoreOS` button. Select EC2.
2. Look for the region you wish to run your VPN in.
3. Click one of the AMI IDs that correspond to your region.
4. Go through the instance creation process, but when asked for user data, paste the contents of `userdata.yml` into the box. You may also download `userdata.yml` and use the 'as file' option when asked for user data.
5. When asked for a security group, create a new one. Open TCP port 8080 and UDP port 1194.
6. When the instance has come up, wait. (5-10 minutes on t1. and t2. micros)  
7. Go to `https://<instance IP>:8080`.
8. Download the config, then point OpenVPN at it and connect.

## Steps (DigitalOcean):

1. Create a new droplet in a region that supports user data.
2. Choose CoreOS for the OS.
3. Paste the contents of `userdata.yml` into the user data box and create the droplet.
4. When the instance has come up, wait a couple of minutes and go to `https://<droplet IP>:8080`.
5. Download the config, then point OpenVPN at it and connect.
6. 

## Tested On
* OS X Mavericks with Tunnelblick 3Tunnelblick 3.4.2 (build 4055.4161)
