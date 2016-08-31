#!/bin/bash
set -e

testAlias+=(
	[kylemanna/openvpn]='openvpn'
)

imageTests+=(
	[openvpn]='
		paranoid
	'
)
