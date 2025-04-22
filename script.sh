#!/bin/bash

if [ "$UID" -ne 0 ]; then
  echo "sudo is required"
  exec sudo bash "$0" "$@"
  exit $?
fi

log_file="$(date +%Y-%m-%d_%T)".log
index=0

core_array=( $(lstopo-no-graphics | grep -E "\(P#[0-9]*\)" | sed s/'PU L#[0-9]* (P#'// | sed s/')'// | xargs) )
#core_array=(0 8 1 9 5 13 6 14 7 15)

#if [ "$(cat /sys/devices/system/cpu/smt/active)" -eq 1 ]; then
#    core_count=("$core_count"/2)
#fi

# shellcheck disable=SC2207
# physical cores have their thread #'s grouped in pairs

stop() {
    for proc in $(pgrep -f /usr/lib/y-cruncher/Binaries/); do
        kill -9 "$proc"
    done
    exit $?
}

trap stop EXIT

touch "$log_file"
chmod 777 "$log_file"

y-cruncher config cfg/2t.cfg 2>&1 | while read -r line; do
    # TODO: error logging
    if echo "$line" | grep -Eq "Iteration:"; then
        printf "Physical Core %s\n" "${core_array[$index]}" | tee -a "$log_file"
        echo "$line" | ansi2txt >> "$log_file"
        taskset -apc "${core_array[$index]}","${core_array[$index+1]}" "$(pgrep -f /usr/lib/y-cruncher/Binaries/)" &> /dev/null
        index=$(((index+2)%${#core_array[@]}))
    elif echo "$line" | grep -Eq "Passed"; then
        echo "$line" | ansi2txt >> "$log_file"
    fi
    echo "$line"
done
