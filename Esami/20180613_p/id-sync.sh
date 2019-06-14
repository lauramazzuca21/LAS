#/bin/bash
tail -f /var/log/newusers | grep --line-buffered ____ | while IFS=____ read header u k footer ; do

	# approccio brutale, ignoro errore se già esiste 
	# (ma così perdo anche altri errori!)
	EXISTS=$(ldapsearch -xb "uname=$u,dc=labammsis" -s one -w admin -h 10.1.1.254)
	
	if ! test -z "$EXISTS"; then
		
	
		echo -e "dn: uname=$u,dc=labammsis\nobjectClass: user\nuname: $u\n\n" | ldapadd -c -x -D "cn=admin,dc=labammsis" -w admin -h 10.1.1.254 2>/dev/null

#	adduser will copy files from SKEL into the home  directory  and  prompt
#       for  finger  (gecos) information and a password.  The gecos may also be
#       set with the --gecos option.  With  the  --disabled-login  option,  the
#       account  will  be created but will be disabled until a password is set.
#       The --disabled-password option will not set a password,  but  login  is
#       still possible (for example with SSH RSA keys).
# 	--home  The home directory can be  overridden  from  the  command
#	line with the --home option, and the shell with the --shell option. 

		for i in {1..59} ; do
			ssh -n 10.9.9.$i "adduser --disabled-password --gecos '' --home /home/$u $u ; mkdir /home/$u/.ssh ; echo $k >> /home/$u/.ssh/authorized_keys ; chown -R $u:$u /home/$u/.ssh ; chmod 700 /home/$u/.ssh ; echo '$i * * * * /home/$u/script.sh' | crontab"
		done
	fi

done

#Vx/2 tail + parsing riga
#Vx/3 ldif + ldapadd
#Vx/2 ciclo server + ssh
#Vx/6 adduser + mkdir + echo $k + chown + chmod + crontab
