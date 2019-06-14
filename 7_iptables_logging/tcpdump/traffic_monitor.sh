#!/bin/bash
#                       traffic_monitor.sh
# conta i pacchetti della connessione
# se passa 1 minuto resetta il contatore
# se soglia superata lancia
# log_user.sh PARAMETRI_CONNESSIONE

# invocato come traffic_monitor.sh $SIP $DIP $SP $DP
SOGLIA=1000
SIP=$1
DIP=$2
SP=$3
DP=$4

# ESTENSIONE: controllo formale dei parametri

function monitor() {
        tcpdump -vnl -i eth2 -c $SOGLIA src host $SIP and dst host $DIP  and src port $SP and dst port $DP > /dev/null 2>&1
	# tcpdump è bloccante, se esce prima dei 60" vuol dire che 
	# ha ricevuto oltre $SOGLIA pacchetti, quindi avvia log_user
        nohup /root/log_user.sh $SIP $DIP $SP $DP &
}

while true ; do
        monitor &
	# termina monitor dopo 60" per prevenire l'esecuzione di log_user
	# se in questo tempo non è ancora stata raggiunta la soglia 
        sleep 60 && kill $!
done


