#!/bin/bash

DEST=`./sshload.sh`

if test -z $DEST ; then
	echo "zi vedi che nun ce sta un dest connesso!!"
	exit 1
fi

echo "$DEST is in charge"

scp testo $DEST:

ssh $DEST sort testo > testo.ord
