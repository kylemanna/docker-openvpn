#!/bin/bash
set -ex
OVPN_DATA=basic-data
CLIENT=travis-client

docker run --name $OVPN_DATA -v /etc/openvpn busybox

docker run --volumes-from $OVPN_DATA --rm kylemanna/openvpn ovpn_genconfig -u udp://travis-ci

# nopass is insecure
docker run --volumes-from $OVPN_DATA --rm -it -e "EASYRSA_BATCH=1" -e "EASYRSA_REQ_CN=Travis-CI Test CA" kylemanna/openvpn ovpn_initpki nopass

docker run --volumes-from $OVPN_DATA --rm -it kylemanna/openvpn easyrsa build-client-full $CLIENT nopass

docker run --volumes-from $OVPN_DATA --rm kylemanna/openvpn ovpn_getclient $CLIENT


