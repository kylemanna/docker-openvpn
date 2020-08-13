#!/bin/bash
set -e

SERV_IP=$(ip -4 -o addr show scope global  | awk '{print $4}' | sed -e 's:/.*::' | head -n1)

#
# Generate a simple configuration, returns nonzero on error
#
ovpn_genconfig -u udp://$SERV_IP 2>/dev/null

export EASYRSA_BATCH=1
export EASYRSA_REQ_CN="Travis-CI Test CA"

#
# Initialize the certificate PKI state, returns nonzero on error
#
ovpn_initpki nopass 2>/dev/null

#
# Test back-up
#
ovpn_copy_server_files
