# Debugging

Random things I do to debug the containers.

## Login Shells

* Create a shell in the running docker container with `docker exec`.
* To modify the data, you can also mount the data container and modify it with

        docker run --rm -it -v $OVPN_DATA:/etc/openvpn kylemanna/openvpn bash -l

## Stream OpenVPN Logs

1. Get the container's name or container ID:

        root@vpn:~/docker-openvpn# docker ps
        CONTAINER ID        IMAGE                      COMMAND             CREATED             STATUS              PORTS                    NAMES
        ed335aaa9b82        kylemanna/openvpn:latest   ovpn_run            5 minutes ago       Up 5 minutes        0.0.0.0:1194->1194/udp   sad_lovelace

2. Tail the logs:

        root@vpn:~/docker-openvpn# docker logs -f sad_lovelace
        + mkdir -p /dev/net
        + [ ! -c /dev/net/tun ]
        + mknod /dev/net/tun c 10 200
        + [ ! -d /etc/openvpn/ccd ]
        + iptables -t nat -A POSTROUTING -s 192.168.254.0/24 -o eth0 -j MASQUERADE
        + iptables -t nat -A POSTROUTING -s 192.168.255.0/24 -o eth0 -j MASQUERADE
        + conf=/etc/openvpn/openvpn.conf
        + [ ! -s /etc/openvpn/openvpn.conf ]
        + conf=/etc/openvpn/udp1194.conf
        + openvpn --config /etc/openvpn/udp1194.conf
        Tue Jul  1 06:56:48 2014 OpenVPN 2.3.2 x86_64-pc-linux-gnu [SSL (OpenSSL)] [LZO] [EPOLL] [PKCS11] [eurephia] [MH] [IPv6] built on Mar 17 2014
        Tue Jul  1 06:56:49 2014 Diffie-Hellman initialized with 2048 bit key
        Tue Jul  1 06:56:49 2014 Control Channel Authentication: using '/etc/openvpn/pki/ta.key' as a OpenVPN static key file
        Tue Jul  1 06:56:49 2014 Outgoing Control Channel Authentication: Using 160 bit message hash 'SHA1' for HMAC authentication
        Tue Jul  1 06:56:49 2014 Incoming Control Channel Authentication: Using 160 bit message hash 'SHA1' for HMAC authentication
        Tue Jul  1 06:56:49 2014 Socket Buffers: R=[212992->131072] S=[212992->131072]

