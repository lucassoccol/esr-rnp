#!/bin/bash

# instalacao
DEBIAN_FRONTEND=noninteractive apt-get -yq install openntpd

# configuracao
mv /etc/openntpd/ntpd.conf /etc/openntpd/ntpd.conf.orig
echo "server 10.0.42.4" > /etc/openntpd/ntpd.conf

# reiniciar ntpd
systemctl restart openntpd.service
