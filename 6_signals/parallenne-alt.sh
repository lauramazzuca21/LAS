#!/bin/bash
# 
# lanciare in parallelo tutti i comandi specificati come parametri e monitorare ogni 5 secondi se sono ancora in esecuzione o no, scrivendo sul file "log" lo stato dei due processi e terminando l'esecuzione quando entrambi terminano.

# strumenti da utilizzare:
# esecuzione in background
# variabile speciale $!
# sleep, while, ps (jobs?), echo
# array della shell

cat /dev/null > log

unset NOME
for CMD in "$@" ; do
	$CMD & NOME[$!]="$CMD"
done

trap 'kill -9 ${!NOME[@]}' EXIT

while ps ${!NOME[@]} > /dev/null ; do
	sleep 5
	for P in ${!NOME[@]} ; do
		echo -n "${NOME[$P]}: "
		# opzioni di ps: no header, output only command name
		# la pipeline con grep garantisce che al PID sia associato
		# ancora il comando originale
		if ps ho cmd $P | grep -q "${NOME[$P]}" ; then
			echo -n "running; "
		else
			echo -n "ended; "
		fi
	done >> log
	echo >> log
done




