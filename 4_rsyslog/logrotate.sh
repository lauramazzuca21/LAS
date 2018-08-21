#!/bin/bash

# realizzare uno script che accetti sulla riga di comando
# 
# - "-n" seguito da un numero (opzionale) 	NCOPIES
# - "-s" seguito da una stringa (opzionale)	LOGSIGNAL
# - una stringa LOGFILE
# 
# lo script "ruota" il file LOGFILE tenendo NCOPIES (default 4) 
# copie e manda al produttore del file il segnale LOGSIGNAL 
# (default USR1) per avvertirlo al momento giusto di chiudere
# e riaprire il file.

THIS=/home/las/niceexec.sh

NCOPIES=4
LOGSIGNAL=USR1

while getopts "n:s:" OPTION ; do
	case $OPTION in
		n)	NCOPIES="$OPTARG"
			;;
		s)	LOGSIGNAL="$OPTARG"
			;;
		?)	printf "Usage: %s [-n copies to keep] [-s signal to send] filename\n" $(basename $0) >&2
			exit 1
			;;
	esac
done

if /usr/bin/tty > /dev/null ; then
	# invocato da terminale, controllo parametri
	if ! [[ $NCOPIES =~ ^[0-9]+$ ]] ; then
		echo "-n must be followed by an integer number"
		exit 2
	fi

	# leggere la man page di kill per il suggerimento sul path completo
	# osservare la differenza tra kill -l e /bin/kill -l
	if ! /bin/kill -l | grep -w "$LOGSIGNAL" ; then
		echo "-s must be followed by a valid signal name ("$(/bin/kill -l)
		exit 3
	fi

	shift $(($OPTIND - 1))
	if ! test -f "$1" ; then
		echo "$1 is not a regular file"
		exit 4
	fi

	LOGFILE=$1

	# configuro cron per l'esecuzione
	/usr/bin/crontab -l | grep -v "$THIS -n $NCOPIES -s $LOGSIGNAL $LOGFILE" > /tmp/niceexec.cron.$$
	echo "00 22 * * 1-5 $THIS -n $NCOPIES -s $LOGSIGNAL $LOGFILE" >> /tmp/niceexec.cron.$$
	/usr/bin/crontab /tmp/niceexec.cron.$$
	/bin/rm -f /tmp/niceexec.cron.$$
else
	# invocato da cron, ruota file

	# sposta $FNAME.9 in $FNAME.10 sovrascrivendolo
	# sposta $FNAME.8 in $FNAME.9 eccetera
	# alla fine non esistera' piu' $FNAME.1

	for i in $(seq $(( $NCOPIES - 1 )) -1 1) ; do
		test -f $LOGFILE.$i && mv $LOGFILE.$i $LOGFILE.$(( $i + 1 ))
	done

	# rinomina il file aperto dal processo di logging, 
	# che contina a scrivere sullo stesso inode col nuovo nome
	mv $LOGFILE $LOGFILE.1

	# segnala al logger di chiudere i file aperti e riaprirli 
	# (seguendo la propria configurazione, il logger ricrea 
	# quindi il file col nome originale)
	fuser -k -$LOGSIGNAL $LOGFILE.1
fi
	
	
	
	
	
	
	
	
