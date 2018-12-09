#!/bin/bash

BIN="asciidoctor-pdf"


usage() {
  echo "  Usage: $0 -w WEEK -t TYPE [-a]" >&2
  echo "  TYPE either pdf or html"
  exit 1
}


tgab() {
  [ "$1" == "gabarito" ] && echo "-a $1" || echo
}


toplevel() {
  flag="$( tgab $1 )"

  echo "Converting top-level '${1}'..."

  if [ $t == "pdf" ]; then
    asciidoctor-pdf -a pdf-style=../share/rnp-theme.yml -a lang=pt_BR $flag -o pdf/${1}_w${w}_temp.pdf gabarito.adoc
    gs -q -sPAPERSIZE=a4 -dNOPAUSE -dBATCH -sDEVICE=pdfwrite -sOutputFile=pdf/${1}_w${w}.pdf  share/capa_w${w}.pdf pdf/${1}_w${w}_temp.pdf
    rm -f pdf/${1}_w${w}_temp.pdf
  else
    asciidoctor -o html/${1}_w${w}.html gabarito.adoc
  fi
}


oneof() {
  flag="$( tgab $1 )"
  s=$( echo $2 | sed 's/.*_s\([0-9]*\).*/\1/' )

  echo "Converting oneof '${1}', session '${s}'..."
  if [ $t == "pdf" ]; then
    asciidoctor-pdf -a pdf-style=../share/rnp-theme.yml -a lang=pt_BR -a oneof $flag -o pdf/_${1}s/${1}_w${w}_s${s}.pdf $2
  else
    asciidoctor -a oneof $flag -o html/_${1}s/${1}_w${w}_s${s}.html $2
  fi
}


a=0
while getopts ":w:t:a" opt; do
  case "$opt" in
    w)
      w=${OPTARG}
      ;;
    t)
      t=${OPTARG}
      ;;
    a)
      a=1
      ;;
    *)
      usage
      ;;
  esac
done

[ -z $w ] && { echo "  [*] No WEEK specified." >&2; usage; }
if [ $w -ne 1 ] && [ $w -ne 2 ]; then
  echo "  [*] WEEK value must be 1 or 2." >&2
  usage
fi

[ -z $t ] && t="pdf"

if ! [ -x "$(command -v $BIN)" ]; then
  echo "  [*] $BIN not in \$PATH." >&2
  exit 1
fi

cd w${w}
toplevel "caderno"
toplevel "gabarito"

if [ $a -eq 1 ]; then
  for file in $( ls include/*.adoc ); do
    oneof "caderno"  $file
    if grep 'ifdef::gabarito\[\]' $file > /dev/null; then
      oneof "gabarito" $file
    fi
  done
fi
