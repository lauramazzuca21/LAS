#!/bin/bash

function forwardjump() {
	iptables -$1 FORWARD -p tcp -s $2 -d $3 --sport $4 --dport $5 -j $6
	iptables -$1 FORWARD -p tcp -d $2 -s $3 --dport $4 --sport $5 -j $6
}
	
# Apr 27 12:02:56 router kernel: [10139.999098]  INIZIO IN=eth2 OUT=eth1 MAC=08:00:27:27:a6:e6:08:00:27:24:9b:d5:08:00 SRC=10.1.1.1 DST=10.9.9.1 LEN=60 TOS=0x00 PREC=0x00 TTL=63 ID=23272 DF PROTO=TCP SPT=37668 DPT=22 WINDOW=29200 RES=0x00 SYN URGP=0

# opzioni dei comandi
# tail --pid $$ garantisce che tail termini quando termina il processo principale
# grep --line-buffered e awk -W interactive evitano il buffering, ogni linea 
# prodotta va direttamente in output
#
# notare che awk taglia sulla "]" evitando il problema dovuto al timestamp precedente,
# che potrebbe riempire o non riempire le [] modificando la numerazione dei campi seguenti

tail --pid=$$ -f /var/log/newconn | egrep --line-buffered 'INIZIO|FINE' | awk -W interactive -F ']' '{ print $2 }' | while read EVENTO IN OUT MAC SRC DST LEN TOS PREC TTL ID DF PROTO SPT DPT RESTO ; do
	SOURCEIP=$(echo $SRC | cut -f2 -d=)
	SOURCELASTBYTE=$(echo $SOURCEIP | cut -f4 -d.)
	DESTIP=$(echo $DST | cut -f2 -d=)
	DESTLASTBYTE=$(echo $DESTIP | cut -f4 -d.)
	SOURCEPORT=$(echo $SPT | cut -f2 -d=)
	DESTPORT=$(echo $DPT | cut -f2 -d=)
	CHAIN="CONTA-$SOURCELASTBYTE-$DESTLASTBYTE-$SOURCEPORT-$DESTPORT"

	# uso una custom chain semplicemente per metterci dentro una sola regola
	# salto poi nella custom chain dalla catena FORWARD, sia per i pacchetti
	# in andata che in ritorno: la regola della custom chain quindi somma
	# automaticamente i traffici, semplificando il successivo rilevamento
	#
	# notare che si usa solo l'ultimo byte degli indirizzi, che in questo 
	# specifico caso è suffciente a individuare le macchine, perche' le 
	# catene hanno nomi limitati a 32 caratteri

	case $EVENTO in 
		INIZIO)
			iptables -N $CHAIN
			iptables -I $CHAIN -j RETURN
			forwardjump I $SOURCEIP $DESTIP $SOURCEPORT $DESTPORT $CHAIN
		;;
		FINE)
			forwardjump D $SOURCEIP $DESTIP $SOURCEPORT $DESTPORT $CHAIN
			iptables -F $CHAIN
			iptables -X $CHAIN
		;;
		*)
			echo "evento sconosciuto $EVENTO"
		;;
	esac
done
