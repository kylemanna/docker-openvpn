#!/bin/bash
set -ex
OVPN_DATA=basic-data-otp
CLIENT=travis-client
IMG=kylemanna/openvpn
OTP_USER=otp
# Function to fail
abort() { cat <<< "$@" 1>&2; exit 1; }

#
# Create a docker container with the config data
#
docker run --name $OVPN_DATA -v /etc/openvpn busybox

ip addr ls
SERV_IP=$(ip -4 -o addr show scope global  | awk '{print $4}' | sed -e 's:/.*::' | head -n1)
# Configure server with two factor authentication
docker run --volumes-from $OVPN_DATA --rm $IMG ovpn_genconfig -u udp://$SERV_IP -2

# nopass is insecure
docker run --volumes-from $OVPN_DATA --rm -it -e "EASYRSA_BATCH=1" -e "EASYRSA_REQ_CN=Travis-CI Test CA" $IMG ovpn_initpki nopass

docker run --volumes-from $OVPN_DATA --rm -it $IMG easyrsa build-client-full $CLIENT nopass

# Generate OTP credentials for user named test, should return QR code for test user
docker run --volumes-from $OVPN_DATA --rm -it $IMG ovpn_otp_user $OTP_USER | tee client/qrcode.txt
# Ensure a chart link is printed in client OTP configuration
grep 'https://www.google.com/chart' client/qrcode.txt || abort 'Link to chart not generated'
grep 'Your new secret key is:' client/qrcode.txt || abort 'Secret key is missing'
# Extract an emergency code from textual output, grepping for line and trimming spaces
OTP_TOKEN=$(grep -A1 'Your emergency scratch codes are' client/qrcode.txt | tail -1 | tr -d '[[:space:]]')
# Token should be present
if [ -z $OTP_TOKEN ]; then
  abort "QR Emergency Code not detected"
fi

# Store authentication credentials in config file and tell openvpn to use them
echo -e "$OTP_USER\n$OTP_TOKEN" > client/credentials.txt

# Override the auth-user-pass directive to use a credentials file
docker run --volumes-from $OVPN_DATA --rm $IMG ovpn_getclient $CLIENT | sed 's/auth-user-pass/auth-user-pass \/client\/credentials.txt/' | tee client/config.ovpn

#
# Fire up the server
#
sudo iptables -N DOCKER || echo 'Firewall already configured'
sudo iptables -I FORWARD -j DOCKER || echo 'Forward already configured'
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
