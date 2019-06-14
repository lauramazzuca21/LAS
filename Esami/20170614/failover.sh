#!/bin/bash

R1ETH2="10.1.1.1"
R9ETH2="10.1.1.254"

ATTUALE=$(ifconfig eth2 | grep "inet addr" | awk -F 'addr:' '{ print $2 }' | cut -f1 -d" ")

function imposta_regole_altro_router() {
	ip a add 10.$1.$1.1/24 dev eth$4
	ip a add 10.$2.$2.254/254 dev eth$3
	
	ip link set eth2 up
	ip link set eth1 up
	
	iptables -F

	# consento il traffico sull'interfaccia locale
	iptables -I INPUT -i lo -j ACCEPT
	iptables -I OUTPUT -o lo -j ACCEPT
	#abilita accesso 
	iptables -I INPUT -i eth3 -s 192.168.56.1 -d 192.168.56.202 -p tcp --dport 22 -j ACCEPT
	iptables -I OUTPUT -o eth3 -d 192.168.56.1 -s 192.168.56.202 -p tcp --sport 22 -m state --state ESTABLISHED -j ACCEPT
	#cambio la policy a default
	iptables -P INPUT DROP
	iptables -P OUTPUT DROP
	iptables -P FORWARD DROP
	
	iptables -I INPUT -s 10.1.1.0/24 -j ACCEPT
	iptables -I INPUT -s 10.9.9.0/24 -j ACCEPT
	iptables -I OUTPUT -d 10.1.1.0/24 -j ACCEPT
	iptables -I OUTPUT -d 10.9.9.0/24 -j ACCEPT

	iptables -I FORWARD -s 10.1.1.0/24 -d 10.9.9.0/24 -j ACCEPT
	iptables -I FORWARD -s 10.9.9.0/24 -d 10.1.1.0/24 -j ACCEPT

	./ldapdrop.sh
}

if [ $ATTUALE == $R1ETH2 ] ; then
	OTHER="9"
	MY="1"
	IFIN="2"
	IFOUT="1"
else
	OTHER="1"
	MY="9"
	IFIN="1"
	IFOUT="2"
fi 

while : ; do

	sleep 10
	
	OID=$(snmpwalk -v 1 -c public 10.$OTHER.$OTHER.1 "UCD-SNMP-MIB::prNames" | grep rsyslogd | awk -F "prNames." '{ print $2 }') | awk -F "=" '{ print $1 }')

	if ! snmpget -v 1 -c public 10.$OTHER.$OTHER.1 "UCD-SNMP-MIB::prErrorFlag.$OID" | grep -q noError ; then
		ssh root@10.$OTHER.$OTHER.1 "shutdown"
		imposta_regole_altro_router $OTHER $MY $IFIN $IFOUT
	fi
done
	
################ configurazione SNMP agent lato server
# inserisco in snmpd.conf dei router 
#
# proc ids.sh
#
# dopo aver configurato community e view per rendere visibile 
# l'intero MIB o la tabella UCD-SNMP-MIB
#
#
################ come predisporre i sistemi perché i router possano spegnersi a vicenda
#
# generare sui router coppie di chiavi ssh
# mettere le rispettive chiavi pubbliche sull'altro router
# nel file /root/.ssh/authorized_keys
#
#
