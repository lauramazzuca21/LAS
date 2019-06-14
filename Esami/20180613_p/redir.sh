#/bin/bash

function check() {
	OID=$(snmpwalk -v 1 -c public 10.9.9.$1 .1.3.6.1.4.1.2021.2.1 | egrep 'prNames.*cron' | awk '{ print $1 }' | sed -e 's/prNames/prErrorFlag/')
	snmpget -v 1 -c public 10.9.9.$1 $OID | grep -q noError && touch /tmp/result/10.9.9.$1
}

# predispongo catene custom solo per pulizia
iptables -t nat -N REDIR
iptables -t nat -I PREROUTING -m range --src-range 10.1.1.1-10.1.1.250 -d 10.1.1.254 --dport 22 -j REDIR

iptables -N AUTH
iptables -I FORWARD -m range --src-range 10.1.1.1-10.1.1.250 --dport 22 -j AUTH
iptables -I FORWARD -m range --dst-range 10.1.1.1-10.1.1.250 --sport 22 --state ESTABLISHED -j AUTH

declare -a CHKPID
while : ; do
	rm -rf /tmp/result && mkdir -p /tmp/result
	for i in {1..59} ; do
		check $i & CHKPID[$i]=$!
	done
	while ps ${CHKPID[@]} >/dev/null 2>&1 ; do sleep 1 ; done

	cd /tmp/result
	unset SRV
	declare -a SRV
	# asterisco espande nei nomi dei file == elenco ip che hanno risposto bene
	# diventano in blocco gli elementi dell''array SRV
	SRV=(*)

	iptables -t nat -F REDIR
	iptables -F AUTH
	for C in {1..250} ; do
		S=$(( $RANDOM % ${#SRV[@]} + 1 ))
		iptables -t nat -I REDIR -s 10.1.1.$C -j DNAT --to-dest ${SRV[$S]}
		iptables -I AUTH -s 10.1.1.$C -d ${SRV[$S]} -j ACCEPT
		iptables -I AUTH -s 10.1.1.254 -d 10.1.1.$C -j ACCEPT
	done
done

#Vx/1 while true
#Vx/4 func snmpwalk+get in bg
#Vx/2 raccolta risultati
#Vx/1 calcolo srv rand
#Vx/2 dnat
#Vx/2 auth fwd
#Vx/2 commento snmp

