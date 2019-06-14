#!/bin/bash

MYIP=$(ifconfig eth2 | grep "inet addr" | awk -F 'addr:' '{ print $2 }' | cut -f1 -d" ")

function imposta_iptables(){
	echo "if ! iptables -C INPUT -sport $2 -p tcp -j LOG --log-level debug --log-prefix 'check_$1' ; then
                iptables -I INPUT -sport $2 -p tcp -j LOG --log-level debug --log-prefix 'check_$1
                fi" > /tmp/regole_iptables$$.sh
        scp /tmp/regole_iptables$$.sh $1:/tmp
        ssh $1 "/bin/bash /tmp/regole_iptables$$.sh ; rm -f /tmp/regole_iptables$$.sh"
        rm -f /tmp/regole_iptables$$.sh
}

function imposta_rsyslog() {
	echo -e "kern.=debug\t@$MYIP" > /tmp/esame_rsyslog$$.conf
        scp /tmp/esame_rsyslog$$.conf $1:/tmp
        ssh $1 "cat /tmp/esame_rsyslog$$.conf > /etc/rsyslog.d/esame.conf ; rm -f /tmp/esame_rsyslog$$.conf; systemctl restart rsyslog"
        rm -f /tmp/esame_rsyslog$$.conf
}

function imposta_snmp() {
#memAvailReal	.1.3.6.1.4.1.2021.4.6
#laLoadInt	.1.3.6.1.4.1.2021.10.1.5.2
#In reatla' abbiamo semplicemente bisogno che sia visibile tutto il mib
	echo " 
	 if ! cat /etc/snmp/snmpd.conf | grep -q 'view all included .1' ; then
		echo 'view all included .1' >> /etc/snmp/snmpd.conf
		fi
		if ! cat /etc/snmp/snmpd.conf | grep -q 'rocommunity public default -V all' ; then
		echo 'rocommunity public default -V all' >> /etc/snmp/snmpd.conf
		fi
		if ! cat /etc/snmp/snmpd.conf | grep -q 'rwcommunity supercom default -V all' ; then
		echo 'rwcommunity supercom default -V all' >> /etc/snmp/snmpd.conf
		fi
		if ! cat /etc/snmp/snmpd.conf | grep -q 'agentAddress udp:161' ; then
		echo 'agentAddress udp:161' >> /etc/snmp/snmpd.conf
		fi" > /tmp/check_snmp$$.sh
        scp /tmp/check_snmp$$.sh $1:/tmp
        ssh $1 "/bin/bash /tmp/check_snmp$$; rm -f /tmp/check_snmp$$.sh; systemctl restart snmpd"
}
        
cat /root/ingress.list | ( while read PORT ; do
	imposta_regole "10.1.1.$1" $PORT
done )

imposta_rsyslog
imposta_snmp
########### cosa predisporre per consentire la connessione non interattiva dal controller ai server
#
# generare sui controller coppie di chiavi ssh
# mettere le chiavi pubbliche dei controller su ogni server
# nel file /root/.ssh/authorized_keys
#
########### come configurare i syslog dei controller per scrivere i pacchetti ricevuti su /var/log/t.log
#
# inserire nel file /etc/rsyslog.conf di 10.1.1.1 e 10.1.1.2
# l'abilitazione alla ricezione udp e queste regole:
#  kern.=debug	/var/log/t.log
#  

