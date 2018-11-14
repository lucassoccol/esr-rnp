#!/bin/bash

TMPFILE="$( mktemp )"
OUTFILE="${HOME}/hashes.txt"

rm -f ${OUTFILE}
touch ${OUTFILE}

ldapsearch -x                     \
  -LLL                            \
  -H ldap://10.0.42.2             \
  -D 'cn=admin,dc=intnet'         \
  -w 'rnpesr'                     \
  -b 'dc=intnet'                  \
  'userPassword=*'                \
  cn userPassword                 \
  | grep '^cn:\|^userPassword::'  \
  | awk '{print $NF}'             \
  | sed 'N;s/\n/ /'               \
  | tr ' ' ':' > ${TMPFILE}

while read l; do
  luser="$( echo ${l} | cut -d':' -f1 )"
  lhash="$( echo ${l} | cut -d':' -f2 )"

  echo "${luser}:$( echo ${lhash} | base64 --decode )" >> ${OUTFILE}
done < ${TMPFILE}

rm -f ${TMPFILE}
