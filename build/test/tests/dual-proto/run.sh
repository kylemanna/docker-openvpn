#!/bin/bash
set -e

[ -n "${DEBUG+x}" ] && set -x

OVPN_DATA=dual-data
CLIENT_UDP=travis-client
CLIENT_TCP=travis-client-tcp
IMG=kylemanna/openvpn
CLIENT_DIR="$(readlink -f "$(dirname "$BASH_SOURCE")/../../client")"

ip addr ls
SERV_IP=$(ip -4 -o addr show scope global  | awk '{print $4}' | sed -e 's:/.*::' | head -n1)

# get temporary TCP config
docker run -v $OVPN_DATA:/etc/openvpn --rm $IMG ovpn_genconfig -u tcp://$SERV_IP:443

# nopass is insecure
docker run -v $OVPN_DATA:/etc/openvpn --rm -it -e "EASYRSA_BATCH=1" -e "EASYRSA_REQ_CN=Travis-CI Test CA" $IMG ovpn_initpki nopass

# gen TCP client
docker run -v $OVPN_DATA:/etc/openvpn --rm -it $IMG easyrsa build-client-full $CLIENT_TCP nopass
docker run -v $OVPN_DATA:/etc/openvpn --rm $IMG ovpn_getclient $CLIENT_TCP | tee $CLIENT_DIR/config-tcp.ovpn

# switch to UDP config and gen UDP client
docker run -v $OVPN_DATA:/etc/openvpn --rm $IMG ovpn_genconfig -u udp://$SERV_IP
docker run -v $OVPN_DATA:/etc/openvpn --rm -it $IMG easyrsa build-client-full $CLIENT_UDP nopass
docker run -v $OVPN_DATA:/etc/openvpn --rm $IMG ovpn_getclient $CLIENT_UDP | tee $CLIENT_DIR/config.ovpn

#Verify client configs
docker run -v $OVPN_DATA:/etc/openvpn --rm $IMG ovpn_listclients | grep $CLIENT_TCP
docker run -v $OVPN_DATA:/etc/openvpn --rm $IMG ovpn_listclients | grep $CLIENT_UDP

#
# Fire up the server
#
sudo iptables -N DOCKER || echo 'Firewall already configured'
sudo iptables -I FORWARD -j DOCKER || echo 'Forward already configured'

# run in shell bg to get logs
docker run --name "ovpn-test-udp" -v $OVPN_DATA:/etc/openvpn --rm -p 1194:1194/udp --privileged $IMG &
docker run --name "ovpn-test-tcp" -v $OVPN_DATA:/etc/openvpn --rm -p 443:1194/tcp --privileged $IMG ovpn_run --proto tcp &

#
# Fire up a clients in a containers since openvpn is disallowed by Travis-CI, don't NAT
# the host as it confuses itself:
# "Incoming packet rejected from [AF_INET]172.17.42.1:1194[2], expected peer address: [AF_INET]10.240.118.86:1194"
#
docker run --rm --net=host --privileged --volume $CLIENT_DIR:/client $IMG /client/wait-for-connect.sh
docker run --rm --net=host --privileged --volume $CLIENT_DIR:/client $IMG /client/wait-for-connect.sh "/client/config-tcp.ovpn"

#
# Client either connected or timed out, kill server
#
kill %1 %2

#
# Celebrate
#
cat <<EOF
 ____________               ___________
< it worked! >             < both ways! >
 ------------               ------------
        \   ^__^        ^__^   /
	 \  (oo)\______/(oo)  /
	    (__)\      /(__)
                ||w---w||
                ||     ||
EOF

