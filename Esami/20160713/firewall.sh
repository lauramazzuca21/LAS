#!/bin/bash

SIP=$1
DIP=$2


if ! iptables -C INPUT -s "$SIP" -d "$DIP" -j DROP ; then
	iptables -I INPUT -s "$SIP" -d "$DIP" -j DROP
	iptables -I INPUT -d "$SIP" -s "$DIP" -j DROP
	echo "./remove_rules.sh "$SIP" "$DIP"" | at now + 15 minutes 2&>1
fi

