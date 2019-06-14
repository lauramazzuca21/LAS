#!/bin/bash

function check() {
	OID=$(snmpwalk -v 1 -c public 10.1.1.$1 "UCD-SNMP-MIB::prNames" | grep rsyslogd | awk -F "prNames." '{ print $2 }') | awk -F "=" '{ print $1 }')
	NOERR=$(snmpget -v 1 -c public 10.1.1.$1 $OID | grep -q noError)
	if test -z "$OID" ; then
		echo "10.1.1.$1" >> /tmp/inactive
	elif test -z "$NOERR" ; then
		echo "10.1.1.$1" >> /tmp/active
	else 
		echo "10.1.1.$1" >> /tmp/active.norsys
	fi
}

EXISTS=$(find /tmp -type f -name 'getdata.complete')

if ! test -z $EXISTS ; then
	echo "file already exists"
	exit 1
fi

cat /dev/null > /tmp/active
cat /dev/null > /tmp/active.norsys
cat /dev/null > /tmp/inactive

declare -a CHKPID
for i in {1..250} ; do
	check $i & CHKPID[$i]=$!
done
while ps ${CHKPID[@]} >/dev/null 2>&1 ; do sleep 1 ; done

touch /tmp/getdata.complete

################ configurazione SNMP agent lato server
# inserisco in snmpd.conf dei server 
#
# proc rsyslogd
#
# dopo aver configurato community e view per rendere visibile 
# l'intero MIB o la tabella UCD-SNMP-MIB
 
################ esecuzione automatica script ogni min
#inserire con crontab -e la riga
# */1 * * * * /home/root/getdata.sh




