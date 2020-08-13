# IPv6 Support

This is a work in progress, more polish to follow.

## Tunnel IPv6 Address To OpenVPN Clients

This feature is advanced and recommended only for those who already have a functioning IPv4 tunnel and know how IPv6 works.

Systemd is used to setup a static route and Debian 8.1 or later is recommended as the host distribution.  Others probably work, but haven't been tested.


### Step 1 — Setup IPv6 on the Host Machine

The tutorial uses a free tunnel from [tunnelbroker.net](https://tunnelbroker.net/) to get a /64 and /48 prefix allocated to me.  The tunnel endpoint is less then 3 ms away from Digital Ocean's San Francisco datacenter.

Place the following in `/etc/network/interfaces`.  Replace `PUBLIC_IP` with your host's public IPv4 address and replace 2001:db8::2 and 2001:db8::1 with the corresponding tunnel endpoints:

    auto he-ipv6
    iface he-ipv6 inet6 v4tunnel
        address 2001:db8::2
        netmask 64
        endpoint 72.52.104.74
        local PUBLIC_IP
        ttl 255
        gateway 2001:db8::1

Bring the interface up:

    ifup he-ipv6

Test that IPv6 works on the host:

    ping6 google.com

If this doesn't work, figure it out.  It may be necessary to add an firewall rule to allow IP protocol 41 through the firewall.


### Step 2 — Update Docker's Init To Enable IPv6 Support

Add the `--ipv6` to the Docker daemon invocation.

On **Ubuntu** and old versions of Debian Append the `--ipv6` argument to the `DOCKER_OPTS` variable in:

    /etc/default/docker

On modern **systemd** distributions copy the service file and modify it and reload the service:

    sed -e 's:^\(ExecStart.*\):\1 --ipv6:' /lib/systemd/system/docker.service | tee /etc/systemd/system/docker.service
    systemctl restart docker.service


### Step 3 — Setup the systemd Unit File

Copy the systemd init file from the docker-openvpn /init directory of the repository and install into `/etc/systemd/system/docker-openvpn.service`

    curl -o /etc/systemd/system/docker-openvpn@.service 'https://raw.githubusercontent.com/kylemanna/docker-openvpn/dev/init/docker-openvpn%40.service'

Edit the file, replace `IP6_PREFIX` value with the value of your /64 prefix.

    vi /etc/systemd/system/docker-openvpn@.service

Finally, reload systemd so the changes take affect:

    systemctl daemon-reload

### Step 4 — Start OpenVPN

Ensure that OpenVPN has been initialized and configured as described in the top level `README.md`.

Start the systemd service file specifying the volume container suffix as the instance.  For example, `INSTANCE=test0` has a docker volume container named `ovpn-data-test0` and service will create `ovpn-test0` container:

    systemctl start docker-openvpn@test0

Verify logs if needed:

    systemctl status docker-openvpn@test0
    docker logs ovpn-test0

### Step 4 — Modify Client Config for IPv6 Default Route

Append the default route for the public Internet:

    echo "route-ipv6 2000::/3" >> clientname.ovpn

### Step 5 — Start up Client

If all went according to plan, then `ping6 2600::` and `ping6 google.com` should work.

Fire up a web browser and attempt to navigate to [https://ipv6.google.com](https://ipv6.google.com).


## Connect to the OpenVPN Server Over IPv6

This feature requires a docker daemon with working IPv6 support.

This will allow connections over IPv4 and IPv6.

Generate server configuration with the udp6 or tcp6 protocol:

    docker run -v $OVPN_DATA:/etc/openvpn --rm kylemanna/openvpn ovpn_genconfig -u udp6://VPN.SERVERNAME.COM
    docker run -v $OVPN_DATA:/etc/openvpn --rm kylemanna/openvpn ovpn_genconfig -u tcp6://VPN.SERVERNAME.COM
