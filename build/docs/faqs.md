# Frequently Asked Questions

## How do I edit `openvpn.conf`?

Use a Docker image with an editor and connect the volume container:

    docker run -v $OVPN_DATA:/etc/openvpn --rm -it kylemanna/openvpn vi /etc/openvpn/openvpn.conf


## Why not keep everything in one image?

The run-time image (`kylemanna/openvpn`) is intended to be an ephemeral image. Nothing should be saved in it so that it can be re-downloaded and re-run when updates are pushed (i.e. newer version of OpenVPN or even Debian). The data container contains all this data and is attached at run time providing a safe home.

If it was all in one container, an upgrade would require a few steps to extract all the data, perform some upgrade import, and re-run. This technique is also prone to people losing their EasyRSA PKI when they forget where it was.  With everything in the data container upgrading is as simple as re-running `docker pull kylemanna/openvpn` and then `docker run ... kylemanna/openvpn`.

## How do I set up a split tunnel?

Split tunnels are configurations where only some of the traffic from a client goes to the VPN, with the remainder routed through the normal non-VPN interfaces. You'll want to disable a default route (-d) when you generate the configuration, but still use NAT (-N) to keep network address translation enabled.

    ovpn_genconfig -N -d ...

## I need to add some extra configurations to openvpn.conf, How can I do that ?

You can pass multiple (**-e**) options to `ovpn_genconfig`. For example, if you need to add _'duplicate-cn'_ and _'topology subnet'_ to the server configuration you could do something like this:

    ovpn_genconfig -e 'duplicate-cn' -e 'topology subnet' -u udp://VPN.SERVERNAME.COM
