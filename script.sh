#!/bin/bash

[ "$UID" -eq 0 ] || exec sudo bash "$0" "$@"

core_count=$(nproc)
tumble_time=300
index=0

# shellcheck disable=SC2207
# physical cores have their thread #'s grouped in pairs
arr=( $(lstopo-no-graphics | grep -E "\(P#[0-9]*\)" | sed s/'PU L#[0-9]* (P#'// | sed s/')'// | xargs) )

stop() {
    for proc in $(pgrep -f y-cruncher); do
        kill $proc
    done
    exit $?
}

trap stop EXIT

y-cruncher stress 2>&1 | tee outfile &

# TODO: kill all process except for one to maybe reduce context switching

if tail -f outfile | grep -Eq "Allocating Memory..."; then
    echo "setting affinity"
    # shellcheck disable=SC2159
    while [ 0 ]; do
       if [ "$(cat /sys/devices/system/cpu/smt/active)" -eq 1 ]; then
           taskset -apc "${arr[$index]},${arr[$index+1]}" "$(pgrep -f /usr/lib/y-cruncher/Binaries/)"
           index=$(((index+2)%core_count))
       else
           taskset -apc $index "$(pgrep -f /usr/lib/y-cruncher/Binaries/)"
           index=$(((index+1)%core_count))
       fi
       sleep $tumble_time
   done
fi