#!/bin/bash

pinit=( $( ps -eo ppid,comm | egrep -e "^ *1 " | sort | uniq | awk {'print $2'} ) )
pinit_count=${#pinit[@]}

echo "$pinit_count processes started by init (1):"

for (( i=0; i<$pinit_count; i++ )); do
  echo "  ${pinit[$i]}"
done
