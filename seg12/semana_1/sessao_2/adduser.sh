#!/bin/bash

usage() {
  echo "  Usage: $0 -u USER -p PASSWORD"
  exit 1
}


if [[ $EUID -ne 0 ]]; then
  echo "  [*] Not root!" 1>&2
	exit 1
fi

while getopts ":u:p:" opt; do
  case "$opt" in
    u)
      user=${OPTARG}
      ;;
    p)
      pass=${OPTARG}
      ;;
    *)
      usage
      ;;  
  esac
done

[ -z $user ] && { echo "  [*] No user?"; usage; }
[ -z $pass ] && { echo "  [*] No password?"; usage; }

if egrep "^${user}:" /etc/passwd &> /dev/null; then
	echo "  [*] User exists!"
	exit 1
fi

lastgid=$( getent group | grep -v 'nogroup' | cut -d':' -f3 | sort -n | tail -n1 )
((lastgid++))

echo "$user:x:$lastgid:" >> /etc/group
echo "$user:!::" >> /etc/gshadow

lastuid=$( getent passwd | grep -v 'nobody' | cut -d':' -f3 | sort -n | tail -n1 )
((lastuid++))

echo "$user:x:$lastuid:$lastgid:,,,:/home/$user:/bin/bash" >> /etc/passwd

salt="$( cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 8 | head -n 1 )"
hpass="$( mkpasswd -m sha-512 -S $salt -s <<< $pass )"
echo "$user:$hpass:16842:0:99999:7:::" >> /etc/shadow

cp -r /etc/skel /home/$user
chown ${user}.${user} /home/$user
