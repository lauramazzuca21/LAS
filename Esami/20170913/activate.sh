#!/bin/bash

function restore_basic_firewall() {

	iptables -F

	iptables -I INPUT -i lo -j ACCEPT
	iptables -I OUTPUT -o lo -j ACCEPT

	iptables -P INPUT DROP
	iptables -P OUTPUT DROP
	iptables -P FORWARD DROP

	# PER DEBUG VIA SSH DALLA MACCHINA HOST DI Vbox
	iptables -I INPUT -p tcp -i eth3 -s 192.168.56.1 -d 192.168.122.201 --dport 22 -j ACCEPT
	iptables -I OUTPUT -p tcp -o eth3 -d 192.168.56.1 -s 192.168.122.201 --sport 22 -m state --state ESTABLISHED,RELATED -j ACCEPT

	# PER CONNESSIONE VIA SSH DAL CONTROLLER
	iptables -I INPUT -p tcp -i eth2 -s 10.1.1.254 -d 10.1.1.$MYIP --dport 22 -j ACCEPT
	iptables -I OUTPUT -p tcp -o eth2 -d 10.1.1.254 -s 10.1.1.$MYIP --sport 22 -m state --state ESTABLISHED,RELATED -j ACCEPT

	# snmp in uscita
	iptables -I OUTPUT -p udp -d 10.1.1.254 -s 10.1.1.$MYIP --dport 161 -j ACCEPT
	iptables -I INPUT -p udp -s 10.1.1.254 -d 10.1.1.$MYIP --sport 161 -m state --state ESTABLISHED,RELATED -j ACCEPT

}

cat /dev/null > /etc/rsyslog.d/esame130917.conf

echo "kern.=debug\t@10.1.1.254" > /etc/rsyslog.d/esame130917.conf

systemctl restart rsyslog

##quando inattivo un processo di sistema ha questa sintassi
#   Loaded: loaded (/etc/init.d/slapd)
#   Active: inactive (dead)

STATUS=$(systemctl status rsyslog | grep Active | awk -F "Active: " '{ print $2 }' | awk -F " \(" '{ print $1 }')
MYIP=$(ifconfig eth2 | grep "inet addr" | awk -F 'addr:' '{ print $2 }' | cut -f1 -d" "| cut -f4 -d .)
#[...]Se rileva che il demone si è avviato, configura il packet filter in modo che mandi al 
#logger di sistema tutti i pacchetti ricevuti dagli altri server; [...]
if [ $STATUS = "active" ] ; then
	if ! iptables -vnL INPUT | grep -q 'myIP:10.1.1.$MYIP' ; then
		if test $MYIP -eq 1 ; then
                	iptables -I INPUT -m iprange --src-range 10.1.1.2-10.1.1.250 -j LOG --log-level debug --log-prefix  ' myIP:10.1.1.$MYIP '
                elif test $MYIP -eq 250 ; then
                	iptables -I INPUT -m iprange --src-range 10.1.1.1-10.1.1.249 -j LOG --log-level debug --log-prefix  ' myIP:10.1.1.$MYIP '
                else
                	IPPREV=$(( $MYIP - 1 ))
                	IPPOST=$(( $MYIP + 1 ))
                	iptables -I INPUT -m iprange --src-range 10.1.1.1-10.1.1.$IPPREV -j LOG --log-level debug --log-prefix  ' myIP:10.1.1.$MYIP '
                	iptables -I INPUT -m iprange --src-range 10.1.1.$IPPOST-10.1.1.250 -j LOG --log-level debug --log-prefix  ' myIP:10.1.1.$MYIP '
                fi

#[...]altrimenti, configura il packet filter per impedire tutto il traffico in ingresso e uscita
#dal server, con l’unica esclusione del traffico relativo alle connessioni SSH e SNMP provenienti dal
#Controller, che devono funzionare correttamente.       fi
else
	restore_basic_firewall
fi

