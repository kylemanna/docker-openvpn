FROM ubuntu:trusty
ADD ./bin/ /usr/local/sbin
RUN echo deb http://archive.ubuntu.com/ubuntu/ precise main universe > /etc/apt/sources.list.d/precise.list
RUN chmod +x /usr/local/sbin/setup.sh
RUN /usr/local/sbin/setup.sh
RUN chmod +x /usr/local/sbin/*
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
EXPOSE 443/tcp 8080/tcp
CMD vpn
