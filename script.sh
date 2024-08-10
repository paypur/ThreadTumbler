#!/bin/bash

[ "$UID" -eq 0 ] || exec sudo bash "$0" "$@"

core_num=0
run_time_per_core=3600

# physical cores have their thread #'s grouped in pairs
# shellcheck disable=SC2207
arr=( $(lstopo-no-graphics | grep -E "\(P#[0-9]*\)" | sed s/'PU L#[0-9]* (P#'// | sed s/')'// | xargs) )

#y-cruncher stress -M:8g &

# shellcheck disable=SC2159
while [ 0 ]; do
    if [ "$(cat /sys/devices/system/cpu/smt/active)" -eq 1 ]; then
        taskset -apc "${arr[core_num]},${arr[core_num+1]}" "$(pgrep -f /usr/lib/y-cruncher/Binaries/)"
        core_num=$((core_num+2))
    else
        taskset -apc $core_num "$(pgrep -f /usr/lib/y-cruncher/Binaries/)"
        core_num=$((core_num+1))
    fi
    sleep $run_time_per_core
done
