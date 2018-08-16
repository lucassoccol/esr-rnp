#!/bin/bash

BIN="asciidoctor-pdf"


usage() {
  echo "  Usage: $0 -w WEEK [-a]" >&2
  exit 1
}


a=0
while getopts ":w:a" opt; do
  case "$opt" in
    w)
      w=${OPTARG}
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

if ! [ -x "$(command -v $BIN)" ]; then
  echo "  [*] $BIN not in \$PATH." >&2
  exit 1
fi

cd w${w}
asciidoctor-pdf -a lang=pt_BR             -o pdf/caderno_w${w}.pdf  gabarito.adoc
asciidoctor-pdf -a lang=pt_BR -a gabarito -o pdf/gabarito_w${w}.pdf gabarito.adoc

if [ $a -eq 1 ]; then
  for file in $( ls include/*.adoc ); do
    s=$( echo $file | sed 's/.*_s\([0-9]*\).*/\1/' )
    asciidoctor-pdf -a lang=pt_BR -a oneof             -o pdf/_cadernos/caderno_w${w}_s${s}.pdf   $file
    asciidoctor-pdf -a lang=pt_BR -a oneof -a gabarito -o pdf/_gabaritos/gabarito_w${w}_s${s}.pdf $file
  done
fi
