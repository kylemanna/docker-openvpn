### HOW TO

- docker build . -t easyrsa:1.0.0
- docker run -e EASYRSA_BATCH=1 -it --cap-add NET_ADMIN --name easyrsa -p "1194:1194/tcp" easyrsa:1.0.0
- docker rm -f easyrsa
- docker tag easyrsa:1.0.0 raibnod/easyrsa:1.0.0
- docker push raibnod/easyrsa:1.0.0