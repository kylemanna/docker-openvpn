#!/bin/sh

LIBYUBIKEY_VER='libyubikey-1.13'
YKCLIENT_VER='ykclient-2.15'
YKPERS_VER='v1.18.0'
YUBICO_PAM_VER='2.24'

apk add --update alpine-sdk autoconf automake libtool linux-pam-dev curl-dev libusb-dev help2man asciidoc

git clone -b $LIBYUBIKEY_VER https://github.com/Yubico/yubico-c.git
cd yubico-c/
autoreconf --install
./configure
make check install

git clone -b $YKCLIENT_VER https://github.com/Yubico/yubico-c-client.git
cd yubico-c-client/
autoreconf --install
./configure
make check install

git clone -b $YKPERS_VER https://github.com/Yubico/yubikey-personalization.git
cd yubikey-personalization/
autoreconf --install
CFLAGS='-I/yubico-c' ./configure
make install

git clone -b $YUBICO_PAM_VER https://github.com/Yubico/yubico-pam.git
cd yubico-pam/
autoreconf --install
PKG_CONFIG_PATH=/usr/local/lib/pkgconfig CFLAGS='-I/yubico-c -I/yubico-c-client -I/yubikey-personalization' ./configure
make check install

cd /usr/local/lib
find . -name \*a -exec rm -f {} \;
rm -rf perl5 pkgconfig

cp -r /usr/local/lib /data/
