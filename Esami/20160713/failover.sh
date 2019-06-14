#!/bin/bash


function controller_attivo() {
	local OID=$(snmpwalk -v 1 -c public 10.$1.$1.1 "UCD-SNMP-MIB::prNames" | grep "check.sh" | awk -F "prNames." '{ print $2 }') | awk -F "=" '{ print $1 }')

	snmpget -v 1 -c public 10.$1.$1.1 "UCD-SNMP-MIB::prErrorFlag.$OID" | grep -q noError

}


C1=$( controller_attivo 1 )
C9=$( controller_attivo 9 )
if  $C1 & $C9 ; then
	iptables -I INPUT -p udp --dport 514 -s 10.1.1.0/24 -d 10.9.9.1 -i eth2 -j REJECT
	iptables -I INPUT -p udp --dport 514 -s 10.9.9.0/24 -d 10.1.1.1 -i eth1 -j REJECT
elif ! $C1 ; then
	iptables -I FORWARD -p udp --dport 514 -s 10.1.1.0/24 -d 10.1.1.1 -i eth2 -j DNAT --to-dest 10.9.9.1
elif ! $C9 ; then
	iptables -I FORWARD -p udp --dport 514 -s 10.9.9.0/24 -d 10.9.9.1 -i eth2 -j DNAT --to-dest 10.1.1.1
fi





################ configurazione SNMP agent
# inserisco in snmpd.conf dei controller
#
# proc check.sh
#
# dopo aver configurato community e view per rendere visibile 
# l'intero MIB o la tabella UCD-SNMP-MIB
#
#
################ esecuzione automatica script ogni 5 min
#inserire con crontab -e la riga
# */5 * * * * /home/root/failover.sh
#
#
