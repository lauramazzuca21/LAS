#!/bin/bash
# Stampare gli username corrispondenti agli N più elevati userid presenti 
# nel file /etc/passwd, essendo N un parametro passato sulla riga di comando.	
cat /etc/passwd | cut -f1,3 -d: --output-delimiter=" " | while read USERNAME USERID
do 
        echo $USERID $USERNAME
done | sort -nr | head -$1 | cut -f2 -d" "



