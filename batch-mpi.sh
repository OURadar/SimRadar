#!/bin/bash
#
#SBATCH --partition=gpu
#SBATCH --ntasks=3
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
module load OpenMPI/1.10.2-GCC-4.9.3-2.25

function decho() {
    echo $@
    echo $@ >> ${errlog}
}

errlog="simradar_stderr.txt"
nowstr=`date`

cd /home/boonleng/simradar

decho "==================<<< $nowstr >>>================="
decho `pwd`

#run_big_mpi.sh
#./radarsim -vvv -p 2 -O ${HOME}/Downloads/big/ --tightbox --concept DB -W 1000
mpirun radarsim-mpi -v -p 1000 ${HOME}/Downloads/big --tightbox --concept DB -W 1000 --no-progress

