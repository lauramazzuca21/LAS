
START=$(date +%s)
cd jobs
for S in * ; do
	if test -x "$S" ; then
		TS=$(date +%s)
		RT=0
		./"$S" & $RUNNING=$!
		while ps $RUNNING ; do
			RT=$(date +%s)
			if test $(( $RT - $START )) -gt 3000 ; then
				echo time limit expired
				kill -9 $RUNNING
				exit 1
			fi
			sleep 1
		done
		RT=$(( $RT - $TS ))
		( echo "dn: ts=$TS,uname=$U,dc=labammsis"
		  echo "objectClass: exec"
		  echo "ts: $TS"
		  echo "rt: $RT"
		  echo "script: $S"
		  echo
		) | ldapadd -x -D "cn=admin,dc=labammsis" -w admin -h 10.9.9.254
	fi
done
