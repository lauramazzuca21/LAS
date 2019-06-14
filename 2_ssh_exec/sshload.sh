#!/bin/bash

#i=0

filename="lista.txt"

#while read line ; do
#	let "i += 1"
#	echo $i $line
#	if [ $i -eq 1 ] ; then
#		LWC=(`./sshnum.sh "$line" | tr -d '\n'`)
#		#LWC=(`./sshnum.sh "$line"`)
#		C="$line"
#	else
#		WC=(`./sshnum.sh "$line" |  tr -d '\n'`)
#		if [ $WC -lt $LWC ] ; then
#			LWC="$WC"
#			C="$line"
#		fi
#	fi	
#done < "$filename"

LWC=0
for line in `cat $filename`; then
	WC=$( ./sshnum_snmp.sh "$line" )
	if [ $WC -eq 0 ] ; then
		continue
	else
		if [ $LWC -eq 0 ] ; then
			LWC=$WC;
			C="$line"
		elif [ $WC -lt $LWC ] ; then
			LWC="$WC"
			C="$line"
		fi
	fi	
done

echo "$C"
