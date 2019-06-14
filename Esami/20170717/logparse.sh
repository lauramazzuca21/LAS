#!/bin/bash

MYPID=$$

#esempio di log 
# Apr 27 12:02:56 router kernel: [10139.999098] IN=eth2 OUT=eth1 MAC=08:00:27:27:a6:e6:08:00:27:24:9b:d5:08:00 SRC=10.1.1.1 DST=10.9.9.1 LEN=60 TOS=0x00 PREC=0x00 TTL=63 ID=23272 DF PROTO=TCP SPT=37668 DPT=22 WINDOW=29200 RES=0x00 SYN URGP=0
#
function ciclo() {
	cat /root/active.list | (while read SERVER ; do
		SERVER="10.9.9.1"
		RAM=$( snmpwalk -v1 -c public "$SERVER" .1.3.6.1.4.1.2021.4.6 | awk -F 'INTEGER: ' '{ print $2 }' | cut -f1 -d " " )
		LOAD=$( snmpwalk -v1 -c public "$SERVER" .1.3.6.1.4.1.2021.10.1.5.2 | awk -F 'INTEGER: ' '{ print $2 }' )
		TS=$(date +%s)
		ENTRY=$( echo "dn: server=$SERVER,dc=labammsis"
		  echo "objectClass: host"
		  echo "server: $SERVER"
		  echo "objectClass: data"
		  echo "ts: $TS"
		  echo "ram: $RAM"
		  echo "load: $LOAD" )
		  SNUM=$( echo $SERVER | cut -f4 -d. )
                while read line ; do
                        IP=$( echo "$line" | cut -f1 -d "_" )
                        if [ "$IP" = "$SNUM" ] ; then
                                PORT=$( echo "$line" | cut -f2 -d "_" )
                                COUNT=$( echo "$line" | cut -f3 -d "_")
                                ENTRY=$( echo "$ENTRY"
                                        echo "pp:" "$PORT"_"$COUNT")
                        fi
                  done < /tmp/elenco

		  echo "$ENTRY" | ldapadd -x -D "cn:admin,dc:labammsis" -w admin 2&>1
		  echo "$ENTRY" | ldapadd -x -D "cn:admin,dc:labammsis" -w admin -h 10.1.1.2 2&>1
		 
	done )
	
}

trap 'ciclo' SIGUSR1



echo "5 * * * * /bin/kill -SIGUSR1 '$MYPID'" > /tmp/contab_config.txt

crontab /tmp/contab_config.txt

declare -A COUNT_PACKETS
cat /dev/null > /tmp/elenco

tail -l /var/log/t.log | awk -W interactive -F ']' '{ print $2 }' | (while read line ; do
	SRC=$(echo $line | awk -F 'SRC=' '{ print $2 }' | cut -f1 -d " " | cut -f4 -d.)
	SPT=$(echo $line | awk -F 'SPT=' '{ print $2 }' | cut -f1 -d " ")
	
	if ! [ -z $SRC -a -z $SPT ] ; then
		i=$(echo "$SRC"_"$SPT")
		COUNT_PACKETS["$i"]=$(( ${COUNT_PACKETS["$i"]} + 1 ))
		new="$i"_"${COUNT_PACKETS[$i]}"
                if cat /tmp/elenco | grep -q "$i" ; then
                        sed -i -e "s/.*$i.*/$new/" /tmp/elenco
                else
                        echo "$new" >> /tmp/elenco
                fi
	fi
done )
	
	
		
	

