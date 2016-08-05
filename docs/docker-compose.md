# Quick Start with docker-compose

* Add a new service in docker-compose.yml

        version: '2'
        services:
          openvpn:
            cap_add:
             - NET_ADMIN
            image: kylemanna/openvpn
            ports:
             - "1194:1194/udp"
            restart: always
            volumes:
             - ./openvpn/conf:/etc/openvpn

* Initialize the configuration files and certificates

        docker-compose run --rm openvpn ovpn_genconfig -u udp://VPN.SERVERNAME.COM
        docker-compose run --rm openvpn ovpn_initpki
        
* Fix ownership (depending on how to handle your backups, this may not be needed)

        sudo chown -R $(whoami): ./openvpn

* Start OpenVPN server process

        docker-compose up -d openvpn

* Generate a client certificate without a passphrase

        docker-compose run --rm openvpn easyrsa build-client-full CLIENTNAME nopass

* Retrieve the client configuration with embedded certificates

        docker-compose run --rm openvpn ovpn_getclient CLIENTNAME > CLIENTNAME.ovpn

## Debugging Tips

* Create an environment variable with the name DEBUG and value of 1 to enable debug output (using "docker -e").

        docker-compose run -e DEBUG=1 openvpn
