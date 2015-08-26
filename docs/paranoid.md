# Advanced security

## Keep the CA root key save
As mentioned in the [backup section](/docs/backup.md), there are good reasons to not generate the CA and/or leave it on the server. This document describes how you can generate the CA and all your certificates on a secure machine and then copy only the needed files (which never includes the CA root key obviously ;) ) to the server(s) and clients.

Execute the following commands. Note that you might want to change the volume `$PWD` or use a data docker container for this.

    docker run --net=none --rm -t -i -v $PWD:/etc/openvpn kylemanna/openvpn ovpn_genconfig -u udp://VPN.SERVERNAME.COM
    docker run --net=none --rm -t -i -v $PWD:/etc/openvpn kylemanna/openvpn ovpn_initpki
    docker run --net=none --rm -t -i -v $PWD:/etc/openvpn kylemanna/openvpn ovpn_copy_server_files

The [`ovpn_copy_server_files`](/bin/ovpn_copy_server_files) script puts all the needed configuration in a subdirectory which defaults to `$OPENVPN/server`. All you need to do now is to copy this directory to the server and you are good to go.

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
