#!/bin/bash

[ "$UID" -eq 0 ] || exec sudo bash "$0" "$@"

log_file="log-$(date +"%Y-%m-%d-%T").txt"
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

y-cruncher stress -M:8g -D:60 2>&1 | tee "$log_file" &

# shellcheck disable=SC2159
while [ 0 ]; do
    if tail -f -n 1 "$log_file" | grep -Eq "Iteration:"; then
        printf "\nTesting physical core %s\n" "$index" >> "$log_file"
        printf "\nTesting physical core %s\n" "$index"
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
