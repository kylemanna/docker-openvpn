#!/bin/bash
#
# OpenVPN + Docker Wrapper Script
#

OPENVPN="/etc/openvpn"

# Needed by easyrsa itself
export EASYRSA="/usr/local/share/easy-rsa/easyrsa3"
export EASYRSA_PKI="$OPENVPN/pki"
export EASYRSA_VARS_FILE="$OPENVPN/vars"

set -ex

abort() {
    echo "Error: $@"
    exit 1
}

if [ $# -lt 1 ]; then
    abort "No command specified"
fi

do_openvpn() {
    if [ ! -d /dev/net ]; then
        mkdir -p /dev/net
    fi
    if [ ! -c /dev/net/tun ]; then
        mknod /dev/net/tun c 10 200
    fi

    cd /etc/easyrsa
}

# Read arguments from command line
cmd=$1
shift

case "$cmd" in
    # nop for volume creation
    init)
        exit 0
        ;;
    easyrsa)
        cd $OPENVPN
        easyrsa "$@"
        ;;
    easyrsa-export-vars)
        if [ -f "$EASYRSA_VARS_FILE" ]; then
            cat "$EASYRSA_VARS_FILE"
        else
            cat "$EASYRSA/vars.example"
        fi
        ;;
    easyrsa-import-vars)
        cat > "$EASYRSA_VARS_FILE"
        ;;
    bash)
        $cmd "$@"
        ;;
    openvpn)
        do_openvpn "$@"
        ;;
    *)
        abort "Unknown cmd \"$cmd\""
        ;;
esac
