#!/bin/bash

users=( $( ps aux | awk '{ if (NR>1) print $1 }' | sort | uniq ) )

for (( i=0; i<${#users[@]}; i++ )); do
  nproc=$( ps aux | grep "${users[$i]}" | wc -l )
  echo "User ${users[$i]} has $nproc active processes"
done
