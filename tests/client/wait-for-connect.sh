#!/bin/bash
set -ex
OPENVPN_CONFIG=${1:-/client/config.ovpn}

# Run in background, rely on bash for job management
openvpn --config "$OPENVPN_CONFIG" --management 127.0.0.1 9999 &

# Spin waiting for interface to exist signifying connection
timeout=10
for i in $(seq $timeout); do

    # Break when connected
    #echo state | busybox nc 127.0.0.1 9999 | grep -q "CONNECTED,SUCCESS" && break;

    # Bash magic for tcp sockets
    if exec 3<>/dev/tcp/127.0.0.1/9999; then
        # Consume all header input
        while read -t 0.1 <&3; do true; done
        echo "state" >&3
        read -t 1 <&3
        echo -n $REPLY | grep -q "CONNECTED,SUCCESS" && break || true
        exec 3>&-
    fi

    # Else sleep
    sleep 1
done

if [ $i -ge $timeout ]; then
    echo "Error starting OpenVPN, i=$i, exiting."
    exit 2;
fi

# The show is over.
kill %1
