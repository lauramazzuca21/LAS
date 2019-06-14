#!/bin/bash

iptables -F

iptables -I INPUT -i lo -j ACCEPT
iptables -I OUTPUT -o lo -j ACCEPT

iptables -P INPUT DROP
iptables -P OUTPUT DROP
iptables -P FORWARD DROP

# PER DEBUG VIA SSH DALLA MACCHINA HOST DI Vbox
iptables -I INPUT -p tcp -i eth3 -s 192.168.122.30 -d 192.168.122.233 --dport 22 -j ACCEPT
iptables -I OUTPUT -p tcp -o eth3 -d 192.168.122.30 -s 192.168.122.233 --sport 22 -m state --state ESTABLISHED,RELATED -j ACCEPT

# rsyslog in ingresso
iptables -I INPUT -p udp -s 10.1.1.0/24 -d 10.1.1.254 --dport 514 -j ACCEPT
iptables -I OUTPUT -p udp -d 10.1.1.0/24 -s 10.1.1.254 --sport 514 -m state --state ESTABLISHED,RELATED -j ACCEPT

# snmp in uscita
iptables -I OUTPUT -p udp -d 10.1.1.0/24 -s 10.1.1.254 --dport 161 -j ACCEPT
iptables -I INPUT -p udp -s 10.1.1.0/24 -d 10.1.1.254 --sport 161 -m state --state ESTABLISHED,RELATED -j ACCEPT

