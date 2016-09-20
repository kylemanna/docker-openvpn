#!/bin/bash

# Function to fail
abort() { cat <<< "$@" 1>&2; exit 1; }


#
# Generate openvpn.config file
#
read -d '' MULTILINE_EXTRA_SERVER_CONF << EOF
management localhost 7505
max-clients 10
EOF

SERV_IP=$(ip -4 -o addr show scope global  | awk '{print $4}' | sed -e 's:/.*::' | head -n1)
ovpn_genconfig -u udp://$SERV_IP -f 1400 -e "$MULTILINE_EXTRA_SERVER_CONF" -e "duplicate-cn" -e "topology subnet"

#
# grep for config lines from openvpn.conf
# add more tests for more configs as required
#

# 1. verb config
CONFIG_REQUIRED_VERB="verb 3"
CONFIG_MATCH_VERB=$(busybox grep verb /etc/openvpn/openvpn.conf)

# 2. fragment config
CONFIG_REQUIRED_FRAGMENT="fragment 1400"
CONFIG_MATCH_FRAGMENT=$(busybox grep fragment /etc/openvpn/openvpn.conf)

## Tests for extra configs
# 3. management config
CONFIG_REQUIRED_MANAGEMENT="^management localhost 7505"
CONFIG_MATCH_MANAGEMENT=$(busybox grep management /etc/openvpn/openvpn.conf)

# 4. max-clients config
CONFIG_REQUIRED_MAX_CLIENTS="^max-clients 10"
CONFIG_MATCH_MAX_CLIENTS=$(busybox grep max-clients /etc/openvpn/openvpn.conf)

# 5. duplicate-cn config
CONFIG_REQUIRED_DUPCN="^duplicate-cn"
CONFIG_MATCH_DUPCN=$(busybox grep duplicate-cn /etc/openvpn/openvpn.conf)

# 6. topology config
CONFIG_REQUIRED_TOPOLOGY="^topology subnet"
CONFIG_MATCH_TOPOLOGY=$(busybox grep 'topology subnet' /etc/openvpn/openvpn.conf)

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

if [[ $CONFIG_MATCH_DUPCN =~ $CONFIG_REQUIRED_DUPCN ]]
then
  echo "==> Config match found: $CONFIG_REQUIRED_DUPCN == $CONFIG_MATCH_DUPCN"
else
  abort "==> Config match not found: $CONFIG_REQUIRED_DUPCN != $CONFIG_MATCH_DUPCN"
fi

if [[ $CONFIG_MATCH_TOPOLOGY =~ $CONFIG_REQUIRED_TOPOLOGY ]]
then
  echo "==> Config match found: $CONFIG_REQUIRED_TOPOLOGY == $CONFIG_MATCH_TOPOLOGY"
else
  abort "==> Config match not found: $CONFIG_REQUIRED_TOPOLOGY != $CONFIG_MATCH_TOPOLOGY"
fi
