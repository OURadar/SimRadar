#!/bin/bash

if [ -z $1 ]; then
	hosts="boomer";
else
	hosts=$@;
fi

for host in $hosts; do
	echo -e "Deploying to \033[32m$host\033[0m ..."

	rsync -av README.md Makefile *.[chm] *.sh *.cl $host:~/radarsim/ --exclude .DS_Store --exclude log --exclude data

done
