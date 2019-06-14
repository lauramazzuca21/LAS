#!/bin/bash

function dn_to_path()
{
	FN=""
	echo $1 | sed -e 's/,dc=labammsis//' | sed -e 's/fn=//g' | sed -e 's/,/\n/g' | ( while read a
		do
		    FN="$a/$FN"
		done
		echo /$FN | sed -e 's/\/$//'
	)
}



ldapsearch -x -s sub -b "dc=labammsis" "(|(objectClass=dir)(objectClass=file))" | grep "^dn: " | cut -c5- | rev | sort -r | rev | while read name ; do
	# il dn è nella forma fn=filename,fn=to,fn=path,dc=labammsis
	# che rappresenta /path/to/filename

	# l'ordinamento rev / sort -r / rev garantisce che path lunghi 
	# vengano prima di path corti 
	# -->
	# nel caso rimuovo i nodi figli prima dei padri

	FILE=$(dn_to_path $name)

	if test -e "$FILE" ; then
		ldapsearch -x -s base -b "$name" | grep '^(ownuser|owngroup|perm): ' | sort | awk -F ': ' '{ print $2 }' | (
			# in questo modo mantengo l'uso del fine riga come separatore, 
			# ed evito problemi se ci sono caratteri speciali negli attributi
			read OG
			read OU 
			read PE
			chown "$OU":"$OG" "$FILE"
			chmod "$PE" "$FILE"
		)
	else
		echo "$name"
		# il ciclo emette i DN da eliminare
		# un'unica connessione autenticata al server li elimina
	fi
done | ldapdelete -D "cn=admin,dc=labammsis" -w "admin" -x 
