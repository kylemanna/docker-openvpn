# OpenVPN for Docker

[![Build Status](https://travis-ci.org/kylemanna/docker-openvpn.svg)](https://travis-ci.org/kylemanna/docker-openvpn)
[![Docker Stars](https://img.shields.io/docker/stars/kylemanna/openvpn.svg)](https://hub.docker.com/r/kylemanna/openvpn/)
[![Docker Pulls](https://img.shields.io/docker/pulls/kylemanna/openvpn.svg)](https://hub.docker.com/r/kylemanna/openvpn/)
[![ImageLayers Size](https://img.shields.io/imagelayers/image-size/kylemanna/openvpn/latest.svg)](https://hub.docker.com/r/kylemanna/openvpn/)
[![ImageLayers Layers](https://img.shields.io/imagelayers/layers/kylemanna/openvpn/latest.svg)](https://hub.docker.com/r/kylemanna/openvpn/)

OpenVPN server in a Docker container complete with an EasyRSA PKI CA.

Extensively tested on [Digital Ocean $5/mo node](http://bit.ly/1C7cKr3) and has
a corresponding [Digital Ocean Community Tutorial](http://bit.ly/1AGUZkq).

#### Upstream Links

* Docker Registry @ [kylemanna/openvpn](https://hub.docker.com/r/kylemanna/openvpn/)
* GitHub @ [kylemanna/docker-openvpn](https://github.com/kylemanna/docker-openvpn)

#### Example Service

* [backroad.io](http://beta.backroad.io?utm_source=kylemanna/openvpn&utm_medium=readme&utm_campaign=20150621) - powered by *kylemanna/openvpn*

## Quick Start

* Create the `$OVPN_DATA` volume container, i.e. `OVPN_DATA="ovpn-data"`

        docker run --name $OVPN_DATA -v /etc/openvpn busybox

* Initialize the `$OVPN_DATA` container that will hold the configuration files and certificates

        docker run --volumes-from $OVPN_DATA --rm kylemanna/openvpn ovpn_genconfig -u udp://VPN.SERVERNAME.COM
        docker run --volumes-from $OVPN_DATA --rm -it kylemanna/openvpn ovpn_initpki

* Start OpenVPN server process

    - On Docker [version 1.2](http://blog.docker.com/2014/08/announcing-docker-1-2-0/) and newer

            docker run --volumes-from $OVPN_DATA -d -p 1194:1194/udp --cap-add=NET_ADMIN kylemanna/openvpn

    - On Docker older than version 1.2

            docker run --volumes-from $OVPN_DATA -d -p 1194:1194/udp --privileged kylemanna/openvpn

* Generate a client certificate without a passphrase

        docker run --volumes-from $OVPN_DATA --rm -it kylemanna/openvpn easyrsa build-client-full CLIENTNAME nopass

* Retrieve the client configuration with embedded certificates

        docker run --volumes-from $OVPN_DATA --rm kylemanna/openvpn ovpn_getclient CLIENTNAME > CLIENTNAME.ovpn

* Create an environment variable with the name DEBUG and value of 1 to enable debug output (using "docker -e").

        docker run --volumes-from $OVPN_DATA -d -p 1194:1194/udp --privileged -e DEBUG=1 kylemanna/openvpn

## How Does It Work?

Initialize the volume container using the `kylemanna/openvpn` image with the
included scripts to automatically generate:

- Diffie-Hellman parameters
- a private key
- a self-certificate matching the private key for the OpenVPN server
- an EasyRSA CA key and certificate
- a TLS auth key from HMAC security

The OpenVPN server is started with the default run cmd of `ovpn_run`

The configuration is located in `/etc/openvpn`, and the Dockerfile
declares that directory as a volume. It means that you can start another
container with the `--volumes-from` flag, and access the configuration.
The volume also holds the PKI keys and certs so that it could be backed up.

To generate a client certificate, `kylemanna/openvpn` uses EasyRSA via the
`easyrsa` command in the container's path.  The `EASYRSA_*` environmental
variables place the PKI CA under `/etc/opevpn/pki`.

Conveniently, `kylemanna/openvpn` comes with a script called `ovpn_getclient`,
which dumps an inline OpenVPN client configuration file.  This single file can
then be given to a client for access to the VPN.


## OpenVPN Details

We use `tun` mode, because it works on the widest range of devices.
`tap` mode, for instance, does not work on Android, except if the device
is rooted.

The topology used is `net30`, because it works on the widest range of OS.
`p2p`, for instance, does not work on Windows.

The UDP server uses`192.168.255.0/24` for dynamic clients by default.

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
  passphrase to protect against a filesystem compromise.  A more secure system
  would put the EasyRSA PKI CA on an offline system (can use the same Docker
  image and the script [`ovpn_copy_server_files`](/docs/paranoid.md) to accomplish this).
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
without having to install/muck with library dependencies (i.e. run latest
OpenVPN with latest OpenSSL on Ubuntu 12.04 LTS).

### It Doesn't Stomp All Over the Server's Filesystem

Everything for the Docker container is contained in two images: the ephemeral
run time image (kylemanna/openvpn) and the data image (using busybox as a
base).  To remove it, remove the two Docker images and corresponding containers
and it's all gone.  This also makes it easier to run multiple servers since
each lives in the bubble of the container (of course multiple IPs or separate
ports are needed to communicate with the world).

### Some (arguable) Security Benefits

At the simplest level compromising the container may prevent additional
compromise of the server.  There are many arguments surrounding this, but the
take away is that it certainly makes it more difficult to break out of the
container.  People are actively working on Linux containers to make this more
of a guarantee in the future.

## Differences from jpetazzo/dockvpn

* No longer uses serveconfig to distribute the configuration via https
* Proper PKI support integrated into image
* OpenVPN config files, PKI keys and certs are stored on a storage
  volume for re-use across containers
* Addition of tls-auth for HMAC security

## Using with Kubernetes

If you want to run a VPN server on a Kubernetes cluster, you may want to put the credentials in a [Secret](http://kubernetes.io/v1.1/docs/user-guide/secrets.html)
To avoid having the PKI data (especially the key) left in a volume in your cluster, you should create the PKI and generate the configuration locally, then only submit the Secrets to the cluster.

You need to create the configuration as explained above, but in order to reach your services within Kubernetes, you will need to add a few flags.
For convenience here, a local volume from /etc/openvpn is mounted with the `-v` option as opposed to using the docker volume.

* Generate the configuration with:

```
docker run -v /etc/openvpn:/etc/openvpn --rm kylemanna/openvpn ovpn_genconfig \
-u udp://your.node.ip.or.FQDN:1194 \
-n 10.3.0.10 \
-n 8.8.8.8 \
-s 10.8.0.0/24 \
-N \
-p "route 10.2.0.0 255.255.0.0" \
-p "route 10.3.0.0 255.255.0.0" \
-p "dhcp-option DOMAIN-SEARCH cluster.local" \
-p "dhcp-option DOMAIN-SEARCH svc.cluster.local" \
-p "dhcp-option DOMAIN-SEARCH default.svc.cluster.local" \
```

The `-n` flags define the DNS to use. `10.3.0.10` is the IP of the default Kubernetes DNS add-on. Make sure it matches your config.

`-s 10.8.0.0/24` insures the VPN subnet is `10.8.0.0/24` as it tends to default to `10.2.0.0/24` which conflicts with Kubernetes's flannel network subnet.

`-N` to allow NAT, which appears to be critical to translate incoming traffic going to Services.

The `-p` options push the routes to the subnets to reach in the cluster to the client so as to force them into the tunnel

The `-p "dhcp-option DOMAIN_SEARCH cluster.local"` pushes the default DNS search domains to use to the client. Make sure they match your DNS config.

Since configuration depends on the credentials that we want to put in a Secret, and the configuration files (openvpn.conf and ovpn_env.sh) need to be accessible
by the server, they are being packed into the Secret as well.

* Generate the Secret YAML file with:

```
docker run -v /etc/openvpn:/etc/openvpn --rm kylemanna/openvpn ovpn_gen_kubernetes_secrets
```
The file will be saved in the `/etc/openvpn` folder

or use:
```
docker run -v /etc/openvpn:/etc/openvpn --rm kylemanna/openvpn ovpn_gen_kubernetes_secrets > open-vpn-secret.yaml
```

to output the file in the local directory

* Create the secret in your cluster

```
kubectl create -f open-vpn-secret.yaml
```

* Run the Pod

The example Pod `open-vpn.yaml` in `tests/kubernetes/` shows how to mount the Secret into the pod

Make sure to set the environment variable `KUBERNETES` to tell the openVPN server to load the Secret into the `/etc/openvpn` folder where it will look for the configuration.


## Tested On

* Docker hosts:
  * server a [Digital Ocean](https://www.digitalocean.com/?refcode=d19f7fe88c94) Droplet with 512 MB RAM running Ubuntu 14.04
* Clients
  * Android App OpenVPN Connect 1.1.14 (built 56)
     * OpenVPN core 3.0 android armv7a thumb2 32-bit
  * OS X Mavericks with Tunnelblick 3.4beta26 (build 3828) using openvpn-2.3.4
  * ArchLinux OpenVPN pkg 2.3.4-1
