#!/bin/bash

print_user_table()
{
# 	name,begin,end,status
# ariya,Jul 21 11:15:44 2020 GMT,Jul  6 11:15:44 2023 GMT,VALID

	echo '<form method="post"><table>'

	echo '<tr><th colspan=5>Existing users</th></tr>
	<tr><th>Username</th><th>Valid from</th><th>Valid to</th><th>Status</th><th>Config</th></tr>'

	ovpn_listclients | tail -n +2 | while IFS=, read -r name valid_from valid_to status; do
		
		echo "<tr><td>$name</td><td>$valid_from</td><td>$valid_to</td><td>$status</td>
			<td><a href=\"user_config.cgi?username=$name\">DOWNLOAD_CONFIG</a></td>
		      </tr>"
	done
	
	echo '</table>
		<br/><br/>
		<div id="popup">
			<table
			<tr><th colspan=2>User management</th></tr>

			<tr><td>Action</td>
			<td><select id="action" name="action">
				<option value="add">add</option>
				<option value="del">delete</option>
				<option value="renew">renew</option>
			</select></td>
			</tr>

			<tr><td>Username</td>
			<td><input type="text" id="username" name="username"/></td>
			</tr>

			<tr><td>CA passphrase*</td>
			<td><input type="password" id="capassphrase" name="capassphrase"/></td>
			</tr>

			<tr><td colspan=2><button type="submit" onclick="done()">Do it!</button></td></tr>
			</table>
		</div>
		<div>* Global passphrase for the user management, can be found in keepassxc pwd db</div>
		<br/>

		<div><a href="web_password.cgi">Openvpn admin web (this page) access management</a>

	</form>'
}


MY_PATH=$(readlink -f "$BASH_SOURCE")
MYDIR=$(dirname "$MY_PATH")
. "$MYDIR/defs"

read -t 5 POST_STRING

action=$(parse_post_arg "action")
username=$(parse_post_arg "username")
capassphrase=$(parse_post_arg "capassphrase")
export EASYRSA_PASSIN="pass:$capassphrase"
export EASYRSA_BATCH=1
case "$action" in
	del) echo "$capassphrase" | ovpn_revokeclient "$username" remove 1>&2 && message="<h2>User $username removed</h2>";;
	add) echo "$capassphrase" | easyrsa build-client-full "$username" nopass 1>&2  && message="<h2>Succesfully created user $username<h2>";;
	renew) echo "$capassphrase" | easyrsa renew "$username" nopass 1>&2 && message="<h2>Certificate of user $username renewed</h2>";;
esac

echo "$HEAD"

print_user_table
echo "$message"

echo "$END"
