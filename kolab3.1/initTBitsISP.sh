#!/bin/bash

if ( which yum ); then
  yum -y install wget patch
else
  if (which apt-get); then
    apt-get -y install wget patch;
  else echo "Neither yum nor apt-get available. On which platform are you?";
  exit 0
  fi
fi

#####################################################################################
# apply a couple of patches, see related kolab bugzilla number in filename, eg. https://issues.kolab.org/show_bug.cgi?id=2018
#####################################################################################
# different paths in debian and centOS
pythonDistPackages=/usr/lib/python2.7/dist-packages
# Debian
if [ ! -d $pythonDistPackages ]; then
  # centOS
  pythonDistPackages=/usr/lib/python2.6/site-packages
fi

echo "applying patchMultiDomainAdminsBug2018.patch"
patch -p1 -i `pwd`/patches/patchMultiDomainAdminsBug2018.patch -d /usr/share/kolab-webadmin
echo "applying domainquotaBug2046.patch"
patch -p1 -i `pwd`/patches/domainquotaBug2046.patch -d /usr/share/kolab-webadmin
echo "applying domainAdminDefaultQuota.patch"
patch -p1 -i `pwd`/patches/domainAdminDefaultQuota.patch -d /usr/share/kolab-webadmin
echo "applying domainAdminMaxAccounts.patch"
patch -p1 -i `pwd`/patches/domainAdminMaxAccounts.patch -d /usr/share/kolab-webadmin
echo "applying domainAdminEnableGroupware.patch"
patch -p1 -i `pwd`/patches/domainAdminEnableGroupware.patch -d /usr/share/kolab-webadmin
echo "applying lastLoginTBitsAttribute patch"
patch -p1 -i `pwd`/patches/lastLoginTBitsAttribute-wap.patch -d /usr/share/kolab-webadmin
patch -p1 -i `pwd`/patches/lastLoginTBitsAttribute-pykolab.patch -d $pythonDistPackages
echo "applying allowPrimaryEmailAddressFromDomain.patch"
patch -p1 -i `pwd`/patches/allowPrimaryEmailAddressFromDomain.patch -d $pythonDistPackages

#####################################################################################
#using specific ldap attribute for the domainadmin overall quota
#####################################################################################
sed -r -i -e "s/\[kolab\]/[kolab]\ndomainadmin_quota_attribute = tbitskolaboverallquota/g" /etc/kolab/kolab.conf


#####################################################################################
#disable LDAP debugging
#####################################################################################
sed -r -i -e 's/config_set\("debug", true\)/config_set("debug", false)/g' /usr/share/kolab-webadmin/lib/Auth/LDAP.php


#####################################################################################
#extend the LDAP schema for TBits ISP patches
#####################################################################################
for d in /etc/dirsrv/slapd*
do
  cp patches/99tbits.ldif $d/schema/
done

service dirsrv restart


#####################################################################################
#create new user_type domainadmin
#add tbitsKolabUser objectclass to Kolab user, for last login time
#####################################################################################
php initTBitsUserTypes.php

#####################################################################################
#set the domain for management of the domain admins
#####################################################################################
sed -r -i -e "s/\[kolab\]/[kolab]\ndomainadmins_management_domain = administrators.org/g" /etc/kolab/kolab.conf
php initDomainAdminManagementDomain.php

#####################################################################################
#only give users with role enable-groupware-features the permission to use calendar, tasks, files etc in Roundcube
#####################################################################################
sed -r -i -e "s/'calendar',/#'calendar',/g" /etc/roundcubemail/config.inc.php 
sed -r -i -e "s/'kolab_activesync',/#'kolab_activesync',/g" /etc/roundcubemail/config.inc.php 
sed -r -i -e "s/'kolab_addressbook',/#'kolab_addressbook',/g" /etc/roundcubemail/config.inc.php 
sed -r -i -e "s/'kolab_files',/#'kolab_files',/g" /etc/roundcubemail/config.inc.php 
sed -r -i -e "s/'tasklist',/#'tasklist',/g" /etc/roundcubemail/config.inc.php 

KolabAuthRolePlugins="rcmail_config['kolab_auth_role_plugins'] = array( \
       'cn=enable-groupware-features,%dc' => array( \
               'calendar', \
               'kolab_activesync', \
               'kolab_addressbook', \
               'kolab_files', \
               'tasklist', \
           ), \
         );"

sed -r -i -e "s/config\['plugins'\] = array\(/$KolabAuthRolePlugins\n\$config['plugins'] = array(/g" /etc/roundcubemail/config.inc.php

