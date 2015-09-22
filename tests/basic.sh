#!/bin/bash
set -ex
OVPN_DATA=basic-data
CLIENT=travis-client
IMG=kylemanna/openvpn

#
# Create a docker container with the config data
#
docker run --name $OVPN_DATA -v /etc/openvpn busybox

ip addr ls
SERV_IP=$(ip -4 -o addr show scope global  | awk '{print $4}' | sed -e 's:/.*::' | head -n1)
docker run --volumes-from $OVPN_DATA --rm $IMG ovpn_genconfig -u udp://$SERV_IP

# nopass is insecure
docker run --volumes-from $OVPN_DATA --rm -it -e "EASYRSA_BATCH=1" -e "EASYRSA_REQ_CN=Travis-CI Test CA" $IMG ovpn_initpki nopass

docker run --volumes-from $OVPN_DATA --rm -it $IMG easyrsa build-client-full $CLIENT nopass

docker run --volumes-from $OVPN_DATA --rm $IMG ovpn_getclient $CLIENT | tee client/config.ovpn

#
# Fire up the server
#
sudo iptables -N DOCKER
sudo iptables -I FORWARD -j DOCKER
# run in shell bg to get logs
docker run --name "ovpn-test" --volumes-from $OVPN_DATA --rm -p 1194:1194/udp --privileged $IMG &

#for i in $(seq 10); do
#    SERV_IP=$(docker inspect --format '{{ .NetworkSettings.IPAddress }}')
#    test -n "$SERV_IP" && break
#done
#sed -ie s:SERV_IP:$SERV_IP:g client/config.ovpn

#
# Fire up a client in a container since openvpn is disallowed by Travis-CI, don't NAT
# the host as it confuses itself:
# "Incoming packet rejected from [AF_INET]172.17.42.1:1194[2], expected peer address: [AF_INET]10.240.118.86:1194"
#
docker run --rm --net=host --privileged --volume $PWD/client:/client $IMG /client/wait-for-connect.sh

#
# Client either connected or timed out, kill server
#
kill %1

#
# Celebrate
#
cat <<EOF
 ___________
< it worked >
 -----------
        \   ^__^
         \  (oo)\_______
            (__)\       )\/\\
                ||----w |
                ||     ||
EOF
