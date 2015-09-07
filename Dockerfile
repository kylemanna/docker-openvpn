# Original credit: https://github.com/jpetazzo/dockvpn

# Leaner build then Ubunutu
FROM debian:jessie

MAINTAINER Kyle Manna <kyle@kylemanna.com>

RUN apt-get update && \
    apt-get install -y openvpn iptables curl && \
    apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN curl -L https://github.com/OpenVPN/easy-rsa/archive/v3.0.0.tar.gz | tar xzf -  && \
	mkdir -p /usr/local/share/easy-rsa && \
	mv easy-rsa-3.0.0/easyrsa3 /usr/local/share/easy-rsa/easyrsa3 && \
    ln -s /usr/local/share/easy-rsa/easyrsa3/easyrsa /usr/local/bin && \
    rm -fr /easy-rsa-3.0.0

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
RUN chmod +x /usr/local/bin/ovpn_* /usr/local/bin/easyrsa_*
