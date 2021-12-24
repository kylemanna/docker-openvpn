### HOW TO

- docker build . -t openvpn-server:1.0.0
- // docker run -e EASYRSA_BATCH=1 -it --cap-add NET_ADMIN --name openvpn-server -p "1194:1194/tcp" openvpn-server:1.0.0
- // docker rm -f openvpn-server
- docker tag openvpn-server:1.0.0 nubeio/openvpn-server:1.0.0
- docker push nubeio/openvpn-server:1.0.0