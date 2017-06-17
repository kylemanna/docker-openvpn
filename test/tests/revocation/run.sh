#!/bin/bash
set -e

[ -n "${DEBUG+x}" ] && set -x

OVPN_DATA="basic-data"
CLIENT1="travis-client1"
CLIENT2="travis-client2"
IMG="kylemanna/openvpn"
NAME="ovpn-test"
CLIENT_DIR="$(readlink -f "$(dirname "$BASH_SOURCE")/../../client")"
SERV_IP="$(ip -4 -o addr show scope global  | awk '{print $4}' | sed -e 's:/.*::' | head -n1)"

#
# Initialize openvpn configuration and pki.
#
docker volume create --name $OVPN_DATA
docker run --rm -v $OVPN_DATA:/etc/openvpn $IMG ovpn_genconfig -u udp://$SERV_IP
docker run --rm -v $OVPN_DATA:/etc/openvpn -it -e "EASYRSA_BATCH=1" -e "EASYRSA_REQ_CN=Travis-CI Test CA" $IMG ovpn_initpki nopass

#
# Fire up the server.
#
sudo iptables -N DOCKER || echo 'Firewall already configured'
sudo iptables -I FORWARD 1 -j DOCKER
docker run -d -v $OVPN_DATA:/etc/openvpn --cap-add=NET_ADMIN --privileged -p 1194:1194/udp --name $NAME $IMG


#
# Test that easy_rsa generate CRLs with 'next publish' set to 3650 days.
#
crl_next_update="$(docker exec $NAME openssl crl -nextupdate -noout -in /etc/openvpn/crl.pem | cut -d'=' -f2 | tr -d 'GMT')"
crl_next_update="$(date -u -d "$crl_next_update" "+%s")"
now="$(docker exec $NAME date "+%s")"
crl_remain="$(( $crl_next_update - $now ))"
crl_remain="$(( $crl_remain / 86400 ))"
if (( $crl_remain < 3649 )); then
    echo "easy_rsa CRL next publish set to less than 3650 days." >&2
    exit 2
fi

#
# Generate a first client certificate and configuration using $CLIENT1 as CN then revoke it.
#
docker exec -it $NAME easyrsa build-client-full $CLIENT1 nopass
docker exec -it $NAME ovpn_getclient $CLIENT1 > $CLIENT_DIR/config.ovpn
docker exec -it $NAME bash -c "echo 'yes' | ovpn_revokeclient $CLIENT1 remove"

#
# Test that openvpn client can't connect using $CLIENT1 config.
#
if docker run --rm -v $CLIENT_DIR:/client --cap-add=NET_ADMIN --privileged --net=host $IMG /client/wait-for-connect.sh; then
    echo "Client was able to connect after revocation test #1." >&2
    exit 2
fi

#
# Generate and revoke a second client certificate using $CLIENT2 as CN, then test for failed client connection.
#
docker exec -it $NAME easyrsa build-client-full $CLIENT2 nopass
docker exec -it $NAME ovpn_getclient $CLIENT2 > $CLIENT_DIR/config.ovpn
docker exec -it $NAME bash -c "echo 'yes' | ovpn_revokeclient $CLIENT2 remove"

if docker run --rm -v $CLIENT_DIR:/client --cap-add=NET_ADMIN --privileged --net=host $IMG /client/wait-for-connect.sh; then
    echo "Client was able to connect after revocation test #2." >&2
    exit 2
fi

#
# Restart the server
#
docker stop $NAME && docker start $NAME

#
# Test for failed connection using $CLIENT2 config again.
#
if docker run --rm -v $CLIENT_DIR:/client --cap-add=NET_ADMIN --privileged --net=host $IMG /client/wait-for-connect.sh; then
    echo "Client was able to connect after revocation test #3." >&2
    exit 2
fi

#
# Stop the server and clean up
#
docker kill $NAME && docker rm $NAME
docker volume rm $OVPN_DATA
sudo iptables -D FORWARD 1

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
