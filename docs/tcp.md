# TCP Protocol

## TCP vs. UDP - Pros & Cons
By default, OpenVPN is configured to use the UDP protocol.  Because UDP incurs minimal protocol overhead (for example, no acknowledgment is required upon successful packet receipt), it can sometimes result in slightly faster throughput.  However, in situations where VPN service is needed over an unreliable connection, the user experience can benefit from the extra diagnostic features of the TCP protocol.

As an example, users connecting from an airplane wifi network may experience high packet drop rates, where the error detection and sliding window control of TCP can more readily adjust to the inconsistent connection.

## Using TCP
Those requiring TCP connections should initialize the data container by specifying the TCP protocol and port number:

    docker run --volumes-from $OVPN_DATA --rm kylemanna/openvpn ovpn_genconfig -u tcp://VPN.SERVERNAME.COM:443
    docker run --volumes-from $OVPN_DATA --rm -it kylemanna/openvpn ovpn_initpki

Because the server container always exposes port 1194, regardless of the
specified protocol, adjust the mapping appropriately:

    docker run --volumes-from $OVPN_DATA -d -p 443:1194/tcp --cap-add=NET_ADMIN kylemanna/openvpn

