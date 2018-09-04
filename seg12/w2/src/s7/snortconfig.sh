#!/bin/bash

groupadd snort
useradd snort -r -s /sbin/nologin -c SNORT_IDS -g snort

mkdir /usr/local/etc/snort
mkdir /usr/local/etc/snort/rules
mkdir /usr/local/etc/snort/preproc_rules
ln -s /usr/local/etc/snort /etc/snort

mkdir /usr/local/lib/snort_dynamicrules
mkdir /var/log/snort

touch /etc/snort/rules/white_list.rules
touch /etc/snort/rules/black_list.rules
touch /etc/snort/rules/local.rules

chmod -R 5775 /usr/local/etc/snort
chmod -R 5775 /usr/local/lib/snort_dynamicrules
chmod -R 5775 /var/log/snort

chown -R snort:snort /usr/local/etc/snort
chown -R snort:snort /usr/local/lib/snort_dynamicrules
chown -R snort:snort /var/log/snort

cp ~/src/snort-2.9.11.1/etc/*.conf* /etc/snort
cp ~/src/snort-2.9.11.1/etc/*.map   /etc/snort
