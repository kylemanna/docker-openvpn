#!/bin/bash

SERV_IP=$(ip -4 -o addr show scope global  | awk '{print $4}' | sed -e 's:/.*::' | head -n1)
SERVER_CONF="/etc/openvpn/openvpn.conf"
TEST1_OVPN="/etc/openvpn/test1.ovpn"

# Function to fail
abort() { cat <<< "$@" 1>&2; exit 1; }

# Check a config (haystack) for a given line (needle) exit with error if not found.
test_config() {

    local needle="${2}"
    local file="${1}"

    busybox grep -q "${needle}" "${file}"
    if [ $? -ne 0 ]; then
        abort "==> Config match not found: ${needle}"
    fi
}

# Check a config (haystack) for absence of given line (needle) exit with error
# if found.
test_not_config() {

    local needle="${2}"
    local file="${1}"

    busybox grep -vq "${needle}" "${file}"
    if [ $? -ne 0 ]; then
        abort "==> Config match found: ${needle}"
    fi
}


#
# Generate openvpn.config file
#
read -d '' MULTILINE_EXTRA_SERVER_CONF << EOF
management localhost 7505
max-clients 10
EOF

ovpn_genconfig \
    -u udp://$SERV_IP \
    -f 1400 \
    -k '60 300' \
    -e "$MULTILINE_EXTRA_SERVER_CONF" \
    -e 'duplicate-cn' \
    -e 'topology subnet' \
    -p 'route 172.22.22.0 255.255.255.0' \


#
# Simple test cases
#

# 1. verb config
test_config "${SERVER_CONF}" "^verb\s\+3"

# 2. fragment config
test_config "${SERVER_CONF}" "^fragment\s\+1400"

## Tests for extra configs
# 3. management config
test_config "${SERVER_CONF}" "^management\s\+localhost\s\+7505"

# 4. max-clients config
test_config "${SERVER_CONF}" "^max-clients\s\+10"

# 5. duplicate-cn config
test_config "${SERVER_CONF}" "^duplicate-cn"

# 6. topology config
test_config "${SERVER_CONF}" "^topology\s\+subnet"

## Tests for push config
# 7. push route
test_config "${SERVER_CONF}" '^push\s\+"route\s\+172.22.22.0\s\+255.255.255.0"'

## Test for default
# 8. Should see default route if none provided
test_config "${SERVER_CONF}" "^route\s\+192.168.254.0\s\+255.255.255.0"

# 9. Should see a push of 'block-outside-dns' by default
test_config "${SERVER_CONF}" '^push\s\+"block-outside-dns"'

# 10. Should see a push of 'dhcp-option DNS' by default
test_config "${SERVER_CONF}" '^push\s\+"dhcp-option\s\+DNS\s\+8.8.8.8"'
test_config "${SERVER_CONF}" '^push\s\+"dhcp-option\s\+DNS\s\+8.8.4.4"'

## Test for keepalive
# 11. keepalive config
test_config "${SERVER_CONF}" '^keepalive\s\+60\s\+300'


#
# More elaborate route tests
#

ovpn_genconfig -u udp://$SERV_IP -r "172.33.33.0/24" -r "172.34.34.0/24"

test_config "${SERVER_CONF}" "^route\s\+172.33.33.0\s\+255.255.255.0"
test_config "${SERVER_CONF}" "^route\s\+172.34.34.0\s\+255.255.255.0"


#
# Block outside DNS test
#

ovpn_genconfig -u udp://$SERV_IP -b

test_not_config "${SERVER_CONF}" '^push "block-outside-dns"'
cat ${SERVER_CONF} >&1
