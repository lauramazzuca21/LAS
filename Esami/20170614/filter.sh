#!/bin/bash

LINE=$(cat current_line)

if test -z $LINE ; then
	LINE=1
fi

tail -n +$LINE /var/log/packets.log | (while read ORA SIP DIP ; do
	LINE=$(( $LINE + 1 ))
	./ldapinsert.sh $ORA $SIP $DIP
done

echo $LINE > current_line

./ldapdrop.sh

################ esecuzione automatica script ogni 5 min
#inserire con crontab -e la riga
# */5 * * * * /home/root/filter.sh
	
