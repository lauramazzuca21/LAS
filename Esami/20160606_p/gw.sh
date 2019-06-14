#!/bin/bash

IPR1="10.1.1.253"
IPR2="10.1.1.254"
IPC=$(ifconfig eth2 | grep "inet addr" | awk -F 'addr:' '{ print $2 }' | cut -f1 -d" ")

function registra_ldap(){
	ldapdelete -c -h $2 -x -D "cn=admin,dc=labammsis" -w admin "dn: ipclient=$IPCLIENT,dc=labammsis" 2> /dev/null
	
	TS=$(/bin/date +%s)
        echo "dn: ipclient=$IPCLIENT,dc=labammsis
objectClass: gw
ipclient: $IPCLIENT
iprouter: $1
timestamp: $TS" | ldapadd -x -D "cn=admin,dc=labammsis" -w admin -h $2
}

function imposta_default(){

	ip route replace default via $1
	
	registra_ldap $1 $IPR1
	registra_ldap $1 $IPR2
}

MIN=(ldapsearch -xb -h 10.1.1.253 "dc=labammsis" "(objectClass=gw)" | grep "^iprouter: " | awk -F '{print $2}' | sort | uniq -c | sort -n | head -1| awk '{print $2}')

if test -z "$MIN"; then MIN = 10.1.1.254 ; fi

imposta_default $MIN


