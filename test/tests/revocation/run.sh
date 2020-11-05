#!/bin/bash
set -e

[ -n "${DEBUG+x}" ] && set -x

OVPN_DATA="ovpn-revoke-test-data"
CLIENT1="travis-client1"
CLIENT2="travis-client2"
IMG="kylemanna/openvpn"
NAME="ovpn-revoke-test"
CLIENT_DIR="$(readlink -f "$(dirname "$BASH_SOURCE")/../../client")"
SERV_IP="$(ip -4 -o addr show scope global  | awk '{print $4}' | sed -e 's:/.*::' | head -n1)"

#
# Initialize openvpn configuration and pki.
#
docker volume create --name $OVPN_DATA
docker run --rm -v $OVPN_DATA:/etc/openvpn $IMG ovpn_genconfig -u udp://$SERV_IP
docker run --rm -v $OVPN_DATA:/etc/openvpn -it -e "EASYRSA_BATCH=1" -e "EASYRSA_REQ_CN=Travis-CI Test CA" $IMG ovpn_initpki nopass

# Register clean-up function
function finish {
    # Stop the server and clean up
    docker rm -f $NAME
    docker volume rm $OVPN_DATA
    jobs -p | xargs -r kill
    wait
}
trap finish EXIT

# Put the server in the background
docker run -d -v $OVPN_DATA:/etc/openvpn --cap-add=NET_ADMIN --name $NAME $IMG

#
# Test that easy_rsa generate CRLs with 'next publish' set to 3650 days.
#
crl_next_update="$(docker exec $NAME bash -c "openssl crl -nextupdate -noout -in \$EASYRSA_PKI/crl.pem | cut -d'=' -f2 | tr -d 'GMT'")"
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
docker exec -it $NAME bash -c "echo 'yes' | ovpn_revokeclient $CLIENT1"

# Determine IP address of container running daemon and update config
for i in $(seq 10); do
    SERV_IP_INTERNAL=$(docker inspect --format '{{ .NetworkSettings.IPAddress }}' "$NAME" 2>/dev/null || true)
    test -n "$SERV_IP_INTERNAL" && break
    sleep 0.1
done
sed -i -e s:$SERV_IP:$SERV_IP_INTERNAL:g $CLIENT_DIR/config.ovpn

#
# Test that openvpn client can't connect using $CLIENT1 config.
#
if docker run --rm -v $CLIENT_DIR:/client --cap-add=NET_ADMIN -e DEBUG $IMG /client/wait-for-connect.sh; then
    echo "Client was able to connect after revocation test #1." >&2
    exit 2
fi

#
# Generate and revoke a second client certificate using $CLIENT2 as CN, then test for failed client connection.
#
docker exec -it $NAME easyrsa build-client-full $CLIENT2 nopass
docker exec -it $NAME ovpn_getclient $CLIENT2 > $CLIENT_DIR/config.ovpn
docker exec -it $NAME bash -c "echo 'yes' | ovpn_revokeclient $CLIENT2"

# Determine IP address of container running daemon and update config
for i in $(seq 10); do
    SERV_IP_INTERNAL=$(docker inspect --format '{{ .NetworkSettings.IPAddress }}' "$NAME" 2>/dev/null || true)
    test -n "$SERV_IP_INTERNAL" && break
    sleep 0.1
done

if docker run --rm -v $CLIENT_DIR:/client --cap-add=NET_ADMIN -e DEBUG $IMG /client/wait-for-connect.sh; then
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
if docker run --rm -v $CLIENT_DIR:/client --cap-add=NET_ADMIN -e DEBUG $IMG /client/wait-for-connect.sh; then
    echo "Client was able to connect after revocation test #3." >&2
    exit 2
fi

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
