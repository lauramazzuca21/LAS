#!/bin/bash

iptables -F

iptables -I INPUT -i lo -j ACCEPT
iptables -I OUTPUT -o lo -j ACCEPT

iptables -I INPUT -p tcp -s 10.9.9.0/24 -i eth1 -j ACCEPT
iptables -I OUTPUT -m state -d 10.9.9.0/24 -o eth1 --state ESTABLISHED,RELATED -j ACCEPT


#SEMPRE da qui in giu'
iptables -I INPUT -s 192.168.56.1 -i eth3 -j ACCEPT
iptables -I OUTPUT -m state -d 192.168.56.1 -o eth3 --state ESTABLISHED,RELATED -j ACCEPT

iptables -P INPUT DROP
iptables -P OUTPUT DROP
iptables -P FORWARD DROP
