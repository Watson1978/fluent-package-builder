#!/bin/bash

set -exu

. $(dirname $0)/commonvar.sh

package="/host/${distribution}/${DISTRIBUTION_VERSION}/x86_64/Packages/fluent-package-[0-9]*.rpm"
sudo $DNF install -y $package

# Make a dummy pacakge for the next version
case $distribution in
    amazon)
        case $version in
            2023)
                curl -L -o rpmrebuild.noarch.rpm https://sourceforge.net/projects/rpmrebuild/files/latest/download
                sudo $DNF install -y ./rpmrebuild.noarch.rpm
                ;;
            2)
                sudo amazon-linux-extras install -y epel
                sudo $DNF install -y rpmrebuild
                ;;
        esac
        ;;
    *)
        sudo $DNF install -y epel-release
        sudo $DNF install -y rpmrebuild
        ;;
esac

# Example: "1.el9"
release=$(rpmquery --queryformat="%{Release}" -p $package)
# Example: "1"
release_ver=$(echo $release | cut -d . -f1)
# Example: "2.el9"
next_release=$(($release_ver+1)).$(echo $release | cut -d. -f2)
rpmrebuild --release=$next_release --modify="find $HOME -name fluentd.service | xargs sed -i -E 's/FLUENT_PACKAGE_VERSION=([0-9.]+)/FLUENT_PACKAGE_VERSION=\1.1/g'" --package $package
next_package=$(find rpmbuild -name "*.rpm")
rpm2cpio $next_package | cpio -id ./usr/lib/systemd/system/fluentd.service
next_package_ver=$(cat ./usr/lib/systemd/system/fluentd.service | grep "FLUENT_PACKAGE_VERSION" | sed -E "s/Environment=FLUENT_PACKAGE_VERSION=(.+)/\1/")
echo "repacked next fluent-package version: $next_package_ver"

# Set up configuration
cp $(dirname $0)/../../test-tools/no-data-lost.conf /etc/fluent/fluentd.conf

# Launch fluentd
sudo systemctl enable --now fluentd
systemctl status --no-pager fluentd

# Ensure to wait for fluentd launching
sleep 1

# Send logs in background for 4 seconds
/opt/fluent/bin/ruby $(dirname $0)/../../test-tools/logdata-sender.rb --udp-data-count 40 --tcp-data-count 50 --duration 4 &

sleep 2

# Update to the next version
sudo $DNF install -y ./$next_package
systemctl status --no-pager fluentd

sleep 2

# Stop fluentd to flush the logs and check
systemctl stop fluentd
test $(wc -l /var/log/fluent/test_udp*.log | cut -d' ' -f 1) = "40"
test $(wc -l /var/log/fluent/test_tcp*.log | cut -d' ' -f 1) = "50"
