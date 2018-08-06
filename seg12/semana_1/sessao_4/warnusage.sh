#!/bin/bash

parts=( $( df -h | egrep -e "^/dev" | awk {'print $6'} ) )
partusage=( $( df -h | egrep -e "^/dev" | awk {'print $5'} | tr -d % ) )
out="$( mktemp )"

for (( i=0; i<${#parts[@]}; i++ )); do
  if [ ${partusage[$i]} -gt 90 ]; then
    echo -e "Filesystem ${parts[$i]} over ${partusage[$i]}% capacity." >> $out
  fi
done

if  [ -e $out ]; then
  mail -s "Filesystem capacity report" root@localhost < $out
  rm -f $out
fi
