#!/bin/bash

function aggiorna_entry() {

#	if test -z ldapsearch -xb -D "cn=admin,dc=labammsis" -w admin  "dn: server=$IPS,dc=labammsis" -s one ; then
#		ldapadd -x -D "cn=admin,dc=labammsis" -w admin  "dn: server=$IPS,dc=labammsis"
#	fi
	
	TS=$(/bin/date +%s)
        ENTRY="dn: ts=$TS,server=$IPS,dc=labammsis\nobjectClass: data"
        for i in "${!PORTCOUNT[@]}"
	do
	  ENTRY="$ENTRY\nports: $i/_${PORTCOUNT[$i]}"
	done
	for i in "${!SIPSUM[@]}"
	do
	  ENTRY="$ENTRY\ntraffic: $i/_${SIPSUM[$i]}"
	done

	echo "$ENTRY\n\n" 
	#| ldapadd -x -D "cn=admin,dc=labammsis" -w admin
	
	
}


IPS=$1

# signal handler per segnale USR1
trap 'aggiorna_entry' USR1


#esempio di output
# Aug 28 19:55:12 Router kernel: [ 8210.367631]  myIP:10.1.1.254 IN=eth2 OUT= MAC=08:00:27:fa:b3:bd:08:00:27:31:9d:37:08:00 SRC=10.1.1.1 DST=10.1.1.254 LEN=52 TOS=0x08 PREC=0x00 TTL=64 ID=64432 DF PROTO=TCP SPT=36241 DPT=22 WINDOW=1032 RES=0x00 ACK URGP=0

# opzioni dei comandi
# tail --pid $$ garantisce che tail termini quando termina il processo principale
# grep --line-buffered e awk -W interactive evitano il buffering, ogni linea 
# prodotta va direttamente in output
#
# dichiaro due array ASSOCIATIVI, al posto di array indicizzati
#
declare -A PORTCOUNT
declare -A SIPSUM

tail --pid=$$ -f /var/log/pacchetti.log | egrep --line-buffered 'myIP:$IPS' | awk -W interactive -F ']' '{ print $2 }' | while IFS="=" read EVENTO IN OUT MAC SRC DST LEN TOS PREC TTL ID DF PROTO SPT DPT REST ; do
	SOURCEIP=$(echo $SRC | cut -f2 -d=)
	SOURCEPORT=$(echo $SPT | cut -f2 -d=)
	BYTEREC=$(echo $LEN | cut -f2 -d=)
	if ! test -z $SOURCEPORT ; then 
		$PORTCOUNT[$SOURCEPORT]=$(( $PORTCOUNT[$SOURCEPORT] + 1 ))
	fi
	if ! test -z $SOURCEIP ; then
		$SIPSUM[$SOURCEIP]=$(( $SIPSUM[$SOURCEIP] + $BYTEREC ))
	fi
done


################ configurazione rsyslogd
# inserisco il file esame13092017.conf sotto la directory /etc/rsyslog.d/ con dentro scritto
#
# kern.=debug	/var/log/pacchetti.log
#
# mi assicro che nel file /etc/rsyslog.conf non siano commentate i due comandi per la comunicazione log remoto tramite udp
#
# $ModLoad imudp
# $UDPServerRun 514
#
# e poi riavvio il demone con il comando
#
# systemctl restart rsyslog



