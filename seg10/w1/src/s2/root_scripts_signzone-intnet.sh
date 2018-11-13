#!/bin/bash

ZSK="ZSKSTUB"
KSK="KSKSTUB"
ZONE_FILE="/etc/nsd/zones/intnet.zone"

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
unbound-control flush_zone intnet.
