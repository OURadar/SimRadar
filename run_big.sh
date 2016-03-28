#!/bin/bash

seed=1

if [ ! -z ${1} ]; then
	seed=${1}
	echo "Start using seed = ${seed}"
fi

while [ 1 ]; do
	radarsim -vv -o -p 2400 --seed ${seed} -O ${HOME}/Downloads/big/ --tightbox --density 10000 --concept DB -W 1000
	seed=$((seed+1))
done

