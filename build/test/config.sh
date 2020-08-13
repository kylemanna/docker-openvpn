#!/bin/bash
set -e

testAlias+=(
	[kylemanna/openvpn]='openvpn'
)

imageTests+=(
	[openvpn]='
	paranoid
        conf_options
        client
        basic
        dual-proto
        otp
	iptables
	revocation
	'
)
