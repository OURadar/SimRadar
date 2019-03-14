#!/bin/bash

function reset() {
	echo -e "\033[0m"
}

function green() {
	echo -e "\033[38;5;82m"
}

function red() {
	echo -e "\033[38;5;203m"
}

function show_last_seg() {
	cmd="grep -n \"==================<<<\" \"$1\" | tail -n 1 | awk -F \":\" '{print \$1}'"
	line=$(eval ${cmd})
	if [ ! -z ${line} ]; then
		tail -n +$((line)) $1 | head -n 2
		reset
		line=$((line+2))
		tail -n +$((line)) $1
	fi
}

if [[ "$#" -gt 0 && "$1" == "t" ]]; then
	# Test
	green
	show_last_seg tests_stdout.txt
	red
	show_last_seg tests_stderr.txt
elif [[ "$#" -gt 0 && "$1" == "1" ]]; then
	# Single node execution
	green
	show_last_seg simradar_single_stdout.txt
	red
	show_last_seg simradar_single_stderr.txt
elif [[ "$#" -gt 0 && "$1" == "c" ]]; then
	echo -e "\033[36m"
	show_last_seg simradar_cpu.txt
else
	green
	show_last_seg simradar_stdout.txt
	red
	show_last_seg simradar_stderr.txt
fi

echo -e "\033[0m"

