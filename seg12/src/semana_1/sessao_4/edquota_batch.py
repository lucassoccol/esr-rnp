#!/usr/bin/python

'''

## Script not yet testing for:
#    - inexistent users
#    - removal of root user
#    - removal of argv[1] user

#!/bin/bash

if [[ $EUID -ne 0 ]]; then
  echo "  [*] Not root!" 1>&2
  exit 1
fi

for user in $( getent shadow | awk -F: '$2 != "*" && $2 !~ /^!/ { print $1 }' ); do
  edquota -u ${user} -p $1
done

'''

import os, sys, subprocess, pwd, spwd

if os.geteuid() != 0:
  exit('  Not root?')

if len(sys.argv) <= 1:
  exit('  Usage: ' + sys.argv[0] + ' TEMPLATE_USER')

try:
  pwd.getpwnam(sys.argv[1])
except KeyError:
  exit('No such \'' + sys.argv[1] + '\' user')

qusers = []

for user in pwd.getpwall():
  if user[0] == 'root' or user[0] == sys.argv[1]:
    continue

  phash = spwd.getspnam(user[0]).sp_pwd

  if phash != '*' and not phash.startswith('!'):
    qusers.append(user[0])

for user in qusers:
  subprocess.call(['edquota', '-u', user, '-p', sys.argv[1]])
