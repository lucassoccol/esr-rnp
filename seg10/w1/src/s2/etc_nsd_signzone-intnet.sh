#!/bin/bash

ZSK="Kintnet.+007+12293"
KSK="Kintnet.+007+04740"
ZONE_FILE="intnet.zone"

cd /etc/nsd

ldns-signzone -n \
  -p \
  -s $(head -n 1000 /dev/random | sha1sum | cut -b 1-16) \
  $ZONE_FILE \
  $ZSK \
  $KSK

nsd-control reconfig
nsd-control reload intnet
nsd-control reload 42.0.10.in-addr.arpa
