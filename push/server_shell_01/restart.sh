#!/bin/bash

pid=`pgrep -f config_02`
if [ $pid ]; then
    kill $pid
fi
cd ~/fish01/fish-server/shell
./run_02.sh