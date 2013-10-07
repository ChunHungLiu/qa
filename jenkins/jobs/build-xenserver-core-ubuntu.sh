#!/bin/bash

set -eu

REMOTELIB=$(cd $(dirname $(readlink -f "$0")) && cd remote && pwd)
XSLIB=$(cd $(dirname $(readlink -f "$0")) && cd xslib && pwd)
TESTLIB=$(cd $(dirname $(readlink -f "$0")) && cd tests && pwd)

function print_usage_and_die
{
cat >&2 << EOF
usage: $0 XENSERVERNAME

Build xenserver-core packages

positional arguments:
 XENSERVERNAME     The name of the XenServer
EOF
exit 1
}

XENSERVERNAME="${1-$(print_usage_and_die)}"

set -x

SLAVE_IP=$(cat $XSLIB/start-slave.sh | "$REMOTELIB/bash.sh" "root@$XENSERVERNAME")

"$REMOTELIB/bash.sh" "ubuntu@$SLAVE_IP" << END_OF_XSCORE_BUILD_SCRIPT
set -eux

sudo tee /etc/apt/apt.conf.d/90-assume-yes << APT_ASSUME_YES
APT::Get::Assume-Yes "true";
APT::Get::force-yes "true";
APT_ASSUME_YES

sudo apt-get update
sudo apt-get dist-upgrade
sudo apt-get install git

#git clone https://github.com/xapi-project/xenserver-core.git -b deb-build-fixes xenserver-core
git clone https://github.com/matelakat/xenserver-core.git -b deb-build-fixes xenserver-core

cd xenserver-core

cat >> pbuilderrc.in << EOF
MIRRORSITE="http://mirror.anl.gov/pub/ubuntu/"
OTHERMIRROR="deb file:@PWD@/RPMS/ ./|deb-src file:@PWD@/SRPMS/ ./|deb http://ppa.launchpad.net/louis-gesbert/ocp/ubuntu raring main|deb http://mirror.anl.gov/pub/ubuntu/ raring universe"
export http_proxy=http://gold.eng.hq.xensource.com:8000
EOF

sudo ./configure.sh
./makemake.py > Makefile
sudo make
END_OF_XSCORE_BUILD_SCRIPT
