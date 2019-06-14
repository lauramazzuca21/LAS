#!/bin/bash

# controllo parametri
if ! echo "$1" | egrep -q "10.9.9.([1-9][0-9]?|100)$" ; then
	echo "primo parametro errato"
	exit 1
fi

if ! test -x "$2" ; then
	echo "secondo parametro errato" 
	exit 2
fi

if test "$3" ; then
	echo "troppi parametri"
	exit 3
fi

if ps -hao uname,cmd | grep -w 'exec\.sh' | grep -qvw $(whoami)
then
        echo "$0 gia in esecuzione"
        exit 4
fi

MYIP=$(ip a | grep "scope global eth2" | awk '{ print $2 }' | cut -d/ -f1)

logger -p local1.info "EXEC___${MYIP}___${1}___"

count=0

while ! ping -c1 -w1 10.1.1.254 > /dev/null 2>&1
do
        echo "In attesa che RF risponda..."
        if test "$count" -gt 9 
        then
                echo "Il router non risponde"
                exit 5
        fi
        count=$(( "$count" + 1 ))
done

echo "Ha risposto connessione avviata con $1"

PROG=$(basename "$2")
scp "$2" "$1":"$PROG"
ssh "$1" "./$PROG" > ~/out  2> ~/err

########

