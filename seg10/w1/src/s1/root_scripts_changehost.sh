#!/bin/bash

[ -z $1 ] && { echo "Usage: $0 NEWHOSTNAME"; exit 1; }

sed -i "s/debian-template/$1/g" /etc/hosts
sed -i "s/debian-template/$1/g" /etc/hostname

invoke-rc.d hostname.sh restart
invoke-rc.d networking force-reload
hostnamectl set-hostname $1

rm -f /etc/ssh/ssh_host_* 2> /dev/null
dpkg-reconfigure openssh-server &> /dev/null
