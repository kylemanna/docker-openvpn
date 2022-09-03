import configparser
from configparser import MissingSectionHeaderError
import json
import logging.handlers
import os
import platform
import stat
import sys
import time
from urllib.parse import urlparse, urlunparse
import urllib3

version = "0.11.0-beta"
user_agent = (
    "OktaOpenVPN/{version} "
    "({system} {system_version}) "
    "{implementation}/{python_version}"
).format(
    version=version,
    system=platform.uname()[0],
    system_version=platform.uname()[2],
    implementation=platform.python_implementation(),
    python_version=platform.python_version()
)
log = logging.getLogger('okta_openvpn')
log.setLevel(logging.DEBUG)
syslog = logging.handlers.SysLogHandler()
syslog_fmt = "%(module)s-%(processName)s[%(process)d]: %(name)s: %(message)s"
syslog.setFormatter(logging.Formatter(syslog_fmt))
log.addHandler(syslog)

errlog = logging.StreamHandler()
errlog.setFormatter(logging.Formatter(syslog_fmt))
log.addHandler(errlog)

filelog = logging.FileHandler('/tmp/okta_openvpn.log')
filelog.setFormatter(logging.Formatter(syslog_fmt))
log.addHandler(filelog)


class ControlFilePermissionsError(Exception):
    "Raised when the control file or containing directory have bad permissions"
    pass


class OktaAPIAuth(object):
    def __init__(self,
                 okta_url,
                 okta_token,
                 username,
                 password,
                 client_ipaddr,
                 mfa_push_delay_secs=None,
                 mfa_push_max_retries=None):
        passcode_len = 6
        self.okta_url = None
        self.okta_token = okta_token
        self.username = username
        self.password = password
        self.client_ipaddr = client_ipaddr
        self.passcode = None
        self.okta_urlparse = urlparse(okta_url)
        self.mfa_push_delay_secs = mfa_push_delay_secs
        self.mfa_push_max_retries = mfa_push_max_retries
        url_new = (self.okta_urlparse.scheme,
                   self.okta_urlparse.netloc,
                   '', '', '', '')
        self.okta_url = urlunparse(url_new)
        if password and len(password) > passcode_len:
            last = password[-passcode_len:]
            if last.isdigit():
                self.passcode = last
                self.password = password[:-passcode_len]

    def okta_req(self, path, data):
        ssws = "SSWS {token}".format(token=self.okta_token)
        headers = {
            'user-agent': user_agent,
            'content-type': 'application/json',
            'accept': 'application/json',
            'authorization': ssws,
        }
        url = "{base}/api/v1{path}".format(base=self.okta_url, path=path)

        http = urllib3.PoolManager()
        req = http.request(
            'POST',
            url,
            headers=headers,
            body=json.dumps(data)
        )

        return json.loads(req.data)

    def preauth(self):
        path = "/authn"
        data = {
            'username': self.username,
            'password': self.password,
        }
        return self.okta_req(path, data)

    def doauth(self, fid, state_token):
        path = "/authn/factors/{fid}/verify".format(fid=fid)
        data = {
            'fid': fid,
            'stateToken': state_token,
            'passCode': self.passcode,
        }
        return self.okta_req(path, data)

    def auth(self):
        username = self.username
        password = self.password
        status = False
        rv = False

        invalid_username_or_password = (
                username is None or
                username == '' or
                password is None or
                password == '')
        if invalid_username_or_password:
            log.info("Missing username or password for user: %s (%s) - "
                     "Reported username may be 'None' due to this",
                     username,
                     self.client_ipaddr)
            return False

        if not self.passcode:
            log.info("No second factor found for username %s", username)

        log.debug("Authenticating username %s", username)
        try:
            rv = self.preauth()
        except Exception as s:
            log.error('Error connecting to the Okta API: %s', s)
            return False

        # Check for errors from Okta
        if 'errorCauses' in rv:
            msg = rv['errorSummary']
            log.info('User %s pre-authentication failed: %s',
                     self.username,
                     msg)
            return False
        elif 'status' in rv:
            status = rv['status']
        # Check authentication status from Okta
        if status == "SUCCESS":
            log.info('User %s authenticated without MFA', self.username)
            return True
        elif status == "MFA_ENROLL" or status == "MFA_ENROLL_ACTIVATE":
            log.info('User %s needs to enroll first', self.username)
            return False
        elif status == "MFA_REQUIRED" or status == "MFA_CHALLENGE":
            log.debug("User %s password validates, checking second factor",
                      self.username)
            res = None
            for factor in rv['_embedded']['factors']:
                log.info("factor: {}".format(factor))
                supported_factor_types = ["token:software:totp", "push"]
                if factor['factorType'] not in supported_factor_types:
                    continue
                fid = factor['id']
                state_token = rv['stateToken']
                try:
                    res = self.doauth(fid, state_token)
                    check_count = 0
                    fctr_rslt = 'factorResult'
                    while fctr_rslt in res and res[fctr_rslt] == 'WAITING':
                        print("Sleeping for {}".format(
                            self.mfa_push_delay_secs))
                        time.sleep(float(self.mfa_push_delay_secs))
                        res = self.doauth(fid, state_token)
                        check_count += 1
                        if check_count > self.mfa_push_max_retries:
                            log.info('User %s MFA push timed out' %
                                     self.username)
                            return False
                except Exception as e:
                    log.error('Unexpected error with the Okta API: %s', e)
                    return False
                if 'status' in res and res['status'] == 'SUCCESS':
                    log.info("User %s is now authenticated "
                             "with MFA via Okta API", self.username)
                    return True
            if 'errorCauses' in res:
                msg = res['errorCauses'][0]['errorSummary']
                log.debug(
                    'User %s MFA token authentication failed: %s',
                    self.username,
                    msg
                )
            return False
        else:
            log.info(
                "User %s is not allowed to authenticate: %s",
                self.username,
                status
            )
            return False


