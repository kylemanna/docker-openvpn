#!/bin/bash
set -e

testAlias+=(
	[kylemanna/openvpn]='openvpn'
)

imageTests+=(
	[openvpn]='
		paranoid
        conf_options
        basic
        dual-proto
        otp
	'
)
