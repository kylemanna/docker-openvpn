# Original credit: https://github.com/jpetazzo/dockvpn

# Smallest base image
FROM alpine:3.4

MAINTAINER Kyle Manna <kyle@kylemanna.com>

RUN echo "http://dl-4.alpinelinux.org/alpine/edge/testing/" >> /etc/apk/repositories && \
    apk add --update openvpn iptables bash easy-rsa openvpn-auth-pam pamtester && \
    ln -s /usr/share/easy-rsa/easyrsa /usr/local/bin && \
    rm -rf /tmp/* /var/tmp/* /var/cache/apk/* /var/cache/distfiles/*

COPY alpine /tmp/local
RUN adduser -D -G abuild abuild && \
    chown -R abuild:abuild /tmp/local && \
    apk add --update alpine-sdk && \
    su -s /bin/bash -c 'cd /tmp/local/google-authenticator && abuild-keygen -a && abuild -Fr' abuild && \
    cp /home/abuild/.abuild/abuild*.pub /etc/apk/keys/ && \
    apk add /home/abuild/packages/local/x86_64/google-authenticator-20160207-r1.apk && \
    apk del --purge --rdepends alpine-sdk && rm -rf /home/abuild && \
    rm -rf /tmp/* /var/tmp/* /var/cache/apk/* /var/cache/distfiles/*


# Needed by scripts
ENV OPENVPN /etc/openvpn
ENV EASYRSA /usr/share/easy-rsa
ENV EASYRSA_PKI $OPENVPN/pki
ENV EASYRSA_VARS_FILE $OPENVPN/vars

VOLUME ["/etc/openvpn"]

# Internally uses port 1194/udp, remap using `docker run -p 443:1194/tcp`
EXPOSE 1194/udp

CMD ["ovpn_run"]

ADD ./bin /usr/local/bin
RUN chmod a+x /usr/local/bin/*

# Add support for OTP authentication using a PAM module
ADD ./otp/openvpn /etc/pam.d/
