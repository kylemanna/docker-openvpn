# Advanced security

## Keep the CA root key save
As mentioned in the [backup section](/docs/backup.md), there are good reasons to not generate the CA and/or leave it on the server. This document describes how you can generate the CA and all your certificates on a secure machine and then copy only the needed files (which never includes the CA root key obviously ;) ) to the server(s) and clients.

To create a separate DVC with a CA root key and all other PKI files and a dedicated DVC for an OpenVPN server, containing only the files needed by the server, execute the following script. Note that you should use the `ovpn-ca-data` DVC for any PKI related operations, e.g. generating user certificates.

    #!/bin/sh

    OVPN_SERVER_DATA="ovpn-server-data"
    OVPN_CA_DATA="ovpn-ca-data"
    OVPN_SERVER_NAME="udp://VPN.YOURDOMAIN.COM"
    
    for name in $OVPN_SERVER_DATA $OVPN_CA_DATA
    do
    	docker run --name $name -v /etc/openvpn busybox
    done
    
    docker run --net=none --volumes-from $OVPN_CA_DATA --rm  kylemanna/openvpn ovpn_genconfig -u $OVPN_SERVER_NAME
    docker run --net=none --volumes-from $OVPN_CA_DATA --rm -it kylemanna/openvpn ovpn_initpki
    
    TMP_DIR=$(mktemp -d)
    
    docker run --net=none --rm -t -i --volumes-from $OVPN_CA_DATA  -v $TMP_DIR:/etc/openvpn/server  kylemanna/openvpn ovpn_copy_server_files
    docker run --net=none --rm -t -i --volumes-from $OVPN_SERVER_DATA  -v $TMP_DIR:/openvpn/ busybox  cp -a /openvpn/ /etc/
    
    rm -rf $TMP_DIR


## Crypto Hardening

If you want to select the cyphers used by OpenVPN the following parameters of the `ovpn_genconfig` might interest you:

    -T    Encrypt packets with the given cipher algorithm instead of the default one (tls-cipher).
    -C    A list of allowable TLS ciphers delimited by a colon (cipher).
    -a    Authenticate  packets with HMAC using the given message digest algorithm (auth).


The following options have been tested successfully:

    docker run --volumes-from $OVPN_DATA --net=none --rm kylemanna/openvpn ovpn_genconfig -C 'AES-256-CBC' -a 'SHA384'

Changing the `tls-cipher` option seems to be more complicated because some clients (namely NetworkManager in Debian Jessie) seem to have trouble with this. Running `openvpn` manually also did not solve the issue:

    TLS Error: TLS key negotiation failed to occur within 60 seconds (check your network connectivity)
    TLS Error: TLS handshake failed

Have a look at the [Applied-Crypto-Hardening](https://github.com/BetterCrypto/Applied-Crypto-Hardening/tree/master/src/configuration/VPNs/OpenVPN) project for more examples.
