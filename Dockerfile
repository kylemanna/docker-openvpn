# Original credit: https://github.com/kylemanna/docker-openvpn

# Smallest base image
FROM alpine:latest

LABEL maintainer="Nanda Bhikkhu <nanda.bhikkhu@sasanarakkha.org>"

# Testing: pamtester
RUN echo "http://dl-cdn.alpinelinux.org/alpine/edge/testing/" >> /etc/apk/repositories && \
    apk add --update openvpn iptables bash easy-rsa openvpn-auth-pam google-authenticator pamtester libqrencode lighttpd lighttpd-mod_auth && \
    ln -s /usr/share/easy-rsa/easyrsa /usr/local/bin && \
    rm -rf /tmp/* /var/tmp/* /var/cache/apk/* /var/cache/distfiles/*

# Needed by scripts
ENV OPENVPN=/etc/openvpn
ENV EASYRSA=/usr/share/easy-rsa \
    EASYRSA_CRL_DAYS=3650 \
    EASYRSA_PKI=$OPENVPN/pki \
    OVPN_USER=openvpn \
    OVPN_GROUP=openvpn

ADD ./lighttpd/htdocs/ /var/www/localhost/htdocs/
ADD ./lighttpd/config/* /etc/lighttpd/
RUN OPENVPN=$(echo $OPENVPN | sed -e 's/\//\\\//g') && sed -i /etc/lighttpd/lighttpd.conf -e 's/server\.username.*/server.username\ =\ "'$OVPN_USER'"/' \
		-e 's/server\.groupname.*/server.groupname\ =\ "'$OVPN_GROUP'"/' \
		-e 's/^var\.ovpndir.*$/var.ovpndir\ =\ "'${OPENVPN}'"/' && \
	chown -R ${OVPN_USER}:${OVPN_GROUP} /var/www/localhost/htdocs /etc/lighttpd /var/log/lighttpd 

ADD ./bin /usr/local/bin
RUN chmod 755 /usr/local/bin/* && chown root:${OVPN_GROUP} /usr/local/bin/*

# Add support for OTP authentication using a PAM module
ADD ./otp/openvpn /etc/pam.d/

VOLUME ["/etc/openvpn"]
VOLUME ["/var/log"]

# Internally uses port 1194/udp, remap using `docker run -p 443:1194/tcp`
EXPOSE 1194/udp
EXPOSE 443/tcp

CMD ["ovpn_run"]
USER $OVPN_USER:$OVPN_GROUP

