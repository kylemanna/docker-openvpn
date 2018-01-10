# Original credit: https://github.com/jpetazzo/dockvpn

# Smallest base image
FROM alpine:latest

LABEL maintainer="Kyle Manna <kyle@kylemanna.com>"

# Testing: pamtester
RUN echo "http://dl-cdn.alpinelinux.org/alpine/edge/testing/" >> /etc/apk/repositories && \
    apk add --update iptables bash easy-rsa google-authenticator pamtester && \
    ln -s /usr/share/easy-rsa/easyrsa /usr/local/bin && \
    rm -rf /tmp/* /var/tmp/* /var/cache/apk/* /var/cache/distfiles/*

ENV OPENVPN_VERSION 2.4.3
ENV OPENVPN_GPG=6D04F8F1B0173111F499795E29584D9F40864578

RUN apk add --no-cache gnupg g++ linux-headers openssl-dev lzo-dev linux-pam-dev make && \
    wget https://swupdate.openvpn.org/community/releases/openvpn-${OPENVPN_VERSION}.tar.gz -P /tmp/ && \
    wget https://swupdate.openvpn.org/community/releases/openvpn-${OPENVPN_VERSION}.tar.gz.asc -P /tmp/ && \
    gpg --keyserver keys.gnupg.net --recv-keys ${OPENVPN_GPG} && \
    gpg --batch --verify /tmp/openvpn-${OPENVPN_VERSION}.tar.gz.asc /tmp/openvpn-${OPENVPN_VERSION}.tar.gz && \
    tar xzf /tmp/openvpn-${OPENVPN_VERSION}.tar.gz && \
    cd /tmp/openvpn-${OPENVPN_VERSION} && ./configure && make -j 9 && \
    cd /tmp/openvpn-${OPENVPN_VERSION}/src/plugins/auth-pam && make && \
    cd /tmp/openvpn-${OPENVPN_VERSION} && make install && mkdir -p /usr/lib/openvpn/plugins/ && cp /tmp/openvpn-${OPENVPN_VERSION}/src/plugins/auth-pam/.libs/openvpn-plugin-auth-pam.so /usr/lib/openvpn/plugins/ && \
    apk del gnupg g++ make && \
    rm -rf /tmp/* /var/tmp/* /var/cache/apk/* /var/cache/distfiles/*

# Needed by scripts
ENV OPENVPN /etc/openvpn
ENV EASYRSA /usr/share/easy-rsa
ENV EASYRSA_PKI $OPENVPN/pki
ENV EASYRSA_VARS_FILE $OPENVPN/vars

# Prevents refused client connection because of an expired CRL
ENV EASYRSA_CRL_DAYS 3650

VOLUME ["/etc/openvpn"]

# Internally uses port 1194/udp, remap using `docker run -p 443:1194/tcp`
EXPOSE 1194/udp

CMD ["ovpn_run"]

ADD ./bin /usr/local/bin
RUN chmod a+x /usr/local/bin/*

# Add support for OTP authentication using a PAM module
ADD ./otp/openvpn /etc/pam.d/
