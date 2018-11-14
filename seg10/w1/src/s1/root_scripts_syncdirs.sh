#!/bin/bash

for d in tmp var usr; do
  [ -d /mnt/${d} ] || mkdir /mnt/${d}
  mount /dev/mapper/vg--base-lv--${d} /mnt/${d}
  rsync -av /${d}/ /mnt/${d}
  umount /mnt/${d}
  rmdir /mnt/${d}
done
