#!/bin/bash
#
#SBATCH --partition=debug_gpu
#SBATCH --ntasks=1
#SBATCH --mem=4GB
#SBATCH --output=radarsim_stdout.txt
#SBATCH --error=radarsim_stderr.txt
#SBATCH --time=00:05:00
#SBATCH --job-name=simradar
#SBATCH --mail-user=boonleng@ou.edu
#SBATCH --mail-type=FAIL
#SBATCH --workdir=/home/boonleng/simradar

#module load OpenCL/2.2-GCC-4.9.3-2.25
module load CUDA/8.0.44-GCC-4.9.3-2.25
#module load OpenMPI/1.10.2-GCC-4.9.3-2.25

#export LD_LIBRARY=/opt/oscer/software/CUDA/8.0.44-GCC-4.9.3-2.25/lib64:/opt/oscer/software/OpenMPI/1.10.2-GCC-4.9.3-2.25/lib
#export LD_LIBRARY=/opt/oscer/software/CUDA/8.0.44-GCC-4.9.3-2.25/lib64

cd /home/boonleng/simradar

echo "====================================" > radarsim_stdout.txt
echo "====================================" > radarsim_stderr.txt

#run_big_mpi.sh
./radarsim -vvv -p 2 -O ${HOME}/Downloads/big/ --tightbox --concept DB -W 1000
#./test_rs

