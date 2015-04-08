#!/bin/bash

# HTTP Repo
yum install -y createrepo httpd
mkdir /var/www/html/cmrepo
cp /cdhbuilder/provision/files/rpm/* /var/www/html/cmrepo
createrepo /var/www/html/cmrepo
mkdir /var/www/html/parcelrepo
cp /cdhbuilder/provision/files/parcels/* /var/www/html/parcelrepo
chmod -R 777  /var/www/html/parcelrepo
chkconfig httpd on
service httpd start

# Add Cloudera Repo
# it can either be the internet repo or a local one (local is just much faster for rapid redeploys)
cat << EOF > /etc/yum.repos.d/cloudera-manager.repo
[cloudera-manager]
# Packages for Cloudera Manager, Version 5.3.2
name=Cloudera Manager
baseurl=http://test-master.fq.dn/cmrepo
gpgcheck=0
EOF

# Install Cloudera Manager & Parcel repository
#TODO which java version matches which CDH version... install the appropriate one
yum install -y java-1.7.0-openjdk-devel cloudera-manager-server
#cp /cdhbuilder/provision/files/parcels/* /opt/cloudera/parcel-repo/
#chown cloudera-scm:cloudera-scm /opt/cloudera/parcel-repo/*

# Install & setup PostgreSQL
yum install -y postgresql-server
service postgresql initdb
sed -i "/# TYPE.*/a host all all 127.0.0.1/32 trust" /var/lib/pgsql/data/pg_hba.conf
chkconfig postgresql on
service postgresql start
/usr/share/cmf/schema/scm_prepare_database.sh postgresql -upostgres scm scm scm

psql -U postgres -h 127.0.0.1 <<EOF
CREATE ROLE amon LOGIN PASSWORD 'amon';
CREATE DATABASE amon OWNER amon ENCODING 'UTF8';
CREATE ROLE rman LOGIN PASSWORD 'rman';
CREATE DATABASE rman OWNER rman ENCODING 'UTF8';
CREATE ROLE hive LOGIN PASSWORD 'hive';
CREATE DATABASE metastore OWNER hive ENCODING 'UTF8';
ALTER DATABASE metastore SET standard_conforming_strings = off;
CREATE ROLE impala LOGIN PASSWORD 'impala';
CREATE DATABASE impala OWNER impala ENCODING 'UTF8';
EOF

sed -i "s#host all all 127.0.0.1/32 trust#host all all 127.0.0.1/32 md5#" /var/lib/pgsql/data/pg_hba.conf
service postgresql reload

service cloudera-scm-server start
