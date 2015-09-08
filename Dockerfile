# Original credit: https://github.com/jpetazzo/dockvpn

# Leaner build then Ubunutu
FROM alpine:3.2

MAINTAINER Kyle Manna <kyle@kylemanna.com>

RUN apk update && \
    apk add openvpn iptables curl bash && \
    rm -rf /tmp/* /var/tmp/* /var/cache/apk/*

RUN mkdir -p /usr/local/share/easy-rsa && cd /usr/local/share/easy-rsa && \
    curl -L https://github.com/OpenVPN/easy-rsa/archive/v3.0.0.tar.gz | tar xzf - easy-rsa-3.0.0/easyrsa3 && \
    mv easy-rsa-3.0.0/easyrsa3 . && rmdir easy-rsa-3.0.0 && \
    ln -s /usr/local/share/easy-rsa/easyrsa3/easyrsa /usr/local/bin

# Needed by scripts
ENV OPENVPN /etc/openvpn
ENV EASYRSA /usr/local/share/easy-rsa/easyrsa3
ENV EASYRSA_PKI $OPENVPN/pki
ENV EASYRSA_VARS_FILE $OPENVPN/vars

VOLUME ["/etc/openvpn"]

# Internally uses port 1194/udp, remap using `docker run -p 443:1194/tcp`
EXPOSE 1194/udp

WORKDIR /etc/openvpn
CMD ["ovpn_run"]

ADD ./bin /usr/local/bin
RUN chmod a+x /usr/local/bin/*
