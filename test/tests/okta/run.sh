#!/bin/bash

# Create configuration file
OKTA_URL='https://mocked-okta-api.herokuapp.com'
OKTA_TOKEN='mocked-token-for-openvpn'
config_file='okta_openvpn.ini'
(echo "[OktaAPI]";
 echo "Url: ${OKTA_URL}";
 echo "Token: ${OKTA_TOKEN}") > $config_file

# Export variables that OpenVPN would be exporting in deferred mode
export common_name='user_MFA_REQUIRED@example.com'
export password='Testing1123456'
export untrusted_ip='10.0.0.1'
export auth_control_file="$(mktemp -t okta_openvpn.XXXXX)"
# $ echo -n | openssl s_client -connect mocked-okta-api.herokuapp.com:443 | openssl x509 -noout -pubkey | openssl rsa  -pubin -outform der | openssl dgst -sha256 -binary | base64

echo pwd
python ../../../okta/okta_openvpn.py

# Save the return value of the script
rv=$?
# Save the contents of the auth control file
acf_contents="$(cat $auth_control_file)"

# Cleanup
rm $auth_control_file
rm $config_file

if [ $rv -eq 0 ] && [ $acf_contents -eq 1 ]; then
    exit 0;
else
    exit 1;
fi
