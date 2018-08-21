#!/bin/bash
# Verificare se c'è un UID libero tra il più alto presente 
# nel file /etc/passwd e quello immediatamente inferiore.

MAX=$(cut -f3 -d: /etc/passwd | sort -nr | head -1)
SECOND=$(cut -f3 -d: /etc/passwd | sort -nr | head -2 | tail -1)
DIFF=$(( $MAX - $SECOND ))

if test $DIFF -gt 1 
then
	echo puoi aggiungere utenti tra $SECOND e $MAX
else
	echo non puoi aggiungere altri utenti
fi

# Equivalente al precedente
HIGHEST=0
SECOND=0

cut -f3 -d: /etc/passwd | ( while read U; do
	if test $U -gt $HIGHEST ; then
		SECOND=$HIGHEST
		HIGHEST=$U
	elif test $U -gt $SECOND ; then
		SECOND=$U
	fi
done 

echo $HIGHEST
echo $SECOND
)

# Stampare i nomi invece degli UID
cat /etc/passwd | ( while IFS=: read NAME X U RESTO ; do
	if test $U -gt $HIGHEST ; then
		SECOND=$HIGHEST
		SECONDNAME=$HIGHESTNAME
		HIGHEST=$U
		HIGHESTNAME=$NAME
	elif test $U -gt $SECOND ; then
		SECOND=$U
		SECONDNAME=$NAME
	fi
done 

echo $HIGHESTNAME
echo $SECONDNAME
)

# Stampare i nomi invece degli UID
cat /etc/passwd | sort -t: -k3nr | head -2 | ( 
IFS=: read HIGHESTNAME X HIGHESTID RESTO
IFS=: read SECONDNAME X SECONDID RESTO 
DIFF=$(( $HIGHESTID - $SECONDID ))
if test $DIFF -gt 1 
	then
		echo puoi aggiungere utenti tra $SECONDNAME e $HIGHESTNAME
else
	echo non puoi aggiungere altri utenti
fi
)


