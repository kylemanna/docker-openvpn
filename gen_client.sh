#!/bin/bash
OVPN_DATA=$1
CLIENTNAME=$2

docker run -v $OVPN_DATA:/etc/openvpn --rm -it kylemanna/openvpn easyrsa build-client-full $CLIENTNAME nopass

