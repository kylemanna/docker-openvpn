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
ovpn_genconfig -u udp://$SERV_IP -f 1400 -k '60 300' -e "$MULTILINE_EXTRA_SERVER_CONF" -e 'duplicate-cn' -e 'topology subnet' -p 'route 172.22.22.0 255.255.255.0'

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

## Tests for push config
# 7. push route
CONFIG_REQUIRED_PUSH_ROUTE="^push route 172.22.22.0 255.255.255.0"
CONFIG_MATCH_PUSH_ROUTE=$(busybox grep 'push route 172.22.22.0 255.255.255.0' /etc/openvpn/openvpn.conf)

## Test for default
# 8. Should see default route if none provided
CONFIG_REQUIRED_DEFAULT_ROUTE="^route 192.168.254.0 255.255.255.0"
CONFIG_MATCH_DEFAULT_ROUTE=$(busybox grep 'route 192.168.254.0 255.255.255.0' /etc/openvpn/openvpn.conf)

# 9. Should see a push of 'block-outside-dns' by default
CONFIG_REQUIRED_BLOCK_OUTSIDE_DNS="^push block-outside-dns"
CONFIG_MATCH_BLOCK_OUTSIDE_DNS=$(busybox grep 'push block-outside-dns' /etc/openvpn/openvpn.conf)

# 10. Should see a push of 'dhcp-option DNS' by default
CONFIG_REQUIRED_DEFAULT_DNS_1="^push dhcp-option DNS 8.8.8.8"
CONFIG_MATCH_DEFAULT_DNS_1=$(busybox grep 'push dhcp-option DNS 8.8.8.8' /etc/openvpn/openvpn.conf)
CONFIG_REQUIRED_DEFAULT_DNS_2="^push dhcp-option DNS 8.8.4.4"
CONFIG_MATCH_DEFAULT_DNS_2=$(busybox grep 'push dhcp-option DNS 8.8.4.4' /etc/openvpn/openvpn.conf)

## Test for keepalive
# 11. keepalive config
CONFIG_REQUIRED_KEEPALIVE="^keepalive 60 300"
CONFIG_MATCH_KEEPALIVE=$(busybox grep keepalive /etc/openvpn/openvpn.conf)


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

if [[ $CONFIG_MATCH_PUSH_ROUTE =~ $CONFIG_REQUIRED_PUSH_ROUTE ]]
then
  echo "==> Config match found: $CONFIG_REQUIRED_PUSH_ROUTE == $CONFIG_MATCH_PUSH_ROUTE"
else
  abort "==> Config match not found: $CONFIG_REQUIRED_PUSH_ROUTE != $CONFIG_MATCH_PUSH_ROUTE"
fi

if [[ $CONFIG_MATCH_DEFAULT_ROUTE =~ $CONFIG_REQUIRED_DEFAULT_ROUTE ]]
then
  echo "==> Config match found: $CONFIG_REQUIRED_DEFAULT_ROUTE == $CONFIG_MATCH_DEFAULT_ROUTE"
else
  abort "==> Config match not found: $CONFIG_REQUIRED_DEFAULT_ROUTE != $CONFIG_MATCH_DEFAULT_ROUTE"
fi

if [[ $CONFIG_MATCH_BLOCK_OUTSIDE_DNS =~ $CONFIG_REQUIRED_BLOCK_OUTSIDE_DNS ]]
then
  echo "==> Config match found: $CONFIG_REQUIRED_BLOCK_OUTSIDE_DNS == $CONFIG_MATCH_BLOCK_OUTSIDE_DNS"
else
  abort "==> Config match not found: $CONFIG_REQUIRED_BLOCK_OUTSIDE_DNS != $CONFIG_MATCH_BLOCK_OUTSIDE_DNS"
fi

if [[ $CONFIG_MATCH_DEFAULT_DNS_1 =~ $CONFIG_REQUIRED_DEFAULT_DNS_1 ]]
then
  echo "==> Config match found: $CONFIG_REQUIRED_DEFAULT_DNS_1 == $CONFIG_MATCH_DEFAULT_DNS_1"
else
  abort "==> Config match not found: $CONFIG_REQUIRED_DEFAULT_DNS_1 != $CONFIG_MATCH_DEFAULT_DNS_1"
fi

if [[ $CONFIG_MATCH_DEFAULT_DNS_2 =~ $CONFIG_REQUIRED_DEFAULT_DNS_2 ]]
then
  echo "==> Config match found: $CONFIG_REQUIRED_DEFAULT_DNS_2 == $CONFIG_MATCH_DEFAULT_DNS_2"
else
  abort "==> Config match not found: $CONFIG_REQUIRED_DEFAULT_DNS_2 != $CONFIG_MATCH_DEFAULT_DNS_2"
fi

if [[ $CONFIG_MATCH_KEEPALIVE =~ $CONFIG_REQUIRED_KEEPALIVE ]]
then
  echo "==> Config match found: $CONFIG_REQUIRED_KEEPALIVE == $CONFIG_MATCH_KEEPALIVE"
else
  abort "==> Config match not found: $CONFIG_REQUIRED_KEEPALIVE != $CONFIG_MATCH_KEEPALIVE"
fi

SERV_IP=$(ip -4 -o addr show scope global  | awk '{print $4}' | sed -e 's:/.*::' | head -n1)
ovpn_genconfig -u udp://$SERV_IP -r "172.33.33.0/24" -r "172.34.34.0/24"

CONFIG_REQUIRED_ROUTE_1="^route 172.33.33.0 255.255.255.0"
CONFIG_MATCH_ROUTE_1=$(busybox grep 'route 172.33.33.0 255.255.255.0' /etc/openvpn/openvpn.conf)

