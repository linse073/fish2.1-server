#!/bin/bash

pgrep -f config_02 | xargs kill
cd ~/fish01/fish-server/shell
sleep 0.1s
./run_02.sh