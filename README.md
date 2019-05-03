OpenVPN for Docker-compose
============================

OpenVPN server in a Docker container complete with an EasyRSA PKI CA.

Quick Start with docker-compose
================================

```{.sh}
docker-compose run --rm openvpn ovpn_genconfig -u udp://____VPN.SERVERNAME.COM____
docker-compose run --rm openvpn ovpn_initpki
```

or

```{.sh}
docker-compose run --rm openvpn ovpn_genconfig -u udp://____VPN.SERVERNAME.COM____ -b -d -D -C AES-256-CBC -p ____LOCAL_IP_SERVER____/32 -R -K ccd -V -L append -F
```

Fix ownership (depending on how to handle your backups, this may not be needed)
---------------------------------------------------------------------------------

```{.sh}
sudo chown -R $(whoami): ./openvpn-data
```

Start OpenVPN server process
----------------------------

```{.sh}
docker-compose up -d openvpn
```

You can access the container logs with
--------------------------------------

```{.sh}
docker-compose logs -f
```

Generate a client certificate
-----------------------------

```{.sh}
export CLIENTNAME="your_client_name"
# with a passphrase (recommended)
docker-compose run --rm openvpn easyrsa build-client-full $CLIENTNAME
# without a passphrase (not recommended)
docker-compose run --rm openvpn easyrsa build-client-full $CLIENTNAME nopass
```

Retrieve the client configuration with embedded certificates
------------------------------------------------------------

In a single file:
```{.sh}
docker-compose run --rm openvpn ovpn_getclient $CLIENTNAME > $CLIENTNAME.ovpn
```

In multiple files
```{.sh}
docker-compose run --rm openvpn ovpn_getclient $CLIENTNAME > $CLIENTNAME.ovpn
```

Revoke a client certificate
---------------------------

```{.sh}
# Keep the corresponding crt, key and req files.
docker-compose run --rm openvpn ovpn_revokeclient $CLIENTNAME
# Remove the corresponding crt, key and req files.
docker-compose run --rm openvpn ovpn_revokeclient $CLIENTNAME remove
```

Debugging Tips
--------------

* Create an environment variable with the name DEBUG and value of 1 to enable debug output (using "docker -e").

```{.sh}
docker-compose run -e DEBUG=1 -p 1194:1194/udp openvpn
```
