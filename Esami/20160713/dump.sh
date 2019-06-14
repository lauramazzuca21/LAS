#!/bin/bash


#-A stampa il contenuto del payload in ASCII (-X sia ASCII che hex)

PAYLOAD=""
tcpdump -Annl -i any tcp and 'not src net 10.1.1.0/24' | ( while read  line ; do

	if echo $line | grep -q IP ; then
		if ! [ -z "$PAYLOAD" ] ; then
		 echo "$SIP $SP $DIP $DP $PAYLOAD"
		fi
		S=$( echo $line | awk -F 'IP ' '{ print $2 }' | awk -F ' >' '{ print $1 }' )
		D=$( echo $line | awk -F '> ' '{ print $2 }' | awk -F ':' '{ print $1 }' )
		SIP=$( echo $S |  awk -F. '{ if (NF == 2) { print $1 } else { print $1 FS $2 FS $3 FS $4 }}' )
		DIP=$( echo $D |  awk -F. '{ if (NF == 2) { print $1 } else { print $1 FS $2 FS $3 FS $4 }}' )
		SP=$( echo $S | cut -f5 -d. )
		DP=$( echo $D | cut -f5 -d. )
		PAYLOAD=""
	else
		PAYLOAD="$PAYLOAD$line"
	fi
done )
	
