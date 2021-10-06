#!/bin/bash
OVPN_DATA=$1

docker run --restart unless-stopped --stop-timeout 300 -v $OVPN_DATA:/etc/openvpn -d -p 1194:1194/udp --name ovpn-probaaho --cap-add=NET_ADMIN kylemanna/openvpn

