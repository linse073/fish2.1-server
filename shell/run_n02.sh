#!/bin/bash

basepath=$(cd `dirname $0`; cd ..; pwd)
cd $basepath

log_dir="log_n02"
[ ! -d "$log_dir" ] && mkdir -p "$log_dir"

ulimit -c unlimited

./skynet/skynet config/config_n02