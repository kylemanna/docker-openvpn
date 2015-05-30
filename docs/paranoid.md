# Advanced security

As mentioned in the [backup section](/docs/backup.md), there are good reasons to not generate the CA and/or leave it on the server. This document describes how you can generate the CA and all your certificates on a secure machine and then copy only the needed files (which never includes the CA root key obviously ;) ) to the server(s) and clients.

Execute the following commands. Note that you might want to change the volume `/tmp/openvpn` to persistent storage or use a data docker container for this.

    docker run --rm -t -i -v $PWD:/etc/openvpn kylemanna/openvpn ovpn_genconfig -u udp://VPN.SERVERNAME.COM
    docker run --rm -t -i -v $PWD:/etc/openvpn kylemanna/openvpn ovpn_initpki
    docker run --rm -t -i -v $PWD:/etc/openvpn kylemanna/openvpn ovpn_copy_server_files

The [`ovpn_copy_server_files`](/bin/ovpn_copy_server_files) script puts all the needed configuration in a subdirectory which defaults to `$OPENVPN/server`. All you need to do now is to copy this directory to the server and you are good to go.
