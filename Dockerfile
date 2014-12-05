# Original credit: https://github.com/jpetazzo/dockvpn

# Leaner build then Ubunutu
FROM debian:jessie

MAINTAINER Kyle Manna <kyle@kylemanna.com>

RUN apt-get update && apt-get install -y openvpn iptables curl

# Install easyrsa 3.0.0-rc2 (switch to release when available)
RUN cd /usr/local/share/ && \
    curl -sSL https://github.com/OpenVPN/easy-rsa/releases/download/v3.0.0-rc2/EasyRSA-3.0.0-rc2.tgz | tar -zx && \
    mv EasyRSA-3.0.0-rc2 easyrsa && \
    ln -s /usr/local/share/easyrsa/easyrsa /usr/local/bin

# Needed by scripts
ENV OPENVPN /etc/openvpn
ENV EASYRSA /usr/local/share/easyrsa
ENV EASYRSA_PKI $OPENVPN/pki
ENV EASYRSA_VARS_FILE $OPENVPN/vars

VOLUME ["/etc/openvpn"]

# Internally uses port 1194, remap using docker
EXPOSE 1194/udp

WORKDIR /etc/openvpn
CMD ["ovpn_run"]

ADD ./bin /usr/local/bin
RUN chmod a+x /usr/local/bin/*
