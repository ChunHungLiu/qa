#!/bin/bash

set -eux

export XAPISERVER="$1"
export XAPIPASS="$2"
export NFSSERVER="$3"
export NFSPATH="$4"
export LOCALPATHTONFS="/mnt/nfsdir"

export BRANCH="$5"

export DEBIAN_FRONTEND=noninteractive

sudo apt-get update
sudo apt-get -qy upgrade
sudo apt-get install -qy git nfs-common python-virtualenv blktap-utils python-dev
sudo mkdir -p /mnt/nfsdir
sudo mount -t nfs "${NFSSERVER}:${NFSPATH}" /mnt/nfsdir

git clone https://github.com/citrix-openstack/cinder-xapi-harness.git cinderdriver
cd cinderdriver
./run_tests.sh
