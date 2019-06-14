#!/bin/bash

function createchain() {
		iptables -N COUNTER_$1_$2
		iptables -I COUNTER_$1_$2 -j ACCEPT
}

function deletechain() {
		iptables -F COUNTER_$1_$2 
		iptables -X COUNTER_$1_$2
}

function managechain() {
	/sbin/iptables -$1 FORWARD -s $2 -d $3 -p tcp --dport 22 -j COUNTER_$2_$3
	/sbin/iptables -$1 FORWARD -d $2 -s $3 -p tcp --sport 22 -m state --state ESTABLISHED -j COUNTER_$2_$3
	/sbin/iptables -$1 INPUT -s $2 -d 10.1.1.254 -p icmp --icmp-type echo-request -j ACCEPT
	/sbin/iptables -$1 OUTPUT -d $2 -s 10.1.1.254 -p icmp --icmp-type echo-reply -m state --state ESTABLISHED -j ACCEPT
}

if ! echo "$2" | egrep '^10.1.1.([1-9][0-9]?|100)$' ; then
	echo "$2 non e' un IP valido di client"
	exit 1
fi

if ! echo "$3" | egrep '^10.9.9.([1-9][0-9]?|100)$' ; then
	echo "$2 non e' un IP valido di server"
	exit 2
fi

if [ "$1" = "open" ]; then
	managechain D "$2" "$3" 2>/dev/null
	deletechain "$2" "$3"
	createchain "$2" "$3"
	manage I "$2" "$3"
elif [ "$1" = "close" ]; then
	manage D "$2" "$3"
	deletechain "$2" "$3"
else
	echo "Uso: {open|close} ipclient ipserver"
	exit 1
fi


#################