class OktaOpenVPNValidator(object):
    def __init__(self):
        self.cls = OktaAPIAuth
        self.username_trusted = "False"
        self.user_valid = "False"
        self.control_file = None
        self.site_config = {}
        self.config_file = 'okta_openvpn.ini'
        self.env = os.environ
        self.okta_config = {}
        self.username_suffix = "None"
        self.always_trust_username = "False"
        # These can be modified in the 'okta_openvpn.ini' file.
        # By default, we retry for 2 minutes:
        self.mfa_push_max_retries = "20"
        self.mfa_push_delay_secs = "3"

    def read_configuration_file(self):
        parser_defaults = {
            'AllowUntrustedUsers': self.always_trust_username,
            'UsernameSuffix': self.username_suffix,
            'MFAPushMaxRetries': self.mfa_push_max_retries,
            'MFAPushDelaySeconds': self.mfa_push_delay_secs,
        }
        if os.path.isfile(self.config_file):
            try:
                cfg = configparser.ConfigParser(defaults=parser_defaults)
                cfg.read(self.config_file)
                self.site_config = {
                    'okta_url': cfg.get('OktaAPI', 'Url'),
                    'okta_token': cfg.get('OktaAPI', 'Token'),
                    'mfa_push_max_retries': cfg.get('OktaAPI', 'MFAPushMaxRetries'),
                    'mfa_push_delay_secs': cfg.get('OktaAPI', 'MFAPushDelaySeconds'),
                }
                always_trust_username = cfg.get(
                    'OktaAPI',
                    'AllowUntrustedUsers'
                )
                if always_trust_username == 'True':
                    self.always_trust_username = True
                self.username_suffix = cfg.get('OktaAPI', 'UsernameSuffix')
                return True
            except MissingSectionHeaderError as e:
                log.debug(e)
        if 'okta_url' not in self.site_config and \
                'okta_token' not in self.site_config:
            log.critical("Failed to load config")
            return False

    def load_environment_variables(self):
        if 'okta_url' not in self.site_config:
            log.critical('OKTA_URL not defined in configuration')
            return False
        if 'okta_token' not in self.site_config:
            log.critical('OKTA_TOKEN not defined in configuration')
            return False
        # Taken from a validated VPN client-side SSL certificate
        username = self.env.get('common_name')
        password = self.env.get('password')
        client_ipaddr = self.env.get('untrusted_ip', '0.0.0.0')
        # Note:
        #   username_trusted is True if the username comes from a certificate
        #
        #   Meaning, if self.common_name is NOT set, but self.username IS,
        #   then self.username_trusted will be False
        if username is not None:
            self.username_trusted = True
        else:
            # This is set according to what the VPN client has sent us
            username = self.env.get('username')
        if self.always_trust_username:
            self.username_trusted = self.always_trust_username
        if self.username_suffix and '@' not in username:
            username = username + '@' + self.username_suffix
        self.control_file = self.env.get('auth_control_file')
        if self.control_file is None:
            log.info(
                "No control file found, "
                "if using a deferred plugin "
                "authentication will stall and fail."
            )
        self.okta_config = {
            'okta_url': self.site_config['okta_url'],
            'okta_token': self.site_config['okta_token'],
            'username': username,
            'password': password,
            'client_ipaddr': client_ipaddr,
        }
        for item in ['mfa_push_max_retries', 'mfa_push_delay_secs']:
            if item in self.site_config:
                self.okta_config[item] = self.site_config[item]
        assert_pin = self.env.get('assert_pin')
        if assert_pin:
            self.okta_config['assert_pinset'] = [assert_pin]

    def authenticate(self):
        if not self.username_trusted:
            log.warning(
                "Username %s is not trusted - failing",
                self.okta_config['username']
            )
            return False
        try:
            okta = self.cls(**self.okta_config)
            self.user_valid = okta.auth()
            return self.user_valid
        except Exception as exception:
            log.error(
                "User %s (%s) authentication failed, "
                "because %s() failed unexpectedly - %s",
                self.okta_config['username'],
                self.okta_config['client_ipaddr'],
                self.cls.__name__,
                exception
            )
        return False

    def check_control_file_permissions(self):
        file_mode = os.stat(self.control_file).st_mode
        if file_mode & stat.S_IWGRP or file_mode & stat.S_IWOTH:
            log.critical(
                'Refusing to authenticate. The file %s'
                ' must not be writable by non-owners.',
                self.control_file
            )
            raise ControlFilePermissionsError()
        dir_name = os.path.split(self.control_file)[0]
        dir_mode = os.stat(dir_name).st_mode
        if dir_mode & stat.S_IWGRP or dir_mode & stat.S_IWOTH:
            log.critical(
                'Refusing to authenticate.'
                ' The directory containing the file %s'
                ' must not be writable by non-owners.',
                self.control_file
            )
            raise ControlFilePermissionsError()

    def write_result_to_control_file(self):
        self.check_control_file_permissions()
        try:
            with open(self.control_file, 'w+') as f:
                if self.user_valid:
                    f.write('1')
                else:
                    f.write('0')
        except IOError:
            log.critical("Failed to write to OpenVPN control file '{}'".format(
                self.control_file
            ))

    def run(self):
        self.read_configuration_file()
        self.load_environment_variables()
        self.authenticate()
        self.write_result_to_control_file()


def return_error_code_for(validator):
    if validator.user_valid:
        sys.exit(0)
    else:
        sys.exit(1)


if __name__ == "__main__":
    validator = OktaOpenVPNValidator()
    validator.run()
    return_error_code_for(validator)
