#!/bin/bash

MYIP=$(ifconfig eth2 | grep "inet addr" | awk -F 'addr:' '{ print $2 }' | cut -f1 -d" ")

function carica_pattern() {
	ldapsearch -xb "cn=admin,dc=labammsis" "(&(IP="$MYIP")(objectClass=blacklist))" | grep --line-buffered badstring | awk -F ': ' '{ print $2 }' | ( while read TOADD ; do	
	PATTERN+=("$TOADD") 
done )
}


declare -a PATTERN
trap carica_pattern SIGHUP

carica_pattern

./dump.sh | (while read line ; do
	
	for i in "${PATTERN[@]}" ; do
		if echo "$line" | grep "$i" ; then
			SIP=$( echo $line | cut -f1 )
			DIP=$( ehco $line | cut -f3 )
			logger -p local1.alert $SIP $DIP
		fi
	done
	
done )


################ configurazione rsyslogd
####Generico Target
# inserisco il file esame13072016.conf sotto la directory /etc/rsyslog.d/ con dentro scritto
#
# local1.=alert	@10.9.9.1
# local1.=alert @10.1.1.1
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
####Su OGNI CONTROLLER
# creo un file, sempre in /etc/rsyslog.d/, con lo stesso nome dell'altro (per coerenza) con scritto
#
# local1.=alert /var/log/anomalies
#
# e seguo gli stessi passi elencato sopra
