# Original credit: https://github.com/jpetazzo/dockvpn

FROM ubuntu:14.04

MAINTAINER Kyle Manna <kyle@kylemanna.com>

RUN apt-get install -y openvpn iptables curl git-core

# Update checkout to use tags when v3.0 is finally released
RUN git clone https://github.com/OpenVPN/easy-rsa.git /usr/local/share/easy-rsa
RUN cd /usr/local/share/easy-rsa && git checkout -b tested 89f369c5bbd13fbf0da2ea6361632c244e8af532
RUN ln -s /usr/local/share/easy-rsa/easyrsa3/easyrsa /usr/local/bin

ADD ./bin /usr/local/bin
RUN chmod a+x /usr/local/bin/*

VOLUME ["/etc/openvpn"]

EXPOSE 443/tcp 1194/udp 8080/tcp

ENTRYPOINT ["openvpn.sh"]
