# TCP Protocol

## TCP vs. UDP - Pros & Cons
By default, OpenVPN is configured to use the UDP protocol.  Because UDP incurs minimal protocol overhead (for example, no acknowledgment is required upon successful packet receipt), it can sometimes result in slightly faster throughput.  However, in situations where VPN service is needed over an unreliable connection, the user experience can benefit from the extra diagnostic features of the TCP protocol.

As an example, users connecting from an airplane wifi network may experience high packet drop rates, where the error detection and sliding window control of TCP can more readily adjust to the inconsistent connection.

Another example would be trying to open a VPN connection from within a very restrictive network. In some cases port 1194, or even UDP traffic on any port, may be restricted by network policy. Because TCP traffic on port 443 is used for normal TLS (https) web browsing, it is very unlikely to be blocked.

## Using TCP
Those requiring TCP connections should initialize the data container by specifying the TCP protocol and port number:

    docker run -v $OVPN_DATA:/etc/openvpn --rm kylemanna/openvpn ovpn_genconfig -u tcp://VPN.SERVERNAME.COM:443
    docker run -v $OVPN_DATA:/etc/openvpn --rm -it kylemanna/openvpn ovpn_initpki

Because the server container always exposes port 1194, regardless of the
specified protocol, adjust the mapping appropriately:

    docker run -v $OVPN_DATA:/etc/openvpn -d -p 443:1194/tcp --cap-add=NET_ADMIN kylemanna/openvpn

## Running a Second Fallback TCP Container
Instead of choosing between UDP and TCP, you can use both. A single instance of OpenVPN can only listen for a single protocol on a single port, but this image makes it easy to run two instances simultaneously. After building, configuring, and starting a standard container listening for UDP traffic on 1194, you can start a second container listening for tcp traffic on port 443:

    docker run -v $OVPN_DATA:/etc/openvpn --rm -p 443:1194/tcp --cap-add=NET_ADMIN kylemanna/openvpn ovpn_run --proto tcp

`ovpn_run` will load all the values from the default config file, and `--proto tcp` will override the protocol setting.

This allows you to use UDP most of the time, but fall back to TCP on the rare occasion that you need it.

Note that you can either (1) configure client connections manually (to respect the fallback server port difference) or (2) add `connection` configuration to your ovpn profiles. Referencing the OpenVPN docs: 

```
<connection>
Define a client connection profile. Client connection profiles are groups of OpenVPN options that describe how to connect to a given OpenVPN server.
Client connection profiles are specified within an OpenVPN configuration file, and each profile is bracketed by <connection> and </connection>.
An OpenVPN client will try each connection profile sequentially until it achieves a successful connection.
```

An example of this would be (inside of a client ovpn profile): 

```
...
<connection>
remote my.vpn.server 1194 udp
</connection>

<connection>
remote my.vpn.server 443 tcp
</connection>
...
```

In this scenario, the client would first attempt to connect over UDP traffic on port 1194. If the connection is unsuccessful, it will then automatically attempt to the next connection block (in this case, TCP traffic on port 443). This can be very useful and seamless for setting up your fallback server.

## Forward HTTP/HTTPS connection to another TCP port
You might run into cases where you want your OpenVPN server listening on TCP port 443 to allow connection behind a restricted network, but you already have a webserver on your host running on that port. OpenVPN has a built-in option named `port-share` that allow you to proxy incoming traffic that isn't OpenVPN protocol to another host and port.

First, change the listening port of your existing webserver (for instance from 443 to 4433).

Then initialize the data container by specifying the TCP protocol, port 443 and the port-share option:

    docker run -v $OVPN_DATA:/etc/openvpn --rm kylemanna/openvpn ovpn_genconfig \
    -u tcp://VPN.SERVERNAME.COM:443 \
    -e 'port-share VPN.SERVERNAME.COM 4433'
    
Then proceed to initialize the pki, create your users and start the container as usual.
    
This will proxy all non OpenVPN traffic incoming on TCP port 443 to TCP port 4433 on the same host. This is currently only designed to work with HTTP or HTTPS protocol.
