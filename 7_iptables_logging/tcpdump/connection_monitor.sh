#!/bin/bash
#                       connection_monitor.sh
# legge da newconn
# se nuova connessione lancia
# traffic_monitor.sh PARAMETRI_CONNESSIONE
# se fine connessione termina traffic_monitor

# ESTENSIONE: signal handler per fare pulizia dei processi e file generati se viene terminato

function cleanup() {
	for i in /var/run/traffic_monitor_* ; do
		kill $(cat $i) && rm -f "$i"
	done
}

trap cleanup EXIT

# log format:
# Mar 28 11:41:17 Router logger: 11:41:17.574430 IP 10.1.1.1.52356 > 10.9.9.1.22: S 3572751694:3572751694(0) win 5840 <mss 1460,sackOK,timestamp 2110393 0,nop,wscale 1>

tail --pid=$$ -f /var/log/newconn | while read M G H HOST PROC TS PROTO SRC DIR DST FLAG OTHER ; do

    case "$FLAG" in
        S)  if test -f /var/run/traffic_monitor_${SRC}_${DST}.pid
            then
                echo connessione $SRC $DST gia monitorata
            else
                SIP=$(echo $SRC | cut -f-4 -d.)
                DIP=$(echo $DST | cut -f-4 -d.)
                SP=$(echo $SRC | cut -f5 -d.)
                DP=$(echo $DST | cut -f5 -d. | sed -e 's/://')
                /root/traffic_monitor.sh $SIP $DIP $SP $DP &
                echo $! > /var/run/traffic_monitor_${SRC}_${DST}.pid
                echo avvio monitoraggio connessione $SRC $DST
            fi
            ;;
        F)  if test -f /var/run/traffic_monitor_${SRC}_${DST}.pid
            then
                echo arresto monitoraggio connessione $SRC $DST
		kill $(cat /var/run/traffic_monitor_${SRC}_${DST}.pid)
                rm -f "/var/run/traffic_monitor_${SRC}_${DST}.pid"
            else
                echo processo di monitoring di $SRC $DST non trovato
            fi
            ;;
        *)  echo "$FLAG" non valido
            ;;
    esac
done


