#!/bin/bash

IPR=$1
IPS=$2
PORT=$3

###
# CHECK ARGOMENTI
###

re='^(0*(1?[0-9]{1,2}|2([0-4][0-9]|5[0-5]))\.){3}'
 re+='0*(1?[0-9]{1,2}|2([‌​0-4][0-9]|5[0-5]))$'

if ! [[ $IPR =~ $re ]]; then
   echo "error: 1st arguemt [router IP] not a valid IP" >&2; exit 1
fi

if ! [[ $IPS =~ $re ]]; then
   echo "error: 2nd arguemt [server IP] not a valid IP" >&2; exit 1
fi

re='^[0-9]+$'
if ! [[ $PORT =~ $re ]] ; then
   echo "error: 3rd arguemt [port] not a number" >&2; exit 1
fi

ssh "$IPR" "echo $IPS $PORT > "'/tmp/$(echo $SSH_CLIENT | cut -f1 -d" ") ; sleep 60'


