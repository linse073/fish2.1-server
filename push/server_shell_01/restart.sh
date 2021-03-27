#!/bin/bash

pgrep -f config_02 | xargs kill
cd ~/fish01/fish-server/shell
./run_02.sh