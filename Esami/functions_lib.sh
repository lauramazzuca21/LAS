###
# COMANDI UTILI PER MONITORING DEMONI
###

#consente di sapere se ci sono stati errori nel caricamento dei file di configurazione
rsyslogd -N1


###
# SETTAGGIO PARAMETRI NOTEVOLI
###
IPATTUALE=$(ifconfig eth2 | grep "inet addr" | awk -F 'addr:' '{ print $2 }' | cut -f1 -d" ")

#IP presente in ldap remoto il minor numero di volte
MIN=$(ldapsearch -x -s sub -h 10.1.1.253 -b "dc=labammsis" "(objectClass=gw)" | grep "^iprouter: " | awk '{ print $2 }' | sort | uniq -c | sort -n | head -1 | awk '{ print $2 }')

###
# FUNZIONI UTILI
###
function altro_router(){
        ATTUALE=$1
        if test $ATTUALE = $ROUTER1
                echo $ROUTER2
        else
                echo $ROUTER1
        fi
}

function setipparams() {
	# setta le variabili a seconda che ci sia un ip o un range
	# MOD per caricare eventualmente il modulo iprange
	# IPS e IPD sono sorgente e destinazione con l'opzione giusta
	if echo $1 | grep -q -- '-' ; then
		# se c'è un - è un range
		MOD="-m iprange"
		IPD="--dst-range $1"
		IPS="--src-range $1"
	else
		# se no è un ip singolo
		MOD=""
		IPD="-d $1"
		IPS="-s $1"
	fi
}

function setprotoparams() {
	# setta le variabili a seconda del protocollo (icmp, tcp o udp)
	# PROTO è sempre il protocollo
	# DP e SP sono sorgente e destinazione solo se non è icmp
	# sarebbe opportuno error checking, anche se invocata solo 
	# internamente da questo stesso script
	PROTO="$1"
	if test "$PROTO" = "icmp" ; then
		DP=""
		SP=""
	else
		DP="--dport $2"
		SP="--sport $2"
	fi
}
	
function client() {
	# imposta regole iptables quando io sono client
	# parametri: server proto porta 
	setipparams $1
	setprotoparams $2 $3
	iptables -I OUTPUT $MOD $PROTO $DP $IPD -j ACCEPT
	iptables -I INPUT $MOD $PROTO $SP $IPS --state ESTABLISHED -j ACCEPT
}

function server() {
	# imposta regole iptables quando io sono server
	# parametri: client proto porta 
	setipparams $1
	setprotoparams $2 $3
	iptables -I INPUT $MOD $PROTO $DP $IPS -j ACCEPT
	iptables -I OUTPUT $MOD $PROTO $SP $IPD --state ESTABLISHED -j ACCEPT
}

function init_non_in_esecuzione(){
	# cerco nella process table la riga relativa a "proc init.sh"
	R=$(snmpwalk -v 1 -c public localhost UCD-SNMP-MIB::prTable | grep init.sh | awk -F 'prNames.' '{ print $2 }' | awk '{ print $1 }')

	# verifico lo stato dell'ErrMessage, e ritorno un exit code
	# coerente col nome della funzione (true se non in esecuzione)
        snmpget -v 1 -c public localhost "UCD-SNMP-MIB::prErrMessage.$R" | grep -q "No init.sh process running"
}

function is_default(){
	# segnalo che sta girando il verificatore
	touch running_$1
        ssh root@$1 "ip route" | grep -q "default via $ROUTER" || touch $1 
	rm -f running_$1
}

function imposta_regole(){
	# ... deve essere attivata (evitando duplicazioni) 
	# su entrambi i router una regola di iptables 
	# che permetta di loggare ogni pacchetto da e per tale client.
	echo "if ! iptables -vnL FORWARD | grep -q 'check_$1' ; then
                iptables -I FORWARD -s $1 -j LOG --log-level debug --log-prefix  ' check_$1 '
                iptables -I FORWARD -d $1 -j LOG --log-level debug --log-prefix  ' check_$1 '
                iptables -I INPUT -s $1 -j LOG --log-level debug --log-prefix  ' check_$1 '
                iptables -I OUTPUT -d $1 -j LOG --log-level debug --log-prefix  ' check_$1 '
              fi" > /tmp/regole$$.sh
	/bin/bash /tmp/regole$$.sh
	scp /tmp/regole$$.sh $ALTRO:/tmp
	ssh $ALTRO "/bin/bash /tmp/regole$$.sh ; rm -f /tmp/regole$$.sh"
	rm -f /tmp/regole$$.sh
}


function segnala_client(){
	# si collega al client e termina tutti i processi 
	# che stanno utilizzando socket di rete
	# l'output di ss può essere di questo tipo:
	# tcp ESTAB 0 0 127.0.0.1:ssh 127.0.0.1:37012 users:(("sshd",pid=10610,fd=3),("sshd",pid=10516,fd=3))
	# prima converto le virgole in a capo, poi seleziono i pid
        ssh root@$1 "ss -ptu | sed -e 's/,/\n/g' | grep pid= | sed -e 's/pid=//' | xargs kill -9"
}

function rimuovi_regole(){
	# rimuove su entrambi i router la relativa regola di logging inserita da check.sh
	# riutilizzo la stringa identificativa per rimuovere la regola
	# individuandone la posizione (vanno cancellate dall'ultima alla prima
	# altrimenti la prima cancellazione causa uno slittamento delle altre)
	iptables --line-numbers -vnL $2 | grep " check_$1 " | awk '{ print $1 }' | sort -nr | while read N ; do
		iptables -D $2 $N
	done
}



########
# LDAP #
########
function sostituisci_ldap(){
        #cancello le entry che ci sono...
        #ATTUALE ed ALTRO sono variabili globali definite esternamente
        ldapsearch -h $ATTUALE -x -s sub -b "dc=labammsis" "objectClass=gw" | grep "^dn: " | awk '{ print $2 }' | ldapdelete -D "cn=admin,dc=labammsis" -w "admin" -x
        #le rimpiazzo con le entry dell'altro router
        ldapsearch -x -c -s sub -h $ALTRO -b "dc=labammsis" "objectClass=gw" | ldapadd -x -D "cn=admin,dc=labammsis" -w admin 
}

function registra_ldap(){
	# $1 = nuovo gw
	# $2 = server LDAP da aggiornare
	ldapdelete -c -h $2 -x -D "cn=admin,dc=labammsis" -w admin "dn: ipclient=$IPCLIENT,dc=labammsis" 2> /dev/null
	TS=$(/bin/date +%s)
        echo "dn: ipclient=$IPCLIENT,dc=labammsis
objectClass: gw
ipclient: $IPCLIENT
iprouter: $1
timestamp: $TS" | ldapadd -x -D "cn=admin,dc=labammsis" -w admin -h $2
}
