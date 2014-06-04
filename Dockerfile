# Original credit: https://github.com/jpetazzo/dockvpn

FROM ubuntu:14.04

MAINTAINER Kyle Manna <kyle@kylemanna.com>

RUN apt-get install -y openvpn iptables curl

ADD ./bin /usr/local/sbin
RUN chmod a+x /usr/local/sbin/*

VOLUME /etc/openvpn

EXPOSE 443/tcp 1194/udp 8080/tcp

ENTRYPOINT ["openvpn.sh"]
