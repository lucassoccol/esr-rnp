#!/bin/bash

users=( $( last -w | egrep '(tty|pts)' | awk '{print $1}' | sort | uniq ) )

for user in "${users[@]}"; do
  times=( $( last -w | egrep "^$user " | egrep '(tty|pts)' | egrep -v 'still logged in *$' | sed 's/  *$//' | awk -F '[ :()]' '{printf "%s:%s\n", $(NF-2), $(NF-1)}' ) )

  h=0
  m=0
  for time in "${times[@]}" ; do
    s=( $( echo $time | tr ':' ' ' ) )
    ((h+=${s[0]}))
    ((m+=${s[1]}))
  done

  mh=$(($m/60))
  mr=$(($m%60))
  ((h+=$mh))

  echo "User \"$user\" logged time: $h hours, $mr minutes"
done
