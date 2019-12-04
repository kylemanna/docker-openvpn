# Docker + OpenVPN systemd Service

The systemd service aims to make the update and invocation of the
`docker-openvpn` container seamless.  It automatically downloads the latest
`docker-openvpn` image and instantiates a Docker container with that image.  At
shutdown it cleans-up the old container.

In the event the service dies (crashes, or is killed) systemd will attempt to
restart the service every 10 seconds until the service is stopped with
`systemctl stop docker-openvpn@NAME.service`.

A number of IPv6 hacks are incorporated to workaround Docker shortcomings and
are harmless for those not using IPv6.

To use and enable automatic start by systemd:

1. Create a Docker volume container named `ovpn-data-NAME` where `NAME` is the
   user's choice to describe the use of the container.  In this example
   configuration, `NAME=example`.
   
        OVPN_DATA="ovpn-data-example"
        docker volume create --name $OVPN_DATA
   
2. Initialize the data container, but don't start the container :
   
       docker run -v $OVPN_DATA:/etc/openvpn --rm kylemanna/openvpn ovpn_genconfig -u udp://VPN.SERVERNAME.COM
       docker run -v $OVPN_DATA:/etc/openvpn --rm -it kylemanna/openvpn ovpn_initpki
   
3. Download the [docker-openvpn@.service](https://raw.githubusercontent.com/kylemanna/docker-openvpn/master/init/docker-openvpn%40.service)
   file to `/etc/systemd/system`:

        curl -L https://raw.githubusercontent.com/kylemanna/docker-openvpn/master/init/docker-openvpn%40.service | sudo tee /etc/systemd/system/docker-openvpn@.service

4. Enable and start the service with:

        systemctl enable --now docker-openvpn@example.service

5. Verify service start-up with:

        systemctl status docker-openvpn@example.service
        journalctl --unit docker-openvpn@example.service

For more information, see the [systemd manual pages](https://www.freedesktop.org/software/systemd/man/index.html).
