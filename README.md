# OpenVPN for Docker


OpenVPN server in a Docker container complete with an EasyRSA PKI CA.

#### Upstream Links

* Docker Registry @ [castone38/dockervpn](https://hub.docker.com/r/castone38/dockervpn/)
* GitHub @ [castone38/docker-openvpn](https://github.com/castone38/docker-openvpn)
* Forked from GitHub @ [kylemanna/docker-openvpn](https://github.com/kylemanna/docker-openvpn)

## Quick Start

* Create, initialize, and start the docker container. The container will prompt for a passphrase to protect the
  private key used by the newly generated certificate authority.

      ./bin/host_install -d YOUR_SERVER_DOMAIN_NAME

* Retrieve a client configuration with embedded certificates

      dockervpn getclient /home/userid/clientname.ovpn

* Command line interface help

      dockervpn help

## How Does It Work?

Initialize the volume container using the `castone38/dockervpn` image with the
included scripts to automatically generate:

- a private key
- a self-certificate matching the private key for the OpenVPN server
- an EasyRSA CA key and certificate
- a TLS auth key for HMAC security
- a certificate revocation key

The OpenVPN server is started with the default run cmd of `ovpn_run`

The configuration is located in `/etc/openvpn`, and the Dockerfile
declares that directory as a volume. It means that you can start another
container with the `-v` argument, and access the configuration.
The volume also holds the PKI keys and certs so that it could be backed up.

The docker container contains the nano and vi editors and any file in the
container can be edited with `dockervpn nano <filename>` or 
`dockervpn vi <filename>`. For instance, to customize the server configuration,
use `dockervpn nano /etc/openvpn/openvpn.conf`.

To generate a client certificate, `castone38/dockervpn` uses EasyRSA via the
`easyrsa` command in the container's path.  The `EASYRSA_*` environment
variables place the PKI CA under `/etc/openvpn/pki`.

Conveniently, the `dockervpn` command line interface contains commands to issue
client certificates and configuration files.

## OpenVPN Details

We use `tun` mode, because it works on the widest range of devices.
`tap` mode, for instance, does not work on Android, except if the device
is rooted.

The topology used is `subnet` to support mesh networking. With mesh networking
it is possible to route traffic through a different vpn client instead of the 
vpn server. This allows you to run the server on a vps in the internet and route
traffic back to a client machine in your house so that it looks like you are
at home. Internet providers routinely block customers from running servers
in their home, thus it may not be possible for you to run the openvpn server
in your home and reach it from outside the home network. Topology subnet avoids
that issue as the machine in your home is a client, not a server.

The UDP server uses`10.8.0.0/24` for dynamic clients by default.

The client profile specifies `redirect-gateway def1`, meaning that after
establishing the VPN connection, all traffic will go through the VPN.
This might cause problems if you use local DNS recursors which are not
directly reachable, since you will try to reach them through the VPN
and they might not answer to you. If that happens, use public DNS
resolvers like those of Google (8.8.4.4 and 8.8.8.8) or OpenDNS
(208.67.222.222 and 208.67.220.220).


## Security Discussion

The Docker container runs its own EasyRSA PKI Certificate Authority.  This was
chosen as a good way to compromise on security and convenience.  The container
runs under the assumption that the OpenVPN container is running on a secure
host, that is to say that an adversary does not have access to the PKI files
under `/etc/openvpn/pki`.  This is a fairly reasonable compromise because if an
adversary had access to these files, the adversary could manipulate the
function of the OpenVPN server itself (sniff packets, create a new PKI CA, MITM
packets, etc).

* The certificate authority key is kept in the container by default for
  simplicity.  It's highly recommended to secure the CA key with some
  passphrase to protect against a filesystem compromise.
* It would be impossible for an adversary to sign bad or forged certificates
  without first cracking the key's passphase should the adversary have root
  access to the filesystem.
* The EasyRSA `build-client-full` command will generate and leave keys on the
  server, again possible to compromise and steal the keys.  The keys generated
  need to be signed by the CA which the user hopefully configured with a passphrase
  as described above.
* Assuming the rest of the Docker container's filesystem is secure, TLS + PKI
  security should prevent any malicious host from using the VPN.


## Benefits of Running Inside a Docker Container

### The Entire Daemon and Dependencies are in the Docker Image

This means that it will function correctly (after Docker itself is setup) on
all distributions Linux distributions such as: Ubuntu, Arch, Debian, Fedora,
etc.  Furthermore, an old stable server can run a bleeding edge OpenVPN server
without having to install/muck with library dependencies.

### It Doesn't Stomp All Over the Server's Filesystem

Everything for the Docker container is contained in two images: the ephemeral
run time image (castone38/dockervpn) and the openvpn_data data volume. To remove
it, remove the corresponding containers, openvpn_data data volume and Docker
image and it's completely removed.  This also makes it easier to run multiple
servers since each lives in the bubble of the container (of course multiple IPs
or separate ports are needed to communicate with the world).

### Some (arguable) Security Benefits

At the simplest level compromising the container may prevent additional
compromise of the server.  There are many arguments surrounding this, but the
take away is that it certainly makes it more difficult to break out of the
container.  People are actively working on Linux containers to make this more
of a guarantee in the future.

## Differences from kylemanna/docker-openvpn

* Uses tls-crypt for HMAC security.
* Uses elliptic curve cryptography in the certificate authority eliminating diffie-hellman generation.
* Uses topology subnet to support mesh networking.
* Will generate client configs that route traffic through another client instead of the vpn server. Similar to NordVPN's meshnet.
* Provides easy host install script.
* Provides the dockervpn cli to make common tasks easier.
