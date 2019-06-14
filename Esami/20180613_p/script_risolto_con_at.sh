#/bin/bash

U=$(whoami)
trap "kill -9 -$$" EXIT
echo "/bin/kill $$" | at now + 50 minutes 2>&1 | grep ^job | awk '{ print $2 }' > /tmp/watchdog.$$

cd ~/jobs
for S in * ; do
	if test -x "$S" ; then
		TS=$(date +%s)
		./"$S"
		RT=$(( $(date +%s) - $TS ))
		( echo "dn: ts=$TS,uname=$U,dc=labammsis"
		  echo "objectClass: exec"
		  echo "ts: $TS"
		  echo "rt: $RT"
		  echo "script: $S"
		  echo
		) | ldapadd -x -D "cn=admin,dc=labammsis" -w admin -h 10.9.9.254
	fi
done

atrm $(cat /tmp/watchdog.$$)

#Vx/1 whoami
#Vx/1 trap
#Vx/3 watchdog (con at) e disinnesco
#Vx/2 ciclo su eseguibili
#Vx/2 exec e misura TS/RT
#Vx/2 ldif+ldapadd
