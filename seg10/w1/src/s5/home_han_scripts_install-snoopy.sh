#!/bin/bash

# instalacao
DEBIAN_FRONTEND=noninteractive apt-get -yq install snoopy

# configuracao
echo "/lib/snoopy.so" > /etc/ld.so.preload
