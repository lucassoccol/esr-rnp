#!/bin/bash

users=( $( ps aux | awk {'print $1'} | grep -v USER | sort | uniq ) )

for (( i=0; i<${#users[@]}; i++ )); do
  nproc=$( ps aux | grep "${users[$i]}" | wc -l )
  echo "User ${users[$i]} has $nproc active processes"
done
