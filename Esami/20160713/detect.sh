#!/bin/bash


declare -A COUNT_PAYLOAD
declare -a STOP_COUNT
COUNT=0
CL=1
tcpdump tcp -i eth2 -Annl -s100 | ( while read line ; do
	if echo $line | grep IP ; then
		if ! test -z "$PAYLOAD" ; then
			for i in $"${STOP_COUNT[@]}" ; do
			if [ "$line" = "$i" ] ; then
				CL=0
				;;
			fi
			done
			if [ $CL -ne 0 ] ; then
				COUNT_PAYLOAD["$PAYLOAD"]=$(( ${COUNT_PAYLOAD["$PAYLOAD"]} + 1 ))
				if [ ${COUNT_PAYLOAD["$PAYLOAD"]} -gt 10 ] ; then
					STOP_COUNT+=("$PAYLOAD")
					
					ldapsearch -xb "cn=admin,dc=labammsis" "(objectClass=blacklist)" | grep dn | ( while read DN ; do
						(echo "$DN"
						echo "changetype: modify"
						echo "add: badstring"
						echo "badstring: $PAYLOAD"
						) | ldapmodify -x -D "cn=admin,dc=labammsis" -w admin 2&>1 )
					done
				fi
			fi
		SIP=$( echo $line | awk -F 'IP ' '{ print $2 }' | awk -F ' >' '{ print $1 }' |  awk -F. '{ if (NF == 2) { print $1 } else { print $1 FS $2 FS $3 FS $4 }}' )
		PAYLOAD=""
	else
		PAYLOAD="$PAYLOAD $line"
		COUNT=$(( $COUNT + 1 ))
	fi
done )
	
			
			
