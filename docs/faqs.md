# Frequently Asked Questions

## How do I edit `openvpn.conf`?

Use a Docker image with a text editor pre-installed (i.e. Ubuntu) and connect the volume container:

    docker run --volumes-from $OVPN_DATA --rm -it ubuntu vi /etc/openvpn/openvpn.conf


## Why not keep everything in one image?

The run-time image (`kylemanna/openvpn`) is intended to be an ephemeral image. Nothing should be saved in it so that it can be re-downloaded and re-run when updates are pushed (i.e. newer version of OpenVPN or even Debian). The data container contains all this data and is attached at run time providing a safe home.

If it was all in one container, an upgrade would require a few steps to extract all the data, perform some upgrade import, and re-run. This technique is also prone to people losing their EasyRSA PKI when they forget where it was.  With everything in the data container upgrading is as simple as re-running `docker pull kylemanna/openvpn` and then `docker run ... kylemanna/openvpn`.

## How do I set up a split tunnel?

Split tunnels are configurations where only some of the traffic from a client goes to the VPN, with the remainder routed through the normal non-VPN interfaces. You'll want to disable a default route (-d) when you generate the configuration, but still use NAT (-N) to keep network address translation enabled. 

    ovpn_genconfig -N -d ...
