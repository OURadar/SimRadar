#!/bin/bash

seed=1

if [ ! -z ${1} ]; then
	seed=${1}
	echo "Start using seed = ${seed}"
fi

end_seed=$((seed+1000))
while [ ${seed} -lt ${end_seed} ]; do
	radarsim -v -o -p 2400 --seed ${seed} -O ${HOME}/Downloads/big/ --tightbox --density 10000 --concept DB -W 1000
	seed=$((seed+1))
done

