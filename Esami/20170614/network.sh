#!/bin/bash

#Lo script rileva se è in esecuzione su R1 o su R9 e configura il packet filter perché la
#macchina funzioni come in figura: R1 inoltra solamente i pacchetti dalla rete 10.1.1.0/24 alla rete
#10.9.9.0/24 ed R9 inoltra solamente i pacchetti dalla rete 10.9.9.0/24 alla rete 10.1.1.0/24. Tutto il
#traffico non indispensabile al funzionamento dei vari script del presente testo deve essere bloccato.

R1ETH2="10.1.1.1"
R9ETH2="10.1.1.254"

ATTUALE=$(ifconfig eth2 | grep "inet addr" | awk -F 'addr:' '{ print $2 }' | cut -f1 -d" ")

function set_rules() {
	#$1=soruce
	#$2=destination
	#$3=src_interface
	#$4=dst_interface
	iptables -I INPUT -i eth$3 -s 10.$1.$1.0/24 -j ACCEPT
	iptables -I OUTPUT -o eth$4 -d 10.$2.$2.0/24 -j ACCEPT
	iptables -I FORWARD -i eth$3 -s 10.$1.$1.0/24 -d 10.$2.$2.0/24 -j ACCEPT
	# regole syslog entrante e uscente
	iptables -I INPUT -p udp --dport 514 -s 10.$1.$1.254 -d 10.$1.$1.1 -i eth$3 -j ACCEPT
	iptables -I OUTPUT -p udp --dport 514 -s 10.$2.$2.254 -d 10.$2.$2.1 -i eth$3 -j ACCEPT
	# regole ssh da/verso router
	iptables -I OUTPUT -d 10.$2.$2.1 -p tcp --dport 22 -j ACCEPT
	iptables -I INPUT -s 10.$1.$1.254 -p tcp --sport 22 --state ESTABLISHED -j ACCEPT
	# regole snmp da/verso server
	iptables -I OUTPUT -d 10.$2.$2.1 -p udp --dport 161 -j ACCEPT
	iptables -I INPUT -s 10.$1.$1.254 -p udp --sport 161 --state ESTABLISHED -j ACCEPT	
}


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

if [ $ATTUALE == $R1ETH2 ] ; then
	set_rules 1 9 2 1
else
	set_rules 9 1 1 2
fi 



