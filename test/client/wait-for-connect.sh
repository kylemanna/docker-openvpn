#!/bin/bash
set -e

[ -n "${DEBUG+x}" ] && set -x

OPENVPN_CONFIG=${1:-/client/config.ovpn}

# For some reason privileged mode creates the char device and cap-add=NET_ADMIN doesn't
mkdir -p /dev/net
if [ ! -c /dev/net/tun ]; then
    mknod /dev/net/tun c 10 200
fi

# Run in background using bash job management, setup trap to clean-up
trap "{ jobs -p | xargs -r kill; wait; }" EXIT
openvpn --config "$OPENVPN_CONFIG" --management 127.0.0.1 9999 &

# Spin waiting for interface to exist signifying connection
timeout=10
for i in $(seq $timeout); do
    # Allow to start-up
    sleep 0.5

    # Use bash magic to open tcp socket on fd 3 and break when successful
    exec 3<>/dev/tcp/127.0.0.1/9999 && break
done

if [ $i -ge $timeout ]; then
    echo "Error connecting to OpenVPN mgmt interface, i=$i, exiting."
    exit 2
fi

# Consume all header input and echo, look for errors here
while read -t 0.1 <&3; do echo $REPLY; done

# Request state over mgmt interface
timeout=10
for i in $(seq $timeout); do
    echo "state" >&3
    state=$(head -n1 <&3)
    echo -n "$state" | grep -q 'CONNECTED,SUCCESS' && break
    sleep 1
done

if [ $i -ge $timeout ]; then
    echo "Error connecting to OpenVPN, i=$i, exiting."
    exit 3
fi

exec 3>&-
