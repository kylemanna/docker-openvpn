#!/bin/bash
init_files() {
  mkdir -p /etc/openvpn
  touch /etc/openvpn/openvpn-status.log
  mkdir -p /etc/openvpn/ccd
  mkdir -p /etc/openvpn/client/configs/users
  mkdir -p /etc/openvpn/client/configs/devices
}

init_ca() {
  ls /etc/openvpn/pki/ca.crt > /dev/null 2>&1
  if [ $? -eq 0 ]; then
    echo "CA already exists!"
    return
  fi

  echo "Creating CA..."
  easyrsa init-pki
  easyrsa build-ca nopass
}

init_vpn_server() {
  ls /etc/openvpn/pki/issued/openvpnserver.crt > /dev/null 2>&1
  if [ $? -eq 0 ]; then
    echo "OpenVPN server already exists!"
    return
  fi

  echo "Creating OpenVPN Server..."
  cd /etc/openvpn
  echo "openvpnserver" | easyrsa gen-req openvpnserver nopass > /dev/null 2>&1
  echo "yes" | easyrsa sign-req server openvpnserver > /dev/null 2>&1
  easyrsa gen-dh
  openvpn --genkey secret /etc/openvpn/pki/ta.key
}

init_files
init_ca
init_vpn_server