# Backing Up Configuration and Certificates

## Security

The resulting archive from this back-up contains all credential to impersonate the server at a minimum.  If the client private keys are generated using the EasyRSA utility then it also contains the client certificates that could be used to impersonate said clients.  Most importantly, if the certificate authority key is in this archive (as it is given the quick start directions), then a adversary could generate certificates at will.

I'd recommend encrypting the archive with something strong (e.g. gpg or openssl + AES).  For the paranoid keep backup offline.  For the truly paranoid users, never keep any keys (i.e. client and certificate authority) in the docker container to begin with :).


TL;DR Protect the resulting archive file, by ensure there is very limited access to it.

## Simple

    docker run  --volumes-from openvpn-data --rm kylemanna/openvpn tar czf - -C /etc openvpn > openvpn-backup.tar.gz
