#!/bin/bash

set -exu

. $(dirname $0)/../commonvar.sh

# Install the current
sudo apt install -V -y \
    /host/${distribution}/pool/${code_name}/${channel}/*/*/fluent-package_*_${architecture}.deb

# Make a dummy pacakge for the next version
dpkg-deb -R /host/${distribution}/pool/${code_name}/${channel}/*/*/fluent-package_*_${architecture}.deb tmp
last_ver=$(cat tmp/DEBIAN/control | grep "Version: " | sed -E "s/Version: ([0-9.]+)-([0-9]+)/\2/g")
sed -i -E "s/Version: ([0-9.]+)-([0-9]+)/Version: \1-$(($last_ver+1))/g" tmp/DEBIAN/control
dpkg-deb --build tmp next_version.deb

# The service should start automatically
systemctl is-active fluentd
# The service should be enabled by default
systemctl is-enabled fluentd

# Stop the service
sudo systemctl stop fluentd

# Install the dummy package
sudo apt install -V -y ./next_version.deb

# The service should restart automatically after update
systemctl is-active fluentd
systemctl is-enabled fluentd
