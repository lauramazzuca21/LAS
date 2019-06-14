#!/bin/bash
#                                       log_user.sh
# individua l'utente responsabile
# lo scrive nel log excess 

# invocato con SIP DIP SP DP

THEPID=$(snmpget -v 1 -c public $1 'NET-SNMP-EXTEND-MIB::nsExtendOutputFull."activeconn"' | egrep "ESTAB.*$1:$3.*$2:$4" | awk -F 'pid=' '{ print $2 }' | cut -f1 -d,)

snmpget -v 1 -c public $1 'NET-SNMP-EXTEND-MIB::nsExtendOutputFull."pid2user"' | egrep -w "$THEPID" | awk '{ print $2 }' | logger -p local1.info

# SU OGNI MACCHINA REMOTA CONFIGURARE L'AGENT CON
# extend    activeconn /usr/bin/sudo /bin/ss -ntp
# extend    pid2user   /bin/ps -haxo pid,user
#
# AVENDO ABILITATO L'ESECUZIONE DI SUDO SS IN /etc/sudoers
# snmp    ALL = NOPASSWD:/bin/ss


# ESTENSIONE: considerare tutti i pid non solo il primo di ss

