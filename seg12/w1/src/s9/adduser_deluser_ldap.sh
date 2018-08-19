#!/bin/bash


tldap_user() {
  qlu=$( ldapsearch -x -LLL -b "dc=empresa,dc=com,dc=br" "(uid=${1})" | grep "^uid:" | awk '{print $2}' )
  [ ! -z $qlu ] && return 1 || return 0
}


# $1 ldap_admin, $2 ldap_password, $3: user, $4: pass
r_adduser() {
  if ! tldap_user $3; then
    echo "  [*] LDAP user exists!"
    exit 1
  fi    

  lastuid=$( ldapsearch -x -LLL '(&(objectClass=posixAccount)(uid=*)(!(uid=nobody)))' uidNumber | grep  '^uidNumber:' | awk '{print $2}' | sort -n | tail -n1 )
  lastgid=$( ldapsearch -x -LLL '(&(objectClass=posixGroup)(cn=*)(!(cn=nogroup)))' gidNumber | grep  '^gidNumber:' | awk '{print $2}' | sort -n | tail -n1 )

  ((lastuid++))
  ((lastgid++))

  ldapadd -x -D $1 -w $2 << EOF
dn: uid=$3,ou=People,dc=empresa,dc=com,dc=br
uid: $3
cn: $3
objectClass: account
objectClass: posixAccount
objectClass: top
objectClass: shadowAccount
shadowMax: 99999
shadowWarning: 7
loginShell: /bin/bash
uidNumber: $lastuid
gidNumber: $lastgid
homeDirectory: /home/$3
gecos: $3,,,

EOF

  ldapadd -x -D $1 -w $2 << EOF
dn: cn=$3,ou=Group,dc=empresa,dc=com,dc=br
objectClass: posixGroup
objectClass: top
cn: $3
gidNumber: $lastgid

EOF

  ldappasswd -x -D $1 -w $2 -s $4 "uid=$3,ou=People,dc=empresa,dc=com,dc=br"
}


# $1 ldap_admin, $2 ldap_password, $3: user
r_deluser() {
  if tldap_user $3; then
    echo "  [*] LDAP user does not exist!"
    exit 1
  fi    

  ldapdelete -x -D $1 -w $2 "uid=$3,ou=People,dc=empresa,dc=com,dc=br"
  ldapdelete -x -D $1 -w $2 "cn=$3,ou=Group,dc=empresa,dc=com,dc=br"
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

