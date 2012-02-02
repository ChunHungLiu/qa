#!/bin/bash

set -eux

thisdir=$(dirname $(readlink -f "$0"))

. "$thisdir/common.sh"

enter_jenkins_test

server="${Server-$TEST_XENSERVER}"
stackdir="/tmp/stack"

mkdir -p $stackdir

cd $stackdir

if [ ! -d $stackdir/devstack ]
then
    git clone git@github.com:renuka-apte/devstack.git
fi

if $AptProxy
then
    scaptproxy=yes
else
    scaptproxy=no
fi
sudo su -c "server=$server scaptproxy=$scaptproxy stackdir=$stackdir $thisdir/run-devstack-helper.sh" root

cd $stackdir/devstack/tools/xen
sudo mv stage /tmp
cd ../../../
scp -r devstack root@$server:~/
sudo mv /tmp/stage $stackdir/devstack/tools/xen

scp $thisdir/common.sh root@$server:~/
scp $thisdir/common-xe.sh root@$server:~/
scp $thisdir/common-ssh.sh root@$server:~/
scp $thisdir/devstack/verify.sh root@$server:~/
scp $thisdir/devstack/run-excercise.sh root@$server:~/
remote_execute "root@$server" \
        "$thisdir/devstack/on-host.sh"
echo "devstack exiting"
