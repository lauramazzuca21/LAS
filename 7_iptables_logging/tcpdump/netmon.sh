#!/bin/bash
#                               netmon.sh
#        se invocato con start
# modifica syslog.conf e riavvia syslogd
# lancia connection_monitor.sh
#        se invocato con stop
# ripulisce tutto

function logging() {
        if test "$1" = "start" ; then
                echo "local0.info /var/log/newconn" > /etc/rsyslog.d/newconn.conf
                echo "local1.info /var/log/excess" > /etc/rsyslog.d/excess.conf
        elif test "$1" = "stop" ; then
                rm -f /etc/rsyslog.d/newconn.conf
                rm -f /etc/rsyslog.d/excess.conf
        fi
        systemctl restart rsyslog
}

function monitor() {
        if test "$1" = "start" ; then
		( tcpdump -lnp -i eth2 'tcp[tcpflags] & (tcp-syn|tcp-fin) != 0 and src net 10.1.1.0/24 and dst net 10.9.9.0/24' 2>/dev/null | logger -p local0.info ) &
		echo $! > /var/run/sys-fin-monitor.pid
		/root/connection_monitor.sh &
		echo $! > /var/run/connection_monitor.pid
        elif test "$1" = "stop" ; then
		# assunzione: il pid della shell in background è uguale al numero del process group
		# kill con pid negativo termina tutti i processi del pgrp
		kill -15 -$(cat /var/run/sys-fin-monitor.pid)
		rm -f /var/run/sys-fin-monitor.pid
		# connection monitor gestisce internamente la terminazione dei sottoprocessi e pulisce
		kill -15 $(cat /var/run/connection_monitor.pid)
		rm -f /var/run/connection_monitor.pid
	fi
}

case "$1" in 
	start)
		logging start
		monitor start
		;;
	stop) 
		monitor stop
		logging stop
		;;
	*) 
		echo "Usage: $0 {start|stop}"
		;;
esac

