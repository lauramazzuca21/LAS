#!/bin/bash

SIP=$1
DIP=$2


iptables -D INPUT -s "$SIP" -d "$DIP" -j DROP
iptables -D INPUT -d "$SIP" -s "$DIP" -j DROP

tcpdump tcp "(src host "$SIP" and dest host "$DIP")" > /var/log/""$SIP"_"$DIP""
