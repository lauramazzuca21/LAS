#!/bin/bash

MAX=$1

declare -A COUPLE_COUNTER

tail -l /home/las/anomalies | (
                while read SIP DIP ; do

                COUPLE_COUNTER[""$SIP"_"$DIP""]=$(( ${COUPLE_COUNTER[""$SIP"_"$DIP""]} + 1 ))
                if [ ${COUPLE_COUNTER[""$SIP"_"$DIP""]} -gt "$MAX" ] ; then
                       ssh root@10.$IND.$IND.254 "./firewall.sh "$SIP" "$DIP""
                	#echo "${COUPLE_COUNTER[""$SIP"_"$DIP""]}"
                fi
done )


################ come predisporre i sistemi perché i controller possano invocare firewall.sh su router
#
# generare su router e controller coppie di chiavi ssh
# mettere le rispettive chiavi pubbliche dei controller sul router 
# e quelle del router su ogni controller 
# nel file /root/.ssh/authorized_keys
#
#
