#!/bin/bash

# Caderno:  ./compile_pdf.sh -f gabarito_semana1.adoc -o _caderno_semana1.pdf
# Gabarito: ./compile_pdf.sh -f gabarito_semana1.adoc -o _gabarito_semana1.pdf -g

BIN="asciidoctor-pdf"


usage() {
  echo "  Usage: $0 [-g] [-o OUTFILE] -f ADOC_FILE" >&2
  exit 1
}


while getopts ":f:o:g" opt; do
  case "$opt" in
    f)
      file=${OPTARG}
      ;;
    o)
      outfile="-o ${OPTARG}"
      ;;
    g)
      gabarito="-a gabarito"
      ;;
    *)
      usage
      ;;
  esac
done

[ -z $file ] && { echo "  [*] No '.adoc' file specified." >&2; usage; }

if ! [ -x "$(command -v $BIN)" ]; then
  echo "  [*] $BIN not in \$PATH." >&2
  exit 1
fi

asciidoctor-pdf $gabarito $outfile $file
