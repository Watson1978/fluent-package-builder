#!/bin/bash

set -exu

. $(dirname $0)/../commonvar.sh

# Install the current
sudo apt install -V -y \
    /host/${distribution}/pool/${code_name}/${channel}/*/*/fluent-package_*_${architecture}.deb

# Test: service status
systemctl status --no-pager fluentd
systemctl status --no-pager td-agent
main_pid=$(eval $(systemctl show td-agent --property=MainPID) && echo $MainPID)

# Install v5 LTS
curl --fail --silent --show-error --location https://toolbelt.treasuredata.com/sh/install-${distribution}-${code_name}-fluent-package5-lts.sh | sh
apt install -y fluent-package=5.0.5-1 --allow-downgrades

systemctl status --no-pager fluentd
systemctl status --no-pager td-agent

# Fluentd should be restarted.
test $main_pid -ne $(eval $(systemctl show fluentd --property=MainPID) && echo $MainPID)
