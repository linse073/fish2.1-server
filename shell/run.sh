#!/bin/bash

basepath=$(cd `dirname $0`; cd ..; pwd)
cd $basepath

log_dir="log"
[ ! -d "$log_dir" ] && mkdir -p "$log_dir"

./skynet/skynet config/config