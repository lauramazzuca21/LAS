#!/bin/bash
#
# $0 = nome comando
# $1 = primo argomento...
# $# = n. di argomenti
# ... limitatamente all'elenco di estensioni passate come parametri sulla riga di comando.

# migliore: il primo parametro è la cartella in cui cercare

DIR="$1"
shift
REG="\.($1"
shift
for ESTENSIONE in "$@" 
do
    REG="$REG|$ESTENSIONE"
done
REG="$REG)$"

find "$DIR" -type f | egrep "$REG" | rev | cut -f1 -d. | rev | sort | uniq -c 







