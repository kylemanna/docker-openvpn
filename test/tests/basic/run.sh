#!/bin/bash
set -e

[ -n "${DEBUG+x}" ] && set -x

OVPN_DATA=basic-data
CLIENT=travis-client
IMG=kylemanna/openvpn
CLIENT_DIR="$(readlink -f "$(dirname "$BASH_SOURCE")/../../client")"

ip addr ls
SERV_IP=$(ip -4 -o addr show scope global  | awk '{print $4}' | sed -e 's:/.*::' | head -n1)
docker run -v $OVPN_DATA:/etc/openvpn --rm $IMG ovpn_genconfig -u udp://$SERV_IP

# nopass is insecure
docker run -v $OVPN_DATA:/etc/openvpn --rm -it -e "EASYRSA_BATCH=1" -e "EASYRSA_REQ_CN=Travis-CI Test CA" $IMG ovpn_initpki nopass

docker run -v $OVPN_DATA:/etc/openvpn --rm -it $IMG easyrsa build-client-full $CLIENT nopass

docker run -v $OVPN_DATA:/etc/openvpn --rm $IMG ovpn_getclient $CLIENT | tee $CLIENT_DIR/config.ovpn

docker run -v $OVPN_DATA:/etc/openvpn --rm $IMG ovpn_listclients | grep $CLIENT

#
# Fire up the server and setup a trap to always clean it up
#
trap "{ jobs -p | xargs -r kill; wait; }" EXIT
docker run --name "ovpn-test" -v $OVPN_DATA:/etc/openvpn --rm -e DEBUG --cap-add=NET_ADMIN $IMG &

for i in $(seq 10); do
    SERV_IP_INTERNAL=$(docker inspect --format '{{ .NetworkSettings.IPAddress }}' "ovpn-test" 2>/dev/null || true)
    test -n "$SERV_IP_INTERNAL" && break
    sleep 0.1
done
sed -i -e s:$SERV_IP:$SERV_IP_INTERNAL:g ${CLIENT_DIR}/config.ovpn

#
# Fire up a client in a container since openvpn is disallowed by Travis-CI
#
docker run --rm --cap-add=NET_ADMIN -e DEBUG --volume $CLIENT_DIR:/client $IMG /client/wait-for-connect.sh

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
