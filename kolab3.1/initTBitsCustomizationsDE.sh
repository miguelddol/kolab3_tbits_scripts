#!/bin/bash

#####################################################################################
# adjust some settings, that might be specific to TBits
#####################################################################################

# add admin_auto_fields_rw = true to kolab_wap section of kolab.conf
sed -r -i -e "s#\[kolab_wap\]#[kolab_wap]\nadmin_auto_fields_rw = true#g" /etc/kolab/kolab.conf

# change default locale
sed -r -i -e "s#default_locale = en_US#default_locale = de_DE#g" /etc/kolab/kolab.conf

# set in kolab.conf, ldap section: modifytimestamp_format = %%Y%%m%%d%%H%%M%%SZ, to avoid warning on console
sed -r -i -e "s#\[ldap\]#[ldap]\nmodifytimestamp_format = %%Y%%m%%d%%H%%M%%SZ#g" /etc/kolab/kolab.conf

# set in /etc/sysconfig/dirsrv: ulimit -n 32192, to avoid dirsrv crashing because of too many open files
sed -r -i -e "s/# ulimit -n 8192/ulimit -n 32192/g" /etc/sysconfig/dirsrv
service dirsrv restart

# disable debug mode in LDAP.php to avoid too much output
sed -r -i -e 's/config_set\("debug", true\)/config_set("debug", false)/g' /usr/share/kolab-webadmin/lib/Auth/LDAP.php
# disable debug modes for roundcube; otherwise /var/log/roundcubemail/imap can get really big!
sed -r -i -e "s/_debug'] = true/_debug'] = false/g" /etc/roundcubemail/config.inc.php

# change order of addressbooks: first personal address book
sed -r -i -e "s# = 0;# = 1;#g" /etc/roundcubemail/kolab_addressbook.inc.php

# change default names for calendar and address book
sed -r -i -e "s#Calendar#Kalender#g" /etc/roundcubemail/kolab_folders.inc.php
sed -r -i -e "s#Contacts#Kontakte#g" /etc/roundcubemail/kolab_folders.inc.php

# change default language
sed -r -i -e "s#// Re-apply mandatory settings here.#// Re-apply mandatory settings here.\n    \$config['locale_string'] = 'de';#g" /etc/roundcubemail/config.inc.php

# make Kalender and Kontakte default folders in roundcube, so that they get subscribed automatically
#sed -r -i -e "s#'INBOX', 'Drafts', 'Sent', 'Spam', 'Trash'#'INBOX', 'Drafts', 'Sent', 'Spam', 'Trash', 'Kalender', 'Kontakte'#g" /etc/roundcubemail/config.inc.php
# enable plugin subscriptions_options
sed -r -i -e "s#'redundant_attachments',#'redundant_attachments',\n            'subscriptions_option',#g" /etc/roundcubemail/config.inc.php
sed -r -i -e "s#// Re-apply mandatory settings here.#// Re-apply mandatory settings here.\n    \$rcmail_config['use_subscriptions'] = false;#g" /etc/roundcubemail/config.inc.php

