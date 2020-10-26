#!/bin/bash
set -e

[ -n "${DEBUG+x}" ] && set -x
OVPN_DATA=basic-data
IMG="kylemanna/openvpn"
NAME="ovpn-test"
SERV_IP=$(ip -4 -o addr show scope global  | awk '{print $4}' | sed -e 's:/.*::' | head -n1)

# generate server config including iptables nat-ing
docker volume create --name $OVPN_DATA
docker run --rm -v $OVPN_DATA:/etc/openvpn $IMG ovpn_genconfig -u udp://$SERV_IP -N
docker run -v $OVPN_DATA:/etc/openvpn --rm -it -e "EASYRSA_BATCH=1" -e "EASYRSA_REQ_CN=Travis-CI Test CA" $IMG ovpn_initpki nopass

# Fire up the server
docker run -d --name $NAME -v $OVPN_DATA:/etc/openvpn --cap-add=NET_ADMIN $IMG

# check default iptables rules
for i in $(seq 10); do
    docker exec -ti $NAME bash -c 'source /etc/openvpn/ovpn_env.sh; exec iptables -t nat -C POSTROUTING -s $OVPN_SERVER -o eth0 -j MASQUERADE' && break
    echo waiting for server start-up
    sleep 1
done

# append new setupIptablesAndRouting function to config
docker exec -ti $NAME bash -c 'echo function setupIptablesAndRouting { iptables -t nat -A POSTROUTING -m comment --comment "test"\;} >> /etc/openvpn/ovpn_env.sh'

# kill server in preparation to modify config
docker rm -f $NAME

# check that overridden function exists and that test iptables rules is active
docker run -d --name $NAME -v $OVPN_DATA:/etc/openvpn --cap-add=NET_ADMIN $IMG
docker exec -ti $NAME bash -c 'source /etc/openvpn/ovpn_env.sh; type -t setupIptablesAndRouting && iptables -t nat -C POSTROUTING -m comment --comment "test"'

#
# kill server
#

docker rm -f $NAME
docker volume rm $OVPN_DATA
