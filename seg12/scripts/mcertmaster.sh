#!/bin/bash


testzero() {
  a=("$@")
  v=1
  for i in "${a[@]}"; do
    [ $i -ne 0 ] && v=0
  done

  echo $v
}


testhundo() {
  a=("$@")
  v=1
  for i in "${a[@]}"; do
    [ $i -ne 100 ] && v=0
  done

  echo $v
}


lead() {
  echo "Olá $1, tudo bem?"
}


hasfile() {
  progress=()

  while read line; do
    IFS=', ' read -r -a var <<< "$line"
    progress+=(${var[1]})
  done < <(cat $cmdir/$1 | tr -d '\"' | grep "^$domain" | sed 's/^\([0-9.]*\)[A-Za-z ,.]*\(.*\)/\1,\2/' | cut -d',' -f1,2,5,6,7)

  prog_zero=$( testzero "${progress[@]}" )
  if [ $prog_zero -ne 1 ]; then
    prog_hundo=$( testhundo ${progress[@]} )
  fi

  echo -e "\nRevisando o seu progresso no Domínio $domain do CertMaster, apresento os seguintes resultados parciais:\n"

  prog_zero=0
  prog_hundo=0
  if [ $prog_zero -eq 1 ]; then
    echo "   Nenhum módulo iniciado"
  else
    while read line; do
      IFS=', ' read -r -a var <<< "$line"
      if [ ${var[1]} -eq 0 ]; then
        echo "   Módulo ${var[0]}: não iniciado"
      else
        echo "   Módulo ${var[0]}: ${var[1]}% realizado, ${var[4]}% de acertos, ${var[2]}% de erros e ${var[3]}% de dúvidas"
      fi
    done < <(cat $cmdir/$1 | tr -d '\"' | grep "^$domain" | sed 's/^\([0-9.]*\)[A-Za-z ,.]*\(.*\)/\1,\2/' | cut -d',' -f1,2,5,6,7)
  fi

  if [ $prog_hundo -eq 1 ]; then
    echo -e "\nTodos os módulos deste domínio foram realizados em sua totalidade, parabéns!"
  fi
}


nofile() {
  echo "Seu e-mail não consta do cadastro de alunos que já se inscreveram no site do CertMaster (https://certification.comptia.org/training/certmaster/login)."
}


msg_end() {
  echo -e "\nGostaríamos de frisar a grande importância que a realização do CertMaster tem no seu aprendizado neste curso: além de prepará-lo para a certificação Security+ SY0-401, as atividades em que você e seus colegas encontrarem mais dificuldades serão trabalhadas em maior detalhe em nosso próximo encontro virtual de revisão.

Agradecemos seu empenho e interesse! E, novamente, nos colocamos à disposição para responder quaisquer dúvidas pelo fórum do curso no AVA.

Bons estudos,

Equipe Acadêmica ESR/RNP"
}


# $1: email
# $2: primeiro nome
# $3: arquivo existe
send_mail() {
 { 
    echo To: $1
    echo From: fbscarel.esr@gmail.com 
    echo Subject: Relatório do Domínio $domain do CertMaster
    echo
    lead $2
    if [ $3 -eq 1 ]; then
      nofile
    else
      hasfile $1
    fi
    msg_end
 } | ssmtp $1
}


usage() {
  echo "  Usage: $0 -u USERDIR -d DOMAIN"
  echo "  User directory must exist and have 'cm_DOMAIN' dir and 'emails_cm' file"
  exit 1
}


while getopts ":u:d:" opt; do
  case "$opt" in
    u)
      udir=${OPTARG}
      ;;
    d)
      domain=${OPTARG}
      ;;
    *)
      usage
      ;;  
  esac
done

udir=$( readlink -f $udir )
[ -z $udir ] && { echo "  [*] No user dir?"; usage; }
[ ! -d $udir ] && { echo "  [*] User dir does not exist"; usage; }

emails="${udir}/emails_cm"
[ ! -f $emails ] && { echo "  [*] 'emails' file does not exist"; usage; }

cmdir="${udir}/cm_${domain}"
[ ! -d $cmdir ] && { echo "  [*] CM dir does not exist"; usage; }

while read line; do
  email=$( echo $line | cut -d':' -f1 )
  name=$( echo $line | cut -d':' -f2 )

  find $cmdir -name $email -print | egrep '.*' > /dev/null && nofile=0 || nofile=1
  send_mail $email $name $nofile
done < $emails
