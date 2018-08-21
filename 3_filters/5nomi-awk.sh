#!/bin/bash
# Stampare gli username corrispondenti agli N più elevati userid presenti 
# nel file /etc/passwd, essendo N un parametro passato sulla riga di comando.	


if [ $# -ne 1 ]; then
	echo "error: usage $0 N" >&2; exit 1
fi

re='^[0-9]+$'
if ! [[ $1 =~ $re ]] ; then
   echo "error: Not a number" >&2; exit 1
fi

cat /etc/passwd | awk -F ':' '{ print $3,$1 }' | sort -nr | head -$1 | cut -f2 -d" "

