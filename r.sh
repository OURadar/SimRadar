#!/bin/bash
#
#SBATCH --partition=debug_gpu
#SBATCH --ntasks=1
#SBATCH --mem=4096
#SBATCH --output=/home/boonleng/simradar/radarsim_stdout.txt
#SBATCH --error=/home/boonleng/simradar/radarsim_stderr.txt
#SBATCH --time=00:30:00
#SBATCH --job-name=simradar
#SBATCH --mail-user=boonleng@ou.edu
#SBATCH --mail-type=ALL
#SBATCH --workdir=/home/boonleng/simradar

module load CUDA/8.0.44-GCC-4.9.3-2.25
module load OpenMPI/1.10.2-GCC-4.9.3-2.25

export LD_LIBRARY=/opt/oscer/software/OpenCL/2.2-GCC-4.9.3-2.25/lib64

cd /home/boonleng/simradar

#run_big_mpi.sh
radarsim -v -p 2400 -O ${HOME}/Downloads/big/ --tightbox --concept DB -W 1000
