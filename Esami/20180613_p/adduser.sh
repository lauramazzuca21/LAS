#!/bin/bash
#
# check parametri minimale
test "$1" || ( echo parametro mancante ; exit 1 )
test "$EUID" -eq 0 || ( echo devi essere root ; exit 2 )

adduser "$1" &&
su -c 'ssh-keygen -t rsa -b 2048 -P ""' - "$1" &&
logger -p local4.info ____"$1"____$(su -c 'cat .ssh/id_rsa.pub' - $1)____

# sui client: local4.info @10.1.1.254
# su RF: local4.info /var/log/newusers (+ attivazione udp)

#Vx/1 check param
#Vx/1 adduser
#Vx/1 && tra i tre step
#Vx/2 su ssh-keygen
#Vx/2 logger 
#Vx/2 commento syslog
