#!/bin/bash


MY_PATH=$(readlink -f "$BASH_SOURCE")
MYDIR=$(dirname "$MY_PATH")
. "$MYDIR/defs"
db="$OPENVPN/http/htpasswd"

read -t 5 POST_STRING

username=$(parse_post_arg "username")
pass=$(parse_post_arg "password")

res=-1
if [ -n "$username" ]; then
	if [ -z "$pass" ]; then
		openssl-htpasswd -D  "$db" "$username"
		res=$?
	else
		openssl-htpasswd "$db" "$username" "$pass"
		res=$?
	fi
fi

echo "$HEAD"
echo '
<h1>Openvpn admin web access config</h1>
<h2>Current user list</h2>
<p>
<ul>
'
cat "$db" | cut -d ':' -f 1 | while read un; do	echo "<li>$un</li>"; done
echo '</ul></p>
<h2>User Management</h2>
<p>
<form method="post">
                    <table
                        <tr><td>Username</td>
                        <td><input type="text" id="username" name="username"/></td>
                        </tr>

                        <tr><td>Password*</td>
                        <td><input type="password" id="password" name="password"/></td>
                        </tr>

                        <tr><td colspan=2><button type="submit" onclick="done()">Set it!</button></td></tr>
                        </table>

</form>
</p>
<div>*use empty password to delete user</div>'

if [ "$res" != '-1' ]; then
	[ "$res" = 0 ] && echo "<h2>Success</h2>" || echo "<h2>Failed</h2>"
	echo "<p>(modyfiing user $username)</p>"
fi

echo "$END"

