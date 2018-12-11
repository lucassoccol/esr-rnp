#!/bin/bash

rm -f test ; \
d=$(pwd | awk -F'/' '{print $NF}') ; \
for f in $( ls -1 | egrep '[a-z]*[0-9]+.(png|txt)' | sort -V | cut -d'.' -f1 ) ; \
do echo -e ".desc\n[#img-${f}]\nimage::${d}/${f}.png[align="center"]\n" >> test ; \
done ; \
unset d
