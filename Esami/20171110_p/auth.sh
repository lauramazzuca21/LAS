#!/bin/bash


tail -f /var/log/req.log | grep --line-buffered EXEC___ | while read line; do

	# exec.sh invia messaggi col seguente comando:
	# logger -p local1.info "EXEC___IPCLIENT___IPSERVER___"
	ipc=$(echo "$line" | awk -F '___' '{ print $2 }')
	ips=$(echo "$line" | awk -F '___' '{ print $3 }')

	username=$(snmpget -Oa -v 1 -c public "$ipc" 'NET-SNMP-EXTEND-MIB::nsExtendOutput1Line."esame"' | awk -F ' = STRING: ' '{ print $2 }')

	if test "$username" ; then
		if ldapsearch -h localhost -x -b "server=$ips,utente=$username,dc=labammsis" -s base >/dev/null 2>&1 ; then
			/root/firewall.sh open "$ipc" "$ips"
			croncmd="/root/timeout.sh $ipc $username $ips"
			crontab -l | grep -v "$croncmd" > /tmp/crontab$$
			echo "*/10 * * * * $croncmd" >> /tmp/crontab$$ 
			crontab /tmp/crontab$$
		fi
	fi
	else 
		echo "lettura username fallita"
	fi
done

