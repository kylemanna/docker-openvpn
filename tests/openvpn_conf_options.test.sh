#!/bin/bash

OVPN_DATA=options-data

IMG=kylemanna/openvpn

# Function to fail
abort() { cat <<< "$@" 1>&2; exit 1; }

#
# Create a docker container with the config data
#
sudo docker run --name $OVPN_DATA -v /etc/openvpn busybox

#
# Generate openvpn.config file
#
read -d '' EXTRA_SERVER_CONF << EOF
management localhost 7505
max-clients 10
EOF

SERV_IP=$(ip -4 -o addr show scope global  | awk '{print $4}' | sed -e 's:/.*::' | head -n1)
sudo docker run --volumes-from $OVPN_DATA --rm $IMG ovpn_genconfig -u udp://$SERV_IP -f 1400 -e "$EXTRA_SERVER_CONF"

#
# grep for config lines from openvpn.conf
# add more tests for more configs as required
#

# 1. verb config
CONFIG_REQUIRED_VERB="verb 3"
CONFIG_MATCH_VERB=$(sudo docker run --rm -it --volumes-from $OVPN_DATA busybox grep verb /etc/openvpn/openvpn.conf)

# 2. fragment config
CONFIG_REQUIRED_FRAGMENT="fragment 1400"
CONFIG_MATCH_FRAGMENT=$(sudo docker run --rm -it --volumes-from $OVPN_DATA busybox grep fragment /etc/openvpn/openvpn.conf)

# 3. management config
CONFIG_REQUIRED_MANAGEMENT="^management localhost 7505"
CONFIG_MATCH_MANAGEMENT=$(sudo docker run --rm -it --volumes-from $OVPN_DATA busybox grep management /etc/openvpn/openvpn.conf)

# 4. max-clients config
CONFIG_REQUIRED_MAX_CLIENTS="^max-clients 10"
CONFIG_MATCH_MAX_CLIENTS=$(sudo docker run --rm -it --volumes-from $OVPN_DATA busybox grep max-clients /etc/openvpn/openvpn.conf)

#
# Clean up
#
# sudo docker rm -f $OVPN_DATA

#
# Tests
#

if [[ $CONFIG_MATCH_VERB =~ $CONFIG_REQUIRED_VERB ]]
then
  echo "==> Config match found: $CONFIG_REQUIRED_VERB == $CONFIG_MATCH_VERB"
else
  abort "==> Config match not found: $CONFIG_REQUIRED_VERB != $CONFIG_MATCH_VERB"
fi

if [[ $CONFIG_MATCH_FRAGMENT =~ $CONFIG_REQUIRED_FRAGMENT ]]
then
  echo "==> Config match found: $CONFIG_REQUIRED_FRAGMENT == $CONFIG_MATCH_FRAGMENT"
else
  abort "==> Config match not found: $CONFIG_REQUIRED_FRAGMENT != $CONFIG_MATCH_FRAGMENT"
fi

if [[ $CONFIG_MATCH_MANAGEMENT =~ $CONFIG_REQUIRED_MANAGEMENT ]]
then
  echo "==> Config match found: $CONFIG_REQUIRED_MANAGEMENT == $CONFIG_MATCH_MANAGEMENT"
else
  abort "==> Config match not found: $CONFIG_REQUIRED_MANAGEMENT != $CONFIG_MATCH_MANAGEMENT"
fi

if [[ $CONFIG_MATCH_MAX_CLIENTS =~ $CONFIG_REQUIRED_MAX_CLIENTS ]]
then
  echo "==> Config match found: $CONFIG_REQUIRED_MAX_CLIENTS == $CONFIG_MATCH_MAX_CLIENTS"
else
  abort "==> Config match not found: $CONFIG_REQUIRED_MAX_CLIENTS != $CONFIG_MATCH_MAX_CLIENTS"
fi
