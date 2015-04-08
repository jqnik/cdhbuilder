#!/bin/sh

set -o errexit

packer build templates/centos-$rhel-x86_64-minimal/centos-$rhel-x86_64-minimal.json
vagrant box remove CentOS-$rhel-minimal
vagrant box add CentOS-$rhel-minimal packer_centos-$rhel-x86_64-minimal_virtualbox.box
vagrant box list | grep "CentOS-$rhel-minimal"
if [ $? -eq 0 ]
then
    rm packer_centos-$rhel-x86_64-minimal_virtualbox.box
fi
