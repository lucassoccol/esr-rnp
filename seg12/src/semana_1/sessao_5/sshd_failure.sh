#!/bin/bash

if [[ $EUID -ne 0 ]]; then
  echo "  [*] Not root!" 1>&2
  exit 1
fi

while read -r line; do
  s=( $( echo $line ) )
  echo -e "Host ${s[1]}: ${s[0]} failed logins"
done < <( grep "(sshd.auth): authentication failure.*rhost=" /var/log/auth.log | awk '{print $14}' | cut -d'=' -f2 | sort -n | uniq -c )
