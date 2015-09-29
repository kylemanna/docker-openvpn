#!/bin/bash

set -ex

IMG=${IMG:-kylemanna/openvpn}

temp=$(mktemp -d)

pushd $temp

SERV_IP=$(ip -4 -o addr show scope global  | awk '{print $4}' | sed -e 's:/.*::' | head -n1)

docker run --net=none --rm -t -i -v $PWD:/etc/openvpn $IMG ovpn_genconfig -u udp://$SERV_IP

docker run --net=none --rm -t -i -v $PWD:/etc/openvpn -e "EASYRSA_BATCH=1" -e "EASYRSA_REQ_CN=Travis-CI Test CA" kylemanna/openvpn ovpn_initpki nopass

docker run --net=none --rm -t -i -v $PWD:/etc/openvpn $IMG ovpn_copy_server_files

popd
# Can't delete the temp directory as docker creates some files as root.
# Just let it die with the test instance.
rm -rf $temp || true
