# Original credit: https://github.com/kylemanna/docker-openvpn

# Smallest base image
FROM alpine:latest

LABEL maintainer="Nanda Bhikkhu <nanda.bhikkhu@sasanarakkha.org>"

# Testing: pamtester
RUN echo "http://dl-cdn.alpinelinux.org/alpine/edge/testing/" >> /etc/apk/repositories && \
    apk add --update openvpn iptables bash easy-rsa openvpn-auth-pam google-authenticator pamtester libqrencode lighttpd lighttpd-mod_auth && \
    ln -s /usr/share/easy-rsa/easyrsa /usr/local/bin && \
    rm -rf /tmp/* /var/tmp/* /var/cache/apk/* /var/cache/distfiles/*

ADD ./lighttpd/htdocs/ /var/www/localhost/htdocs/
ADD ./lighttpd/config/* /etc/lighttpd/
RUN chown -R openvpn:openvpn /var/www/localhost/htdocs /etc/lighttpd /var/log/lighttpd

# Needed by scripts
ENV OPENVPN=/etc/openvpn
ENV EASYRSA=/usr/share/easy-rsa \
    EASYRSA_CRL_DAYS=3650 \
    EASYRSA_PKI=$OPENVPN/pki

VOLUME ["/etc/openvpn"]

# Internally uses port 1194/udp, remap using `docker run -p 443:1194/tcp`
EXPOSE 1194/udp
EXPOSE 443/tcp

CMD ["ovpn_run"]

ADD ./bin /usr/local/bin
RUN chmod a+x /usr/local/bin/*

# Add support for OTP authentication using a PAM module
ADD ./otp/openvpn /etc/pam.d/

# TODO: make sure here & in scripts that everything is done as "openvpn" user
