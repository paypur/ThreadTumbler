#!/bin/bash

[ "$UID" -eq 0 ] || (echo "sudo is required" && exec sudo bash "$0" "$@")

log_file="$(date +"%Y-%m-%d-%T").log"
core_count=$(nproc)
index=0

#if [ "$(cat /sys/devices/system/cpu/smt/active)" -eq 1 ]; then
#    core_count=("$core_count"/2)
#fi

# shellcheck disable=SC2207
# physical cores have their thread #'s grouped in pairs
# arr=( $(lstopo-no-graphics | grep -E "\(P#[0-9]*\)" | sed s/'PU L#[0-9]* (P#'// | sed s/')'// | xargs) )

stop() {
    for proc in $(pgrep -f /usr/lib/y-cruncher/Binaries/); do
        kill -9 "$proc"
    done
    exit $?
}

trap stop EXIT

touch "$log_file"
chmod 777 "$log_file"

y-cruncher config cfg/1t.cfg 2>&1 | while read -r line; do
    echo "$line"
    if echo "$line" | grep -Eq "Iteration:"; then
        printf "Testing Logical Core %s\n" "$index" | tee -a "$log_file"
        echo "$line" | ansi2txt >> "$log_file"
        taskset -apc $index "$(pgrep -f /usr/lib/y-cruncher/Binaries/)" &> /dev/null
        index=$(((index+1)%core_count))
    elif echo "$line" | grep -Eq "Passed"; then
        echo "$line" | ansi2txt >> "$log_file"
    fi
done
