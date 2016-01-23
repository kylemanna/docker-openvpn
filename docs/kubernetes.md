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

