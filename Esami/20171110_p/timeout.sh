#!/bin/bash
# parametri IP/utente del client e IP serve

ipc="$1"
username="$2"
ips="$3"

# controllo il traffico rispetto all' ultima esecuzione
# la catena dev'essere resettata ad ogni invocazione

chain="COUNTER_$ipc_$ips"
accumulatore="/tmp/$chain"
traffico=$(iptables -Z -vnxL $chain | grep -v ^Zeroing | tail -1 | awk '{ print $2 }')

if [ -f "$accumulatore" ]; then
	totale=$(( $(cat $accumulatore) + $traffico ))
else
	totale=$traffico
fi
echo $totale > $accumulatore

if test "$traffico" -eq 0 ; then

	/root/firewall.sh close $ipc $ips

	( echo "dn: server=$ips,utente=$username,dc=labammsis"
	echo "changetype: modify"
	echo "add: traffic"
	echo "traffic: $(date +%s)_$totale)"
	) | ldapmodify -h localhost -x -D "cn=admin,dc=labammsis" -w admin

	crontab -l | grep -v "/root/timeout.sh $ipc $username $ips" | crontab
	rm -f "$accumulatore"
fi

