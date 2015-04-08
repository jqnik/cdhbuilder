#!/bin/bash

sed -i 's/127.0.0.1.*/127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4/' /etc/hosts
#hostname `hostname`.internal.jkunigk.ip

#cp /vagrant/provision/files/CentOS-Base.repo /etc/yum.repos.d/
