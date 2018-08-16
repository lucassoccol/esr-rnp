#!/bin/bash

IFS=':'
useradd="$( which useradd )"
groupadd="$( which groupadd )"


usage() {
  echo "  Usage: $0 -f NEWUSERS_FILE"
  echo "  File syntax: username:password:uid:gid:gecos:homedir:shell"
  exit 1
}


if [[ $EUID -ne 0 ]]; then
  echo "  [*] Not root!" 1>&2
  exit 1
fi

while getopts ":f:" opt; do
  case "$opt" in
    f)
      file=${OPTARG}
      ;;
    *)
      usage
      ;;
  esac
done

[ -z $file ] && { echo "  [*] No file?"; usage; }

while read username password uid gid gecos homedir shell; do
  if egrep "^${username}:" /etc/passwd &> /dev/null; then
    echo "  [*] User $username already exists, skipping..."
  elif getent passwd | cut -d':' -f3 | grep "$uid" &> /dev/null; then
    echo "  [*] UID $uid already exists, skipping..."
  elif getent group | cut -d':' -f3 | grep "$gid" &> /dev/null; then
    echo "  [*] GID $gid already exists, skipping..."
  else
    hpass="$( mkpasswd -m sha-512 -s <<< $pass )"
    $groupadd $username -g $gid
    $useradd $username -p $( mkpasswd -m sha-512 -s <<< $password)  -u $uid -g $gid -c "$gecos" -d $homedir -s $shell
    cp -r /etc/skel $homedir
    chown -R $username:$username $homedir
  fi
done < "$file"
