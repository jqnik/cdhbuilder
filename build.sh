# Call like ./build.sh my_build 5.3.2 fq.dn 6.6
build=$1
#must be X.Y or X.Y.Z (e.g. 5.4 or 5.3.2)
cdh_release=$2
#just the domain name please, the hostname will be master, the complete name master.fq.dn
fqdn=$3
#RHEL release
rhel=$4

echo "num of params = $#"

if [ ! -e $build ]; then
    mkdir $build
fi

if [ ! -e $build/Vagrantfile ]
then
    cp Vagrantfile $build/  
fi

if [ ! -e $build/provision ]
then
    ln -s `pwd`/provision $build
fi

# TODO: This is bad as it is self-modifying code, we need to pass in variables (into Ruby? *running away*)
sed -i'' -e "s/config.vm.define.*/config.vm.define \"$build-master\", primary: true do |master|" $build/Vagrantfile
sed -i'' -e "s/DOMAIN = .*/DOMAIN = \"$fqdn\"/" $build/Vagrantfile
sed -i'' -e "s/v.name = .*/v.name = \"$build-master\"/" $build/Vagrantfile
sed -i'' -e "s/master.vm.hostname = .*/master.vm.hostname = \"$build-master\.#{DOMAIN}\"/" $build/Vagrantfile
sed -i'' -e "s/master.hostmanager.aliases = .*/master.hostmanager.aliases = \"$build-master\"/" $build/Vagrantfile

hostname=$(grep "v\.name" $build/Vagrantfile | sed -e "s/.*v\.name = \"//"| sed -e "s/.$//")

fqhn=$hostname.$fqdn

# TODO: This is bad as it is self-modifying code, we need to pass in variables
sed -i'' -e "s/Packages for Cloudera Manager, Version .*/Packages for Cloudera Manager, Version $cdh_release/" ./provision/master.sh
sed -i'' -e "s/baseurl=http:\/\/.*/baseurl=http:\/\/$fqhn\/cmrepo/" ./provision/master.sh

minor_rel=`echo $cdh_release|cut -d. -f1,2`

# For this to work you need to enter a custom parcel repo in the install wizard:
# Page: Cluster Installation. -> Choose Method -> Parcels -> More Options -> Remote Parcel Repositor URLS -> remove all -> add http://$fqhn/parcelrepo
prefix=./provision/files/parcels
echo "prefix = $prefix"
if [ -e $prefix/CDH-$cdh_release* ]
then
    echo "Skipping parcels download, since content for CDH $cdh_release seems to exist already"
    echo "You can delete the files in $prefix to get a fresh download"
    path="http://archive.cloudera.com/cdh5/parcels/$minor_rel/CDH-$cdh_release-1.cdh$cdh_release.p0.10-el6.parcel"
    wget -P $prefix $path.sha1
    path="http://archive.cloudera.com/cdh5/parcels/$minor_rel/manifest.json"
    wget -P $prefix $path
else
    echo "Getting Parcels"
    path="http://archive.cloudera.com/cdh5/parcels/$minor_rel/CDH-$cdh_release-1.cdh$cdh_release.p0.10-el6.parcel"
    wget -P $prefix $path
    wget -P $prefix $path.sha1
    path="http://archive.cloudera.com/cdh5/parcels/$minor_rel/manifest.json"
    wget -P $prefix $path
fi

# Page: Cluster Installation. -> Select the specific release of the Cloudera Manager Agent you want to install on your hosts -> custom repositor -> add http://$fqhn/cmrepo
prefix=./provision/files/rpm
echo "prefix = $prefix"
ls $prefix|grep "cloudera-.*$cdh_release"
if [ $? -eq 0 ]
then
    echo "Skipping RPM download, since content for CDH $cdh_release seems to exist already"
    echo "You can delete the files in $prefix to get a fresh download"
else
    echo "Getting RPMs"
    path=http://archive.cloudera.com/cm5/redhat/6/x86_64/cm/$cdh_release/RPMS/x86_64/
    wget -nd -r --no-parent --reject "index.html*" -P $prefix $path
fi

prefix=./packer-templates
vagrant box list | grep "CentOS-$rhel-minimal"
if [ $? -eq 0 ]
then
    echo "Skipping CentOS Box build since content for CDH $cdh_release seems to exist already"
    echo "do \"vagrant box remove CentOS-$rhel-minimal\" to force re-build"
else
    $prefix/build-centos-minimal_.sh $rhel
fi

cd $build
vagrant up
