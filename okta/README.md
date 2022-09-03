# Introduction

This is a plugin for OpenVPN Community Edition that allows OpenVPN to authenticate directly against Okta, with support for TOTP and Okta Verify Push factors (modified from: <https://github.com/jpf/okta-openvpn>).

At a high level, OpenVPN communicates with this plugin via a "control file", a temporary file that OpenVPN creates and polls periodically. 
If the plugin writes the ASCII character `1` into the control file, the user in question is allowed to log in to OpenVPN, if we write the ASCII character `0` into the file, the user is denied.

Below are the key parts of the code for `okta_openvpn.py`:

1.  Instantiate an OktaOpenVPNValidator object
2.  Load in configuration file and environment variables
3.  Authenticate the user
4.  Write result to the control file

## Instantiate an OktaOpenVPNValidator object

Occurs in `__main__()` method

## Load in configuration file and environment variables

`OktaOpenVPNValidator.run()` method of the OktaOpenVPNValidator class is what calls the methods which load the configuration file and environment variables, then calls the `authenticate()` method.

## Authenticate the user

see method: `OktaOpenVPNValidator.authenticate`

This code in turns calls the `OktaAPIAuth.auth()` method in the `OktaAPIAuth` class, which does the following:

-   Makes an authentication request to Okta, using the `preauth()` method.
-   Checks for errors
-   Log the user in if the reply was `SUCCESS`
-   Deny the user if the reply is `MFA_ENROLL` or `MFA_ENROLL_ACTIVATE`

If the response is `MFA_REQUIRED` or `MFA_CHALLENGE` then we do the following, for each factor that the user has registered:

-   Skip the factor if this code doesn't support that factor type.
-   Call `doauth()`, the second phase authentication, using the passcode (if we have one) and the `stateToken`.
    -   Keep running `doauth()` if the response type is `MFA_CHALLENGE` or `WAITING`.
-   If the response from `doauth()` is `SUCCESS` then log the user in.
-   Fail otherwise.

When returning errors, we prefer the summary strings in `errorCauses`, over those in `errorSummary` because the strings in `errorCauses` tend to be mroe descriptive. For more information, see the documentation for [Verify Security Question Factor](http://developer.okta.com/docs/api/resources/authn.html#verify-security-question-factor).

## Write result to the control file

see method: `OktaOpenVPNValidator.write_result_to_control_file()`

**Important:** The key thing to know about OpenVPN plugins (like this one) are that they communicate with OpenVPN through a **control file**. 
When OpenVPN calls a plugin, it first creates a temporary file, passes the name of the temporary file to the plugin, then waits for the temporary file to be written.

Because of how critical this control file is, we take the precaution of checking the permissions on the control file before writing anything to the file.
If the user authentication that happened previously was a success, we write a **1** to the file. Otherwise, we write a **0** to the file, denying the user by default.

# Setup

## Make sure that OpenVPN has a temporary directory

In OpenVPN, the "deferred plugin" model requires the use of temporary files to work.
located within an EFS volume in directory `/etc/openvpn/tmp` with directory permissions set to `744`

## Configure the Okta OpenVPN plugin

The Okta OpenVPN plugin is configured via the `okta_openvpn.ini` file. 
This file was manually configured for Knock's Okta instance.

## Configure OpenVPN to use the C Plugin

To configure OpenVPN to call the Okta plugin, added following lines to the OpenVPN `server.conf` configuration file:
```ini
plugin /usr/lib/openvpn/plugins/defer_simple.so /usr/lib/openvpn/plugins/okta_openvpn.py
tmp-dir "/etc/openvpn/tmp"
```
