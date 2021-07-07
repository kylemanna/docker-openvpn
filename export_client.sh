#!/bin/bash
OVPN_DATA=$1
CLIENTNAME=$2
CLIENTFILENAME="${CLIENTNAME}.ovpn"

docker run -v $OVPN_DATA:/etc/openvpn --rm kylemanna/openvpn ovpn_getclient $CLIENTNAME > $CLIENTFILENAME

