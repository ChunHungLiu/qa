#!/bin/bash

set -eux

thisdir=$(dirname $(readlink -f "$0"))
. "$thisdir/common.sh"
enter_jenkins_test

server="${Server-$TEST_XENSERVER}"

stackdir="/tmp/stack"
if $CleanStackDir
then
    sudo rm -rf $stackdir
    sudo rm -rf /tmp/stage
fi

#
# Get latest devstack
#
mkdir -p $stackdir
cd $stackdir
if [ ! -d $stackdir/devstack ]
then
    DefaultDevStackRepo="git@github.com:renuka-apte/devstack.git"
    DevStackRepo="${DevStackRepo-$DefaultDevStackRepo}"
    git clone $DevStackRepo
fi
cd $stackdir/devstack

DefaultDevStackBranch="xenservermodif"
DevStackBranch="${DevStackBranch-$DefaultDevStackBranch}"
git checkout $DevStackBranch
git pull

#
# Get localrc
#
defaultlocalrc="http://gold.eng.hq.xensource.com/localrc"
lrcurl="${localrcURL-$defaultlocalrc}"
wget -N $lrcurl

#
# Build the XVA **as root**
#
if $AptProxy
then
    scaptproxy=yes
else
    scaptproxy=no
fi

BuildXVA="${BuildXVA-true}"
if $BuildXVA
then
    sudo su -c "server=$server scaptproxy=$scaptproxy stackdir=$stackdir $thisdir/run-devstack-helper.sh" root
fi

#
# Copy what we need to the XenServer
#
SCRIPT_TMP_DIR=/tmp/jenkins_test

cd $stackdir/devstack/tools/xen
sudo mv stage /tmp
add_on_exit "sudo mv /tmp/stage $stackdir/devstack/tools/xen"
cd ../../../
ssh "$server" "mkdir -p $SCRIPT_TMP_DIR/devstack"
scp -r devstack root@$server:$SCRIPT_TMP_DIR

scp $thisdir/common.sh root@$server:$SCRIPT_TMP_DIR
scp $thisdir/common-xe.sh root@$server:$SCRIPT_TMP_DIR
scp $thisdir/common-ssh.sh root@$server:$SCRIPT_TMP_DIR
scp $thisdir/devstack/verify.sh root@$server:$SCRIPT_TMP_DIR
scp $thisdir/devstack/run-excercise.sh root@$server:$SCRIPT_TMP_DIR
scp $thisdir/devstack/run-tempest.sh root@$server:$SCRIPT_TMP_DIR

#
# Run the next steps on the XenServer
#
RunExercises="${RunExercises-true}"
RunTempest="${RunTempest-true}"
remote_execute "root@$server" "$thisdir/devstack/on-host.sh" \""$RunExercises"\" \""$RunTempest"\"

echo "devstack exiting"
