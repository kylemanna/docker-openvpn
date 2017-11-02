# OpenLDAP Support

## Generate Config With LDAP Enabled

```shell
IMAGE_NAME=hydra1983/openvpn:openldap
OVPN_DATA="ovpn-data-sample"

docker run \
    -v $OVPN_DATA:/etc/openvpn \
    --rm ${IMAGE_NAME} \
    ovpn_genconfig \
    -e 'duplicate-cn' \
    -3 \
    -b \
    -c \
    -d \
    -N \
    -z

# Display generated conf
cat $(docker volume inspect --format '{{ .Mountpoint }}' $OVPN_DATA)/openvpn.conf
```

## Generate OpenLDAP Config

```shell
docker run \
    -v $OVPN_DATA:/etc/openvpn \
    --rm ${IMAGE_NAME} \
    ovpn_genconfig_openldap \
    -u 'ldap://<host>:<port>' \
    -B 'dc=sample,dc=com' \
    -b 'cn=admin,dc=sample,dc=com' \
    -p '<admin password>'

# Display generated conf
cat $(docker volume inspect --format '{{ .Mountpoint }}' $OVPN_DATA)/auth/auth-ldap.conf
```