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

    docker run -v $OVPN_DATA:/etc/openvpn --rm -p 443:1194/tcp --privileged kylemanna/openvpn ovpn_run --proto tcp

`ovpn_run` will load all the values from the default config file, and `--proto tcp` will override the protocol setting.

This allows you to use UDP most of the time, but fall back to TCP on the rare occasion that you need it.

Note that you will need to configure client connections manually. At this time it is not possible to generate a client config that will automatically fall back to the TCP connection.

