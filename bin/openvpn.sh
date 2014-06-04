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
    mkdir -p /dev/net
    if [ ! -c /dev/net/tun ]; then
        mknod /dev/net/tun c 10 200
    fi

    iptables -t nat -A POSTROUTING -s 192.168.255.0/24 -o eth0 -j MASQUERADE

    openvpn --config "$OPENVPN/udp1194.conf"
}

do_init() {
    cn=$1

    # Provides a sufficient warning before erasing pre-existing files
    easyrsa init-pki

    # For a CA key with a password, manually init; this is autopilot
    easyrsa build-ca nopass

    easyrsa gen-dh
    openvpn --genkey --secret $OPENVPN/pki/ta.key

    if [ -z "$cn"]; then
        #TODO: Handle IPv6 (when I get a VPS with IPv6)...
        ip4=$(dig +short myip.opendns.com @resolver1.opendns.com)
        ptr=$(dig +short -x $ip4 | sed -e 's:\.$::')

        [ -n "$ptr" ] && cn=$ptr || cn=$ip4
    fi

    echo "$cn" > $OPENVPN/servername

    easyrsa build-server-full $cn nopass

    [ -f "$OPENVPN/udp1194.conf" ] || cat > "$OPENVPN/udp1194.conf" <<EOF
server 192.168.255.128 255.255.255.128
verb 3
#duplicate-cn
key $EASYRSA_PKI/private/$cn.key
ca $EASYRSA_PKI/ca.crt
cert $EASYRSA_PKI/issued/$cn.crt
dh $EASYRSA_PKI/dh.pem
#tls-auth $EASYRSA_PKI/ta.key
#key-direction 0
keepalive 10 60
persist-key
persist-tun
push "dhcp-option DNS 8.8.4.4"
push "dhcp-option DNS 8.8.8.8"

proto udp
port 1194
dev tun1194
status /tmp/openvpn-status-1194.log
EOF
}

do_getclientconfig() {
    cn=$1

    [ -z "$cn" ] && abort "Common name not specified"

    if [ ! -f "$EASYRSA_PKI/private/$cn.key" ]; then
        easyrsa build-server-full $cn nopass
    fi

    servername=$(cat $OPENVPN/servername)

    cat <<EOF
client
nobind
dev tun
redirect-gateway def1

<key>
$(cat $EASYRSA_PKI/private/$cn.key)
</key>
<cert>
$(cat $EASYRSA_PKI/issued/$cn.crt)
</cert>
<ca>
$(cat $EASYRSA_PKI/ca.crt)
</ca>
<dh>
$(cat $EASYRSA_PKI/dh.pem)
</dh>
#<tls-auth>
#$(echo cat $EASYRSA_PKI/ta.key)
#</tls-auth>
#key-direction 1

<connection>
remote $servername 1194 udp
</connection>
EOF
}

# Read arguments from command line
cmd=$1
shift

case "$cmd" in
    # nop for volume creation
    init)
        do_init "$@"
        ;;
    easyrsa)
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
    getclientconfig)
        do_getclientconfig "$@"
        ;;
    openvpn)
        do_openvpn "$@"
        ;;
    log)
        tail -F /tmp/openvpn-status-1194.log
        ;;
    *)
        abort "Unknown cmd \"$cmd\""
        ;;
esac
