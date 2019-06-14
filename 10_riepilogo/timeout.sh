#!/bin/bash


iptables -Z -vnxL FORWARD | egrep '^[[:space:]]*[123456789]+' | while read pkts bytes target proto opts intin intout srcip destip proto2 ports ; do
	DPT=$(echo $ports | cut -f2 -d:)
	atrm $(cat /tmp/timer_$srcip_$destip_$DPT)
	echo "/root/openclose.sh D $srcip $destip $DPT" | at now + 5 minutes 2>&1 | grep ^job | awk '{ print $2 }' > /tmp/timer_$srcip_$destip_$DPT
done


