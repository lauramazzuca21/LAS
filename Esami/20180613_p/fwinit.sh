#/bin/bash
iptables -I INPUT -i lo -j ACCEPT
iptables -I OUTPUT -o lo -j ACCEPT
# regole lab..
# regole syslog entrante
iptables -I INPUT -p udp --dport 514 -s 10.1.1.0/24 -d 10.1.1.254 -i eth2 -j ACCEPT
# regole ssh verso server
iptables -I OUTPUT -m range --dst-range 10.9.9.1-10.9.9.59 -p tcp --dport 22 -j ACCEPT
iptables -I INPUT -m range --src-range 10.9.9.1-10.9.9.59 -p tcp --sport 22 --state ESTABLISHED -j ACCEPT
# regole snmp verso server
iptables -I OUTPUT -m range --dst-range 10.9.9.1-10.9.9.59 -p udp --dport 161 -j ACCEPT
iptables -I INPUT -m range --src-range 10.9.9.1-10.9.9.59 -p udp --sport 161 --state ESTABLISHED -j ACCEPT
# regole ldap da server
iptables -I INPUT -m range --src-range 10.9.9.1-10.9.9.59 -p tcp --dport 389 -j ACCEPT
iptables -I OUTPUT -m range --dst-range 10.9.9.1-10.9.9.59 -p tcp --sport 389 --state ESTABLISHED -j ACCEPT
# default
iptables -P INPUT DROP
iptables -P OUTPUT DROP
iptables -P FORWARD DROP

#Vx/2 lo+drop
#Vx/2 syslog in
#Vx/2 ssh out
#Vx/2 snmp out
#Vx/2 ldap in
