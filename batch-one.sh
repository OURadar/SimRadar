#!/bin/bash
#
#SBATCH --partition=debug_gpu
#SBATCH --ntasks=1
#SBATCH --ntasks-per-node=1
#SBATCH --mem=1GB
#SBATCH --time=00:05:00
#SBATCH --job-name=simradar
#SBATCH --output=simradar_stdout.txt
#SBATCH --error=simradar_stderr.txt
#SBATCH --mail-user=boonleng@ou.edu
#SBATCH --mail-type=FAIL
#SBATCH --workdir=/home/boonleng/simradar

module load CUDA/8.0.44-GCC-4.9.3-2.25

function decho() {
    echo $@
    echo $@ >> ${errlog}
}

errlog="simradar_stderr.txt"
nowstr=`date`

cd /home/boonleng/simradar

decho "==================<<< $nowstr >>>================="
decho `pwd`

./simradar -o -b 0.5 -l 0.328 -c FV -L flat --sweep D:0,75,10/90,75,10/0,90,10 -t 0.01 -p 6000
#./radarsim -v -p 999 -O ${HOME}/Downloads/big/ --tightbox --concept DB -W 1000 --no-progress --dont-ask
#./cldemo

