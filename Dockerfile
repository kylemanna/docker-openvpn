
FROM alpine:latest# Original credit: https://github.com/kylemanna/docker-openvpn

# Testing: pamtester
RUN echo "http://dl-cdn.alpinelinux.org/alpine/edge/testing/" >> /etc/apk/repositories && \
    apk add --update openvpn iptables bash easy-rsa openvpn-auth-pam google-authenticator pamtester libqrencode py-pip curl && \
    ln -s /usr/share/easy-rsa/easyrsa /usr/local/bin && \
    rm -rf /tmp/* /var/tmp/* /var/cache/apk/* /var/cache/distfiles/*

# okta plugin requisites
ADD okta/requirements.txt /requirements.txt
RUN pip install -r /requirements.txt

# Needed by scripts
ENV OPENVPN=/etc/openvpn
ENV EASYRSA=/usr/share/easy-rsa \
    EASYRSA_CRL_DAYS=3650 \
    EASYRSA_PKI=$OPENVPN/pki

VOLUME ["/etc/openvpn"]

CMD ["ovpn_run"]

ADD ./bin /usr/local/bin
RUN chmod a+x /usr/local/bin/*

# Add support for OTP authentication using a PAM module
ADD ./otp/openvpn /etc/pam.d/

# Add support for Okta plugin
ADD okta/defer_simple.so /usr/lib/openvpn/plugins
ADD okta/okta_openvpn.py  /usr/lib/openvpn/plugins
ADD okta/okta_openvpn.ini  /usr/lib/openvpn/plugins
RUN chmod a+x /usr/lib/openvpn/plugins/*
