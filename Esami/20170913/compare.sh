#!/bin/bash
while : ; do
	declare -a ACTCOLLECT
	if [ -f "/tmp/getdata.complete" ] ; then
		cat "/tmp/active" | while read IPS ; do
			i=$(echo $IPS | cut -d . -f4)
			./collect.sh $IPS & ACTCOLLECT[$i]=$!
				done
		cat "/tmp/inactive" | while read IPS ; do
			i=$(echo $IPS | cut -d . -f4)
			if test $ACTCOLLECT[$i] ; then 
				kill -s USR1 $ACTCOLLECT[$i]
				done
		cat "/tmp/active.norsys" | while read IPS ; do
			ssh -n $IPS "$(find -type f -name '*activate.sh')"
				done
		rm -f "/tmp/getdata.complete"
	fi
done
			
				
			
