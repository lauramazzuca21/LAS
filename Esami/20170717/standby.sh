#!/bin/bash

while : ; do
	LAST_TS=$(ldapsearch -xb "dc=labammsis" '(ts=*)' | grep ts | awk -F 'ts: ' '{ print $2 }' | sort -n | tail -n1 )
	TIME=$(( $(date +%s) - $LAST_TS ))
	#10*60=600 secondi in 10 min
	if [ $TIME -ge 600 ] ; then
		/root/finder.sh
		/root/logparse.sh
	fi
done
		
	
