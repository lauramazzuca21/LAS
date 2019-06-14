#!/bin/bash

function check() {
	if nc -nz 10.1.1.$1 22 ; then
		found=1
		for i in ${PREV_FOUND[@]} ; do
			if  [ "${PREV_FOUND[$i]}" = "10.1.1.$1" ] ; then
				found=0
			fi
		done
		if ! $found ; then
			PREV_FOUND+=("10.1.1.$1")
			./config.sh "10.1.1.$1"
		fi
	fi
}

declare -a CHKPID
declare -a PREV_FOUND
while sleep 30 ; do
	for i in {10..253} ; do
		check $i & CHKPID[$i]=$!
	done
	while ps ${CHKPID[@]} >/dev/null 2>&1 ; do sleep 1 ;
	
	cat /dev/null > /root/active.list
	for i in ${PREV_FOUND[@]} ; do
		echo "${PREV_FOUND[$i]}" >> /root/active.list
	done
done
