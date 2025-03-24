#!/bin/bash

[ "$UID" -eq 0 ] || (echo "sudo is required" && exec sudo bash "$0" "$@")

log_file="log-$(date +"%Y-%m-%d-%T").txt"
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

y-cruncher config cfg/1t.cfg 2>&1 | tee -a "$log_file" &

# shellcheck disable=SC2159
while [ 0 ]; do
    if tail -f -n 1 "$log_file" | grep -Eq "Iteration:"; then
        printf "\nTesting physical core %s\n" "$index" >> "$log_file"
        printf "\nTesting physical core %s\n" "$index"
        taskset -apc $index "$(pgrep -f /usr/lib/y-cruncher/Binaries/)" &> /dev/null
        index=$(((index+1)%core_count))
    fi
done
