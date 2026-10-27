#!/bin/bash

sudo apt update
if apt-cache show incus-base > /dev/null 2>&1; then
  sudo apt install -y -V incus-base
else
  sudo apt install -y -V incus
fi

# Allow egress network traffic flows for Incus
# https://linuxcontainers.org/incus/docs/main/howto/network_bridge_firewalld/#prevent-connectivity-issues-with-incus-and-docker
sudo iptables -I DOCKER-USER -i incusbr0 -j ACCEPT
sudo iptables -I DOCKER-USER -o incusbr0 -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
sudo incus admin init --auto
sudo incus profile set default raw.apparmor="signal peer=@{profile_name}//&unconfined,
ptrace peer=@{profile_name}//&unconfined,"
# enable incus legacy/snapshot images
sudo incus remote add fluent https://fluentd.cdn.cncf.io/test/incus-images --accept-certificate --protocol=simplestreams
