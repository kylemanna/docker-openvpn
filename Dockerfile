FROM ubuntu:trusty
MAINTAINER Jason Gegere <jason@htmlgraphic.com>

ADD ./bin/ /usr/local/sbin
RUN echo deb http://archive.ubuntu.com/ubuntu/ precise main universe > /etc/apt/sources.list.d/precise.list

RUN apt-get update -q
RUN apt-get install -qy openvpn openssl libssl-dev curl python-pip build-essential python-dev iptables-persistent iptables
RUN pip install cherrypy uwsgi

RUN chmod +x /usr/local/sbin/*
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
CMD ["/bin/sh", "vpn"]
