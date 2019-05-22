OpenVPN for Docker-compose
============================

OpenVPN server in a Docker container complete with an EasyRSA PKI CA.

Check if your port is availlable
================================

On your server:
```{.sh}
nc -ul -p 1194
```

On your computer
```{.sh}
nc -u __SERVER_IP__ 1194
```


Remove other VPN local:

In case an other service is started :
```
sudo systemctl stop openvpn@server.service
```


Quick Start with docker-compose
================================

```{.sh}
docker-compose run --rm openvpn_service ovpn_genconfig -u udp://____VPN.SERVERNAME.COM____
docker-compose run --rm openvpn_service ovpn_initpki
```

or

```{.sh}
docker-compose run --rm openvpn_service ovpn_genconfig -u udp://____VPN.SERVERNAME.COM____ -b -D -C AES-256-CBC -p ____LOCAL_IP_SERVER____/32 -R -V -F
docker-compose run --rm openvpn_service ovpn_initpki
```

**Note:** the ```-d``` create some errors


With a teltonika routeur, you need to add the interface of the docker:
```
-p "route 10.3.1.0 255.255.255.0"
```



Fix ownership (depending on how to handle your backups, this may not be needed)
---------------------------------------------------------------------------------

```{.sh}
sudo chown -R $(whoami): ./openvpn-data
```

Start OpenVPN server process
----------------------------

```{.sh}
docker-compose up -d openvpn_service
```

You can access the container logs with
--------------------------------------

```{.sh}
docker-compose logs -f
```

Generate a client certificate
-----------------------------

```{.sh}
export CLIENT_NAME="your_client_name"
# with a passphrase (recommended)
docker-compose run --rm openvpn easyrsa build-client-full $CLIENT_NAME
# without a passphrase (not recommended)
docker-compose run --rm openvpn easyrsa build-client-full $CLIENT_NAME nopass
```

Add toute too the client:
```
echo "route 10.10.1.0 255.255.255.0" >> openvpn-data/conf/openvpn.conf
echo "iroute 10.10.1.0 255.255.255.0" > openvpn-data/conf/ccd/$CLIENT_NAME
```


Retrieve the client configuration with embedded certificates
------------------------------------------------------------

In a single file:
```{.sh}
# if the container is down
docker-compose run --rm openvpn_service ovpn_getclient $CLIENT_NAME > $CLIENT_NAME.ovpn
# if the container is up
docker-compose exec openvpn_service ovpn_getclient $CLIENT_NAME > $CLIENT_NAME.ovpn
```

In multiple files
```{.sh}
# if the container is down
docker-compose run --rm openvpn_service ovpn_getclient $CLIENT_NAME separated
# if the container is up
docker-compose exec openvpn_service ovpn_getclient $CLIENT_NAME separated
```

Revoke a client certificate
---------------------------

```{.sh}
# Keep the corresponding crt, key and req files.
docker-compose run --rm openvpn_service ovpn_revokeclient $CLIENT_NAME
# Remove the corresponding crt, key and req files.
docker-compose run --rm openvpn_service ovpn_revokeclient $CLIENT_NAME remove
```

Debugging Tips
--------------

* Create an environment variable with the name DEBUG and value of 1 to enable debug output (using "docker -e").

```{.sh}
docker-compose run -e DEBUG=1 -p 1194:1194/udp openvpn_service
```

Test on the client:
-------------------

Run in root mode:
```
openvpn --config $CLIENT_NAME.ovpn
```

you can test the connection with the server:
```
ping ____LOCAL_IP_SERVER____
```

On server test the Connectionwith the client:
```
ping ____CLIENT_IP_SERVER____
```

If needed add the routing rules on the server:
```
ip route add 10.10.0.0/16 via 10.3.0.2
```

