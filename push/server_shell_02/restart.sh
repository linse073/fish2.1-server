#!/bin/bash

pgrep -f config_02 | xargs kill
cd ~/fish02/fish2-server/shell
sleep 0.1s
./run_02.sh