#!/bin/bash

[ "$UID" -eq 0 ] || exec sudo bash "$0" "$@"

core_count=$(nproc)
index=0

# shellcheck disable=SC2207
# physical cores have their thread #'s grouped in pairs
arr=( $(lstopo-no-graphics | grep -E "\(P#[0-9]*\)" | sed s/'PU L#[0-9]* (P#'// | sed s/')'// | xargs) )

stop() {
    for proc in $(pgrep -f y-cruncher); do
        kill "$proc"
    done
    exit $?
}

trap stop EXIT

y-cruncher stress -M:8g -D:60 2>&1 | tee log.txt &

while [ 0 ]; do
    if tail -f -n 1 log.txt | grep -Eq "Iteration:"; then
        echo "Testing physical core $index" >> log.txt # TODO: doesnt work
        # shellcheck disable=SC2159
        if [ "$(cat /sys/devices/system/cpu/smt/active)" -eq 1 ]; then
            taskset -apc "${arr[$index]},${arr[$index+1]}" "$(pgrep -f /usr/lib/y-cruncher/Binaries/)" &> /dev/null
            index=$(((index+2)%core_count))
        else
            taskset -apc $index "$(pgrep -f /usr/lib/y-cruncher/Binaries/)" &> /dev/null
            index=$(((index+1)%core_count))
        fi
    fi
done
