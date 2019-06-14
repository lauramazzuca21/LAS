#!/bin/bash

#crea allo start i file di logging e li elimina allo stop
function logging() {
	if test "$1" = "start" ; then
		echo "kern.warning  /var/log/newconn" > /etc/rsyslog.d/newconn.conf
		echo "local1.info /var/log/excess" > /etc/rsyslog.d/excess.conf
	elif test "$1" = "stop" ; then
		rm -f /etc/rsyslog.d/newconn.conf
		rm -f /etc/rsyslog.d/excess.conf
	fi
	systemctl restart rsyslog
}

#funzione per inserire le regole di logging nella tabella FORWARD. 
#Prende in ingresso I o D (insert, drop) a seconda che sia start o stop
function iniziofine() {
	iptables -$1 FORWARD -s 10.1.1.0/24 -d 10.9.9.0/24 -p tcp --dport 22 --syn -j LOG --log-level warning --log-prefix " INIZIO " 
	iptables -$1 FORWARD -s 10.1.1.0/24 -d 10.9.9.0/24 -p tcp --dport 22 --tcp-flags FIN FIN -j LOG --log-level warning --log-prefix " FINE " 
}

#aggiunge in crontab l'avvio automatico di traffic_monitor.sh
function trafficmonitor() {
		crontab -l | grep -v "/root/traffic_monitor.sh" > /tmp/cron$$
		if test "$1" = "start" ; then
			echo "* * * * * /root/traffic_monitor.sh" >> /tmp/cron$$
		fi
		crontab /tmp/cron$$
}

#invocazione con start o stop per avviare o fermare il monitoring

case "$1" in 
	start)
		logging start
		iniziofine I
		./connection_monitor.sh & echo $! > /var/run/connection_monitor.pid
		trafficmonitor start
	;;
	stop)
		logging stop
		iniziofine D
		kill -TERM -$(cat /var/run/connection_monitor.pid)
		trafficmonitor stop
	;;
	*)
		echo "lanciami con start o stop"
		exit 1
	;;
esac





