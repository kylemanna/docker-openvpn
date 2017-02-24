#!/bin/bash
set -ev

# Provide support for Dockerfile.armhf, Dockerfile.aarch64, etc
if [ "$DOCKERFILE" != 'Dockerfile' ]; then
  docker run --rm --privileged multiarch/qemu-user-static:register --reset
fi

image="kylemanna/openvpn"
docker build -t "$image" . -f "$DOCKERFILE"
docker inspect "$image"
docker run --rm "$image" openvpn --version || true # why does it return 1?
docker run --rm "$image" openssl version

# Assist with ci test debugging:
# export DEBUG=1
official-images/test/run.sh "$image"
test/run.sh "$image"
