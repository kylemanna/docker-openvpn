### HOW TO

- docker build . -t openvpn:1.0.0
- docker run -e EASYRSA_BATCH=1 -it --cap-add NET_ADMIN --name openvpn -p "1194:1194/tcp" openvpn:1.0.0
- docker rm -f openvpn
- docker tag openvpn:1.0.0 raibnod/openvpn
- docker push raibnod/openvpn