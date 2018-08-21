#!/bin/bash
# Se il carico del sistema è inferiore ad una soglia specificata 
# come secondo parametro dello script, lancia il comando specificato
# come terzo parametro con tutti gli argomenti specificati dopo.
#
# Se non è sceso a zero il numero di tentativi specificato come 
# primo parametro, con at rischedula il test dopo 2 minuti, 
# decrementando il contatore di tentativi

# testare se $1 e $2 sono numeri
# studiare "help [[" e notare che fa da solo da inibitore delle 
# espansioni di caratteri speciali, la regex non deve essere "quotata"

THIS=/home/las/niceexec-base.sh

if ! [[ "$1" =~ ^[0-9]+$ ]] ; then
	echo "$1 non è un numero di tentativi valido"
	exit 1
else 
	TRY=$1
fi

if ! [[ "$2" =~ ^[0-9]+$ ]] ; then
	echo "$2 non è una soglia intera di carico valida"
	exit 2
else
	THRESHOLD=$2
fi

# $3 deve essere eseguibile, file standard e con path assoluto 
# per evitare problemi con l'environment di atd

if ! [[ -x "$3" && -f "$3" && "$3" =~ ^/ ]] ; then
	echo "$3" non è un eseguibile con path assoluto
	exit 3
fi

# controllo se esiste configurazione syslog o la inserisco
if ! egrep -q "^local4.*/var/log/niceexec.log$" /etc/rsyslog.d/*.conf ; then
	echo "local4.*  /var/log/niceexec.log" > /etc/rsyslog.d/niceexec.conf
	/bin/systemctl restart rsyslog
fi

# elimino tentativi e soglia
shift 2

# ipotesi semplificativa: solo la parte intera del carico a 1 minuto
# per farlo, devo sapere qual è il delimitatore dei decimali 
# in accordo alla localizzazione attiva: man locale

LOAD=$(uptime | awk -F 'average: ' '{ print $3 }' | cut -f1 -d$(locale decimal_point))

if test $LOAD -lt $TRESHOLD ; then
	eval "$@"
elif test "$TRY" -gt 0 ; then 
	TRY=$(( $TRY - 1 )
	echo $TRY $THRESHOLD "$@" | at now +2 minutes
	logger -p local4.info "tento $@ al piu' altre $TRY volte"
else
	logger -p local4.error "limite di tentativi raggiunto per $@" 
fi

