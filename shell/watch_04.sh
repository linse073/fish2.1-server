#!/bin/bash

basepath=$(cd `dirname $0`; cd ..; pwd)
cd $basepath

while true
do
	count=`ps -ef | grep config_04 | grep -v "grep" | wc -l`

	if [ $count -gt 0 ]; then
	    :
	else
	    echo "program has crashed, restarting..."
	    shell/run_04.sh
	fi
	
	sleep 10
done