CONFIG_REQUIRED_ROUTE_2="^route 172.34.34.0 255.255.255.0"
CONFIG_MATCH_ROUTE_2=$(busybox grep 'route 172.34.34.0 255.255.255.0' /etc/openvpn/openvpn.conf)

if [[ $CONFIG_MATCH_ROUTE_1 =~ $CONFIG_REQUIRED_ROUTE_1 ]]
then
  echo "==> Config match found: $CONFIG_REQUIRED_ROUTE_1 == $CONFIG_MATCH_ROUTE_1"
else
  abort "==> Config match not found: $CONFIG_REQUIRED_ROUTE_1 != $CONFIG_MATCH_ROUTE_1"
fi

if [[ $CONFIG_MATCH_ROUTE_2 =~ $CONFIG_REQUIRED_ROUTE_2 ]]
then
  echo "==> Config match found: $CONFIG_REQUIRED_ROUTE_2 == $CONFIG_MATCH_ROUTE_2"
else
  abort "==> Config match not found: $CONFIG_REQUIRED_ROUTE_2 != $CONFIG_MATCH_ROUTE_2"
fi

SERV_IP=$(ip -4 -o addr show scope global  | awk '{print $4}' | sed -e 's:/.*::' | head -n1)
ovpn_genconfig -u udp://$SERV_IP -b

if busybox grep -v 'block-outside-dns' /etc/openvpn/openvpn.conf
then
  echo "==> Config '-b' Succesfully remove the 'block-outside-dns' option"
else
  abort "==> Config '-b' given, but 'block-outside-dns' option is still present in configuration"
fi


# Test generated client config

# gen udp client with tcp fallback
ovpn_genconfig -u udp://$SERV_IP -E "remote $SERV_IP 443 tcp" -E "remote vpn.example.com 443 tcp"
# nopass is insecure
EASYRSA_BATCH=1 EASYRSA_REQ_CN="Travis-CI Test CA" ovpn_initpki nopass
easyrsa build-client-full client-fallback nopass
ovpn_getclient client-fallback | tee /etc/openvpn/config-fallback.ovpn

CONFIG_REQUIRED_TCP_REMOTE="^remote $SERV_IP 443 tcp"
CONFIG_MATCH_TCP_REMOTE=$(busybox grep "remote $SERV_IP 443 tcp" /etc/openvpn/config-fallback.ovpn)

CONFIG_REQUIRED_TCP_REMOTE_2="^remote vpn.example.com 443 tcp"
CONFIG_MATCH_TCP_REMOTE_2=$(busybox grep "remote vpn.example.com 443 tcp" /etc/openvpn/config-fallback.ovpn)

if [[ $CONFIG_MATCH_TCP_REMOTE =~ $CONFIG_REQUIRED_TCP_REMOTE ]]
then
  echo "==> Config match found: $CONFIG_REQUIRED_TCP_REMOTE == $CONFIG_MATCH_TCP_REMOTE"
else
  abort "==> Config match not found: $CONFIG_REQUIRED_TCP_REMOTE != $CONFIG_MATCH_TCP_REMOTE"
fi

if [[ $CONFIG_MATCH_TCP_REMOTE_2 =~ $CONFIG_REQUIRED_TCP_REMOTE_2 ]]
then
  echo "==> Config match found: $CONFIG_REQUIRED_TCP_REMOTE_2 == $CONFIG_MATCH_TCP_REMOTE_2"
else
  abort "==> Config match not found: $CONFIG_REQUIRED_TCP_REMOTE_2 != $CONFIG_MATCH_TCP_REMOTE_2"
fi

# Test non-defroute config

SERV_IP=$(ip -4 -o addr show scope global  | awk '{print $4}' | sed -e 's:/.*::' | head -n1)
ovpn_genconfig -d -u udp://$SERV_IP -r "172.33.33.0/24" -r "172.34.34.0/24"
# nopass is insecure
EASYRSA_BATCH=1 EASYRSA_REQ_CN="Travis-CI Test CA" ovpn_initpki nopass
easyrsa build-client-full client-fallback nopass
ovpn_getclient client-fallback | tee /etc/openvpn/config-fallback.ovpn

CONFIG_REQUIRED_BLOCK_OUTSIDE_DNS=""
CONFIG_MATCH_BLOCK_OUTSIDE_DNS=$(busybox grep 'push block-outside-dns' /etc/openvpn/openvpn.conf)

if [[ $CONFIG_MATCH_BLOCK_OUTSIDE_DNS =~ $CONFIG_REQUIRED_BLOCK_OUTSIDE_DNS ]]
then
  echo "==> Config match found: $CONFIG_REQUIRED_BLOCK_OUTSIDE_DNS == $CONFIG_MATCH_BLOCK_OUTSIDE_DNS"
else
  abort "==> Config match not found: $CONFIG_REQUIRED_BLOCK_OUTSIDE_DNS != $CONFIG_MATCH_BLOCK_OUTSIDE_DNS"
fi

CONFIG_REQUIRED_REDIRECT_GATEWAY=""
CONFIG_MATCH_REDIRECT_GATEWAY=$(busybox grep "redirect-gateway def1" /etc/openvpn/config-fallback.ovpn)

if [[ $CONFIG_MATCH_REDIRECT_GATEWAY =~ $CONFIG_REQUIRED_REDIRECT_GATEWAY ]]
then
  echo "==> Config match found: $CONFIG_REQUIRED_REDIRECT_GATEWAY == $CONFIG_MATCH_REDIRECT_GATEWAY"
else
  abort "==> Config match not found: $CONFIG_REQUIRED_REDIRECT_GATEWAY != $CONFIG_MATCH_REDIRECT_GATEWAY"
fi
