#!/bin/bash


# exibir uso do script e sair
function usage() {
  echo "  Usage: $0 -h HOSTNAME -i IPADDR -g GATEWAY"
  echo "  Netmask is assumed as /24."
  exit 1
}


# testar sintaxe valida de HOSTNAME
function valid_host() {
  if [[ "$nhost" =~ [^a-z0-9] ]]; then
    echo "  [*] HOSTNAME must be lowercase alphanumeric: [a-z0-9]*"
    usage
  elif [ ${#nhost} -gt 63 ]; then
    echo "  [*] HOSTNAME must have <63 chars"
    usage
  fi
}


# testar sintaxe valida de IPADDR/GATEWAY
function valid_ip() {
  local  ip=$1
  local  stat=1

  if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
    OIFS=$IFS
    IFS='.'
    ip=($ip)
    IFS=$OIFS
    [[ ${ip[0]} -le 255 && \
       ${ip[1]} -le 255 && \
       ${ip[2]} -le 255 && \
       ${ip[3]} -le 255 ]]
        stat=$?
  fi

  if [ $stat -ne 0 ] ; then
    echo "  [*] Invalid syntax for $2"
    usage
  fi
}


while getopts ":g:h:i:" opt; do
  case "$opt" in
    g)
      ngw=${OPTARG}
      ;;
    h)
      nhost=${OPTARG}
      ;;
    i)
      nip=${OPTARG}
      ;;
    *)
      usage
      ;;
  esac
done

# testar se parametros foram informados
[ -z $ngw ]   && { echo "  [*] No gateway?"; usage; }
[ -z $nhost ] && { echo "  [*] No hostname?"; usage; }
[ -z $nip ]   && { echo "  [*] No ipaddr?"; usage; }

# testar sintaxe de parametros
valid_ip $nip "IPADDR"
valid_ip $ngw "GATEWAY"
valid_host $nhost

# alterar endereco ip/gateway
iff="/etc/network/interfaces"
cip="$( egrep '^address ' $iff | awk -F'[ /]' '{print $2}' )"
cgw="$( egrep '^gateway ' $iff | awk '{print $NF}' )"
sed -i "s|${cip}|${nip}|g" $iff
sed -i "s|${cgw}|${ngw}|g" $iff
ip addr flush label 'enp0s*'

# alterar hostname local
chost="$( hostname -s )"
sed -i "s/${chost}/${nhost}/g" /etc/hosts
sed -i "s/${chost}/${nhost}/g" /etc/hostname

invoke-rc.d hostname.sh restart
invoke-rc.d networking restart
hostnamectl set-hostname $nhost

# assinar chaves SSH
bash /root/scripts/sshsign.sh

# reiniciar sistema de autenticacao LDAP
systemctl restart nslcd.service
systemctl restart nscd.service

for table in `ls -1 /var/cache/nscd` ; do
  nscd --invalidate $table
done
