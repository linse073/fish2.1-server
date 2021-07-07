#!/bin/bash

basepath=$(cd `dirname $0`; cd ..; pwd)
cd $basepath

while true
do
	count=`ps -ef | grep config_02 | grep -v "grep" | wc -l`

	if [ $count -gt 0 ]; then
	    :
	else
	    echo "program has crashed, restarting..."
	    bash shell/run_02.sh
	fi
	
	sleep 10
done