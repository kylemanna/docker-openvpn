#!/bin/bash

MY_PATH=$(readlink -f "$BASH_SOURCE")
MYDIR=$(dirname "$MY_PATH")
. "$MYDIR/defs"


username=$(parse_arg username)
[ "$?" != 0 -o -z "$username" ] && echo -e "$HEAD\n no valid user supplied!\n$END" && exit 1

CONFIG=$(ovpn_getclient "$username")
[ -z "$CONFIG" -o $? != 0 ] && echo -e "$HEAD error generating config for user $username\n$END" && exit 1

echo "Content-type: application/x-openvpn-profile"
echo "Content-Disposition:attachment; filename=$username.ovpn"
echo ""
echo "$CONFIG"

