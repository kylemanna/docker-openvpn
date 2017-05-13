#!/bin/bash

# Function to fail
abort() { cat <<< "$@" 1>&2; exit 1; }


#
# Generate openvpn.config file
#
SERV_IP=$(ip -4 -o addr show scope global  | awk '{print $4}' | sed -e 's:/.*::' | head -n1)

ovpn_genconfig \
    -u udp://$SERV_IP \
    -m 1337 \


EASYRSA_BATCH=1 EASYRSA_REQ_CN="Travis-CI Test CA" ovpn_initpki nopass

easyrsa build-client-full test1 nopass 2>/dev/null

TEST1_OVPN="/etc/openvpn/test1.ovpn"
ovpn_getclient test1 > "${TEST1_OVPN}"

# Check a config (haystack) for a given line (needle) exit with error if not found.
test-client-config() {

    local needle="${1}"

    busybox grep -q "${needle}" "${TEST1_OVPN}"
    if [ $? -ne 0 ]; then
        abort "==> Config match not found: ${needle}"
    fi
}

#
# Test cases
#

# Test 1: Check MTU
test-client-config "^tun-mtu\s+1337"
