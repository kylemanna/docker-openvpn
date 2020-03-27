# Advanced Configurations

The [`ovpn_genconfig`](/bin/ovpn_genconfig) script is intended for simple configurations that apply to the majority of the users.  If your use case isn't general, it likely won't be supported.  This document aims to explain how to work around that.

## Create host volume mounts rather than data volumes

* Refer to the Quick Start document, and substitute `-v $OVPN_DATA:/etc/openvpn` with `-v /path/on/host/openvpn0:/etc/openvpn`
* Quick example that is likely to be out of date, but here's how to get started:

        mkdir openvpn0
        cd openvpn0
        docker run --rm -v $PWD:/etc/openvpn kylemanna/openvpn ovpn_genconfig -u udp://VPN.SERVERNAME.COM:1194
        docker run --rm -v $PWD:/etc/openvpn -it kylemanna/openvpn ovpn_initpki
        vim openvpn.conf
        docker run --rm -v $PWD:/etc/openvpn -it kylemanna/openvpn easyrsa build-client-full CLIENTNAME nopass
        docker run --rm -v $PWD:/etc/openvpn kylemanna/openvpn ovpn_getclient CLIENTNAME > CLIENTNAME.ovpn

* Start the server with:

        docker run -v $PWD:/etc/openvpn -d -p 1194:1194/udp --privileged kylemanna/openvpn

## Per-user routes

In certain instances, it's desirable to only allow users limited access to hosts on the VPN.  For example, say user `alice` is allowed to access the entire network, while `bob` should only be able to access a system at `192.168.1.4`.

To enable per-user routes, add the following to `/etc/openvpn/openvpn.conf`:

```
client-connect /usr/local/bin/client-connect
```

**NOTE**: Once this directive is added, the behavior is strict.  If there are no routes defined, users will not be able to access any hosts.

Next, add a file with the routes for each user on the system.  The name of the file should match the name of the client, so the routes file for the client created with the command `easyrsa build-client-full alice` will be `/etc/openvpn/routes/alice`.  The file should contain one route per line.  For `alice` to access the entire network her file should be:

```
0.0.0.0/0
```

For bob to only access the machine `192.168.1.4`, the file `/etc/openvpn/routes/bob` should be:

```
192.168.1.4/32
```

If, later `bob` also needs access to `192.168.1.11`, the file should be updated to be:

```
192.168.1.4/32
192.168.1.11/32
```
