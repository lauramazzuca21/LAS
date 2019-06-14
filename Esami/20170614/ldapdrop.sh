#!/bin/bash

#Questo script individua le entry LDAP create nelle ultime due ore, e sul router su cui
#viene lanciato, configura il packet filter perché blocchi il traffico relativo alle rispettive coppie di IP
#(si ponga attenzione a non duplicare inutilmente le regole).

ORA=$(date +'%H')
PREVORA=$(( $ORA - 1 ))
ldapsearch -xb "cn=admin,dc=labammsis" "(|(ora=$ORA*)(ora=$PREVORA*))" | ( while read line ; do
	if echo $line | grep -q src ; then
		SRC=$( echo $line | awk -F 'src: ' '{ print $2 }' )
	elif echo $line | grep -q dst ; then
		DST=$( echo $line | awk -F 'dest: ' '{ print $2 }' )
	fi
	
	if ! [ -z $SRC -a -z $DST ] ; then
		if ! iptables -C INPUT -s $SRC -d $DST -j DROP ; then
			iptables -I INPUT -s $SRC -d $DST -j DROP
			iptables -I OUTPUT -d $SRC -s $DST -j DROP
		fi
	fi
done )
