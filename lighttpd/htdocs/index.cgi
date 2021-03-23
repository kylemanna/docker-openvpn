#!/bin/bash



print_user_table()
{
# 	name,begin,end,status
# ariya,Jul 21 11:15:44 2020 GMT,Jul  6 11:15:44 2023 GMT,VALID

	echo '<table>'
	echo '<tr><th>name</th><th>valid from</th><th>valid to</th><th>status</th><th>actions</th></tr>'

	ovpn_listclients | tail -n +2 | while IFS=, read -r name valid_from valid_to status; do
		echo "<tr><td>$name</td><td>$valid_from</td><td>$valid_to</td><td>$status</td><td>DELETE RENEW DOWNLOAD_CONFIG</td></tr>"
	done

	echo '</table>'
}


MY_PATH=$(readlink -f "$BASH_SOURCE")
MYDIR=$(dirname "$MY_PATH")
. "$MYDIR/defs"

echo "$HEAD"

print_user_table

echo "$END"
