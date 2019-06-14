#!/bin/bash

#Questo script accetta tre parametri (un numero che rappresenta un’orario e due
#indirizzi ip) e inserisce una entry nella directory LDAP locale, costruita con tali dati.

ORA=$1
SRC=$2
DEST=$3

( echo "dn: ora=$ORA,cn=admin,dc=labammsis"
	echo "objectclass: stop"
	echo "ora: $ORA"
	echo "src: $SRC"
	echo "dest: $DEST"
	) | ldapadd -xc -D "cn=admin,dc=labammsis" -w admin
