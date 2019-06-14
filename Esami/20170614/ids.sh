#!/bin/bash

#Osserva senza interruzione tutto il traffico TCP tra le due reti, limitatamente ai primi 200
#byte di ogni pacchetto. Quando un pacchetto contiene un pattern compreso tra quelli elencati nel
#file /etc/blacklist.regex , invoca insert.sh passando come primo parametro l’ora corrente (con
#sufficiente precisione per evitare duplicati) e come secondo e terzo gli ip di sorgente e destinazione
#del pacchetto.
#Le stesse tre informazioni devono essere inviate all’altro router per mezzo di syslog.
#Indicare nei commenti: come configurare i demoni syslog dei router per consentire la scrittura sul
#file /var/log/packets.log di ognuno dei messaggi ricevuti dall’altro.

R1ETH2="10.1.1.1"
R9ETH2="10.1.1.254"

ATTUALE=$(ifconfig eth2 | grep "inet addr" | awk -F 'addr:' '{ print $2 }' | cut -f1 -d" ")

function monitor() {

	log=$2
	
	tcpdump tcp -i $1 -nnlXX -s200 | ( while read line ; do
	
	if ! echo $line | grep -q 0x ; then
		ORA=$( echo $line | awk -F  ' IP' '{ print $1 }' )
		SIP=$( echo $line | awk -F 'IP ' '{ print $2 }' | awk -F ' >' '{ print $1 }' |  awk -F. '{ if (NF == 2) { print $1 } else { print $1 FS $2 FS $3 FS $4 }}' )
		DIP=$( echo $line | awk -F '> ' '{ print $2 }' | awk -F ':' '{ print $1 }' |  awk -F. '{ if (NF == 2) { print $1 } else { print $1 FS $2 FS $3 FS $4 }}' )

	else
		cat /etc/blacklist.regex | ( while read reg ; do
			if echo $line | grep $reg ; then
				./ldapinsert.sh $ORA $SIP $DIP
				logger -p $log.info "$ORA $SIP $DIP"
			fi
		done )
	fi
done )

}



if [ $ATTUALE == $R1ETH2 ] ; then
	monitor eth2 local0
else
	monitor eth1 local1
fi 




################ configurazione rsyslogd
####R1
# inserisco il file esame14062017_R1.conf sotto la directory /etc/rsyslog.d/ con dentro scritto
#
# local0.=info	@10.9.9.1
#
# mi assicuro che nel file /etc/rsyslog.conf non siano commentate i due comandi per la comunicazione log remoto tramite udp
#
# $ModLoad imudp
# $UDPServerRun 514
#
# e poi riavvio il demone con il comando
#
# systemctl restart rsyslog
#
# su R9 creo invece un file, sempre in /etc/rsyslog.d/, con lo stesso nome dell'altro e con scritto
#
# local0.=info /var/log/packets.log
#
####R9
# inserisco il file esame14062017_R9.conf sotto la directory /etc/rsyslog.d/ con dentro scritto
#
# local1.=info	@10.1.1.1
#
# mi assicuro che nel file /etc/rsyslog.conf non siano commentate i due comandi per la comunicazione log remoto tramite udp
#
# $ModLoad imudp
# $UDPServerRun 514
#
# e poi riavvio il demone con il comando
#
# systemctl restart rsyslog
#
# su R9 creo invece un file, sempre in /etc/rsyslog.d/, con lo stesso nome dell'altro e con scritto
#
# local1.=info /var/log/packets.log
#
