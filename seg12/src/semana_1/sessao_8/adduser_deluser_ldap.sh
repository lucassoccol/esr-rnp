#!/bin/bash

tlocal_user() {
  egrep "^${1}:" /etc/passwd &> /dev/null && return 1 || return 0
}


tldap_user() {
  qlu=$( ldapsearch -x -LLL -b "dc=empresa,dc=com,dc=br" "(uid=${1})" | grep "^uid:" | awk '{print $2}' )
  [ ! -z $qlu ] && return 1 || return 0
}


# $1 ldap_admin, $2 ldap_password, $3: user , $4: pass
r_adduser() {
  if ! tlocal_user $3; then
    echo "  [*] Local user exists!"
    exit 1
  elif ! tldap_user $3; then
    echo "  [*] LDAP user exists!"
    exit 1
  fi    

  useradd -m -K UID_MIN=5000 -K GID_MIN=5000 -G esr $3
  echo "$3:$4" | chpasswd

  cd /usr/share/migrationtools/
  ./migrate_passwd.pl /etc/passwd | awk "/dn: uid=$3,ou=People,dc=empresa,dc=com,dc=br/,/^$/" | ldapadd -x -w $2 -D $1
  ./migrate_group.pl /etc/group | awk "/dn: cn=$3,ou=Group,dc=empresa,dc=com,dc=br/,/^$/" | ldapadd -x -w $2 -D $1
}


# $1 ldap_admin, $2 ldap_password, $3: user
r_deluser() {
  if tlocal_user $3; then
    echo "  [*] Local user does not exist!"
    exit 1
  elif tldap_user $3; then
    echo "  [*] LDAP user does not exist!"
    exit 1
  fi    

  deluser --remove-home $3

  ldapdelete -x -w $2 -D $1 "uid=$3,ou=People,dc=empresa,dc=com,dc=br"
  ldapdelete -x -w $2 -D $1 "cn=$3,ou=Group,dc=empresa,dc=com,dc=br"
}


usage() {
  echo "  Usage: $0 -l LDAP_ADMIN -w LDAP_PASSWD -u USER [-a|-d] [-p PASSWD]"
  exit 1
}


# - - - main() - - -


if [[ $EUID -ne 0 ]]; then
  echo "  [*] Not root!" 1>&2
  exit 1
fi

while getopts ":adu:p:l:w:" opt; do
  case "$opt" in
    l)
      ladmin=${OPTARG}
      ;;
    w)
      lpass=${OPTARG}
      ;;
    u)
      user=${OPTARG}
      ;;
    p)
      pass=${OPTARG}
      ;;
    a)
      uadd=1
      ;;
    d)
      udel=1
      ;;
    *)
      usage
      ;;  
  esac
done

[ -z $ladmin ] && { echo "  [*] No LDAP admin?"; usage; }
[ -z $lpass ] && { echo "  [*] No LDAP password?"; usage; }
[ -z $user ] && { echo "  [*] No user?"; usage; }

if [ -z $uadd ] && [ -z $udel ]; then
  echo "  [*] Choose '-a' (add) or '-d' (delete)."
  usage
elif (($uadd)) && (($udel)); then
  echo "  [*] Do not use '-a' (add) and '-d' (delete) simultaneously."
  usage
fi

if (($uadd)) && [ -z $pass ]; then
  echo "  [*] '-p' (password) mandatory with '-a' (add)."
  usage
fi

(($uadd)) && r_adduser $ladmin $lpass $user $pass
(($udel)) && r_deluser $ladmin $lpass $user

