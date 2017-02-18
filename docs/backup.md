# Backing Up Configuration and Certificates

## Security

The resulting archive from this backup contains all credential to impersonate the server at a minimum.  If the client's private keys are generated using the EasyRSA utility then it also contains the client certificates that could be used to impersonate said clients.  Most importantly, if the certificate authority key is in this archive (as it is given the quick start directions), then a adversary could generate certificates at will.

I'd recommend encrypting the archive with something strong (e.g. gpg or openssl + AES).  For the paranoid keep backup offline.  For the [truly paranoid users](/docs/paranoid.md), never keep any keys (i.e. client and certificate authority) in the docker container to begin with :).


**TL;DR Protect the resulting archive file.  Ensure there is very limited access to it.**

## Backup to Archive

    docker run -v $OVPN_DATA:/etc/openvpn --rm kylemanna/openvpn tar -cvf - -C /etc openvpn | xz > openvpn-backup.tar.xz

## Restore to New Data Volume

Creates an volume container named `$OVPN_DATA` to extract the data to.

    docker volume create --name $OVPN_DATA
    xzcat openvpn-backup.tar.xz | docker run -v $OVPN_DATA:/etc/openvpn -i kylemanna/openvpn tar -xvf - -C /etc
