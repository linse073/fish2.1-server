#!/bin/bash

basepath=$(cd `dirname $0`; cd ..; pwd)
cd $basepath

log_dir="log_wc01"
[ ! -d "$log_dir" ] && mkdir -p "$log_dir"

ulimit -c unlimited

./skynet/skynet config/config_wc01