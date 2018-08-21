#!/bin/bash
# 
# lanciare in parallelo tutti i comandi specificati come parametri e monitorare ogni 5 secondi se sono ancora in esecuzione o no, scrivendo sul file "log" lo stato dei due processi e terminando l'esecuzione quando tutti terminano.

# strumenti da utilizzare:
# esecuzione in background
# variabile speciale $!
# sleep, while, ps (jobs?), echo
# array della shell

# rm -f log 2> /dev/null && touch log
cat /dev/null > log

N=0
unset PID NOME
for CMD in "$@" ; do
	N=$(( $N + 1 ))
	$CMD & PID[$N]=$! 
	NOME[$N]="$CMD"
done

while ps ${PID[@]} > /dev/null ; do
	sleep 5
	for P in `seq 1 $N` ; do
		echo -n "${NOME[$P]}: "
		if ps "${PID[$P]}" > /dev/null ; then
			echo -n "running; "
		else
			echo -n "ended; "
		fi
	done >> log
	echo >> log
done


