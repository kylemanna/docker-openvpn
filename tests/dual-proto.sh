#!/bin/bash
set -ex

OVPN_DATA=dual-data
CLIENT_UDP=travis-client
CLIENT_TCP=travis-client-tcp
IMG=kylemanna/openvpn

#
# Create a docker container with the config data
#
docker run --name $OVPN_DATA -v /etc/openvpn busybox

ip addr ls
SERV_IP=$(ip -4 -o addr show scope global  | awk '{print $4}' | sed -e 's:/.*::' | head -n1)

# get temporary TCP config
docker run --volumes-from $OVPN_DATA --rm $IMG ovpn_genconfig -u tcp://$SERV_IP:443

# nopass is insecure
docker run --volumes-from $OVPN_DATA --rm -it -e "EASYRSA_BATCH=1" -e "EASYRSA_REQ_CN=Travis-CI Test CA" $IMG ovpn_initpki nopass

# gen TCP client
docker run --volumes-from $OVPN_DATA --rm -it $IMG easyrsa build-client-full $CLIENT_TCP nopass
docker run --volumes-from $OVPN_DATA --rm $IMG ovpn_getclient $CLIENT_TCP | tee client/config-tcp.ovpn

# switch to UDP config and gen UDP client
docker run --volumes-from $OVPN_DATA --rm $IMG ovpn_genconfig -u udp://$SERV_IP
docker run --volumes-from $OVPN_DATA --rm -it $IMG easyrsa build-client-full $CLIENT_UDP nopass
docker run --volumes-from $OVPN_DATA --rm $IMG ovpn_getclient $CLIENT_UDP | tee client/config.ovpn

#Verify client configs
docker run --volumes-from $OVPN_DATA --rm $IMG ovpn_listclients | grep $CLIENT_TCP
docker run --volumes-from $OVPN_DATA --rm $IMG ovpn_listclients | grep $CLIENT_UDP

#
# Fire up the server
#
sudo iptables -N DOCKER
sudo iptables -I FORWARD -j DOCKER

# run in shell bg to get logs
docker run --name "ovpn-test-udp" --volumes-from $OVPN_DATA --rm -p 1194:1194/udp --privileged $IMG &
docker run --name "ovpn-test-tcp" --volumes-from $OVPN_DATA --rm -p 443:1194/tcp --privileged $IMG ovpn_run --proto tcp &

#
# Fire up a clients in a containers since openvpn is disallowed by Travis-CI, don't NAT
# the host as it confuses itself:
# "Incoming packet rejected from [AF_INET]172.17.42.1:1194[2], expected peer address: [AF_INET]10.240.118.86:1194"
#
docker run --rm --net=host --privileged --volume $PWD/client:/client $IMG /client/wait-for-connect.sh
docker run --rm --net=host --privileged --volume $PWD/client:/client $IMG /client/wait-for-connect.sh "/client/config-tcp.ovpn"

#
# Client either connected or timed out, kill server
#
kill %1

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

