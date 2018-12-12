#!/bin/bash

rm -f test1
d=$(pwd | awk -F'/' '{print $NF}')
for f in $( ls -1 | egrep '[a-z]*[0-9]+[-a-z]*.(png|txt)' | sort -V ) ; do
  pref=$( echo ${f} | cut -d'.' -f1 )
  suff=$( echo ${f} | cut -d'.' -f2 )
  if [ $suff == 'png' ]; then
    echo -e ".desc\n[#img-${pref}]\nimage::${d}/${f}[align="center"]\n" >> test1
  else
    echo -e ".text: ${f}\n---\n$(cat ${f} )\n---\n" >> test1
  fi
done
iconv -f ISO-8859-1 -t UTF-8 test1 > test2
mv test2 test1
unset d
