# Quick Start with docker-compose

* Add a new service in docker-compose.yml

```yaml
version: '2'
services:
  openvpn:
    cap_add:
     - NET_ADMIN
    image: kylemanna/openvpn
    container_name: openvpn
    ports:
     - "1194:1194/udp"
    restart: always
    volumes:
     - ./openvpn-data/conf:/etc/openvpn
```


* Initialize the configuration files and certificates

```bash
docker-compose run --rm openvpn ovpn_genconfig -u udp://VPN.SERVERNAME.COM
docker-compose run --rm openvpn ovpn_initpki
```

* Fix ownership (depending on how to handle your backups, this may not be needed)

```bash
sudo chown -R $(whoami): ./openvpn-data
```

* Start OpenVPN server process

```bash
docker-compose up -d openvpn
```

* You can access the container logs with

```bash
docker-compose logs -f
```

* Generate a client certificate

```bash
export CLIENTNAME="your_client_name"
# with a passphrase (recommended)
docker-compose run --rm openvpn easyrsa build-client-full $CLIENTNAME
# without a passphrase (not recommended)
docker-compose run --rm openvpn easyrsa build-client-full $CLIENTNAME nopass
```

* Retrieve the client configuration with embedded certificates

```bash
docker-compose run --rm openvpn ovpn_getclient $CLIENTNAME > $CLIENTNAME.ovpn
```

* Revoke a client certificate

```bash
# Keep the corresponding crt, key and req files.
docker-compose run --rm openvpn ovpn_revokeclient $CLIENTNAME
# Remove the corresponding crt, key and req files.
docker-compose run --rm openvpn ovpn_revokeclient $CLIENTNAME remove
```

## Debugging Tips

* Create an environment variable with the name DEBUG and value of 1 to enable debug output (using "docker -e").

```bash
docker-compose run -e DEBUG=1 -p 1194:1194/udp openvpn
```

## Simple Script
* If you use docker-compose for deployment, this is a simple and practical script. Add a shell script file `manage.sh`.  in the same directory as docker-compose.
```bash
#!/bin/bash

echo -e "\nManage Script\n"

while getopts ":a:d: l r v h" opt
do
    case $opt in
        a)
        	echo "Generating certificate for $OPTARG"
		docker-compose run --rm openvpn easyrsa build-client-full $OPTARG
        ;;
	d)
		echo "Revoking certificate for $OPTARG "
		docker-compose run --rm openvpn ovpn_revokeclient $OPTARG remove	
	;;
	l)
		echo "View user list"
		docker-compose run --rm openvpn ovpn_listclients
	;;
	r)
        	echo "Update certificate"
		docker-compose run --rm openvpn ovpn_getclient_all
		echo "openvpn-data/conf/"		
        ;;
	v)	
		echo "Version information"
		docker exec openvpn openvpn --version
	;;
	h)
		echo -e "-a Add user. eg: -a wangyanpeng;\n"
		echo -e "-d Revocation of user's certificate. eg: -d wangyanpeng;\n"
		echo -e "-l View user list. eg: -l; \n"
		echo -e "-r Batch generation and update of client configuration files,catalog:openvpn-data/conf/clients . eg: -r;\n"
		echo -e "-v View current version. eg: -v;\n"
		echo -e "-h Get help information. eg: -h;\n"
	;;
        ?)
        echo "Unknown parameter"
	echo "-h for help information"
        exit 1;;
    esac
done

```
* Add run permissions.
```bash
chmod +x ./manage.sh 
```
* Let's go ！
```bash
./manage.sh -h
```

