#!/bin/bash

CLASSTIME="9h"


falta() {
echo "Olá $1, tudo bem?

Não encontrei você em sala hoje, $curdate, em nosso encontro virtual às $CLASSTIME. Sentimos sua falta! Houve algum problema de ordem técnica, ou alguma outra situação que impediu sua participação? Se você tiver entrado na sala com algum apelido diferente ou em momento posterior à verificação, pode ser que eu não tenha te visto, também.

Se houver qualquer coisa que possamos fazer para facilitar sua experiência no curso, por favor entre em contato! Relembro que nosso próximo encontro virtual será nesta $futweekday, dia $futdate, às $CLASSTIME. Nos vemos lá!

Bons estudos,

Equipe Acadêmica ESR/RNP"
}


simulado() {
echo "Olá $1, tudo bem?

Observei que você não teve a oportunidade de fazer o simulado do Domínio $domain até o prazo limite. Que pena! Mas fique tranquilo, pois todos os simulados serão reabertos ao final do curso para revisão, e também para quem os perdeu na primeira oportunidade.

Se houver qualquer coisa que possamos fazer para facilitar sua experiência no curso, por favor entre em contato! Relembro que nosso próximo encontro virtual será nesta $futweekday, dia $futdate, às $CLASSTIME. Nos vemos lá!

Bons estudos,

Equipe Acadêmica ESR/RNP"
}


# $1: operação
# $2: email
# $3: primeiro nome
send_mail() {
  { 
    echo To: $2
    echo From: fbscarel.esr@gmail.com 
    case $1 in
      "falta")
        echo Subject: Encontro virtual do dia $curdate
        echo
        falta $3
        ;;
      "simulado")
        echo Subject: Simulado do domínio $domain
        echo
        simulado $3
        ;;
    esac
  } | ssmtp $2
}


usage() {
  echo "  Usage: $0 -c CURDATE -f FUTDATE -w USERFILE -o OPERATION [-d DOMAIN]"
  echo "  Date syntax: YYYY-MM-DD"
  echo "  User file syntax (per line): NAME:EMAIL"
  echo "  Operation syntax: falta | simulado"
  exit 1
}


while getopts ":c:f:w:o:d:" opt; do
  case "$opt" in
    c)
      cdate=${OPTARG}
      ;;
    f)
      fdate=${OPTARG}
      ;;
    w)
      ufile=${OPTARG}
      ;;
    o)
      operation=${OPTARG}
      ;;
    d)
      domain=${OPTARG}
      ;;
    *)
      usage
      ;;  
  esac
done

[ -z $cdate ] && { echo "  [*] No current date?"; usage; }
[ -z $fdate ] && { echo "  [*] No future date?"; usage; }
[ -z $ufile ] && { echo "  [*] No user file?"; usage; }
[ ! -f $ufile ] && { echo "  [*] User file does not exist"; usage; }

if [ $operation != "falta" ] && [ $operation != "simulado" ]; then
  echo "  [*] Valid ops: [falta] or [simulado]"
  usage
elif [ $operation == "simulado" ] && [ -z $domain ]; then
  echo "  [*] DOMAIN required for op [simulado]"
  usage
fi

curdate=$( date -d $cdate "+%d de %B de %Y" )
futdate=$( date -d $fdate "+%d de %B de %Y" )
futweekday=$( date -d $fdate "+%A" )

while read line; do
  name=$( echo $line | cut -d':' -f1 )
  email=$( echo $line | cut -d':' -f2 )
  send_mail $operation $email $name
done <$ufile
