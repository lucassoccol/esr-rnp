#!/bin/bash

BACKUP_DIR="/root/user_backups"

usage() {
  echo "  Usage: $0 -u USER [-b]"
  echo "  Use [-b] to backup user dir to /root before deletion."
  exit 1
}


if [[ $EUID -ne 0 ]]; then
  echo "  [*] Not root!" 1>&2
  exit 1
fi

backup=false
while getopts ":u:b" opt; do
  case "$opt" in
    u)
      user=${OPTARG}
      ;;
    b)
      backup=true
      ;;
    *)
      usage
      ;;  
  esac
done

[ -z $user ] && { echo "  [*] No user?"; usage; }

if ! egrep "^${user}:" /etc/passwd &> /dev/null; then
  echo "  [*] User does not exist!"
  exit 1
fi

homedir=$( getent passwd | egrep "^$user:" | cut -d':' -f6 )

if $backup; then
  [ ! -d $BACKUP_DIR ] && mkdir $BACKUP_DIR
  tar czf $BACKUP_DIR/${user}.tar.gz $homedir
fi
rm -rf /home/$user

sed -i "/^$user:/d" /etc/group
sed -i "/^$user:/d" /etc/gshadow
sed -i "/^$user:/d" /etc/passwd
sed -i "/^$user:/d" /etc/shadow

# remove user from secondary groups
sed -r -i "s/,?${user},?/,/ ; s/:,/:/ ; s/,$//" /etc/group
