#!/bin/bash
#SBATCH --job-name=kwave-build
#SBATCH -p short,group_servers
#SBATCH --gpus 1
#SBATCH -c 8
#SBATCH --mem 8G
#SBATCH --time 25
#SBATCH -o /data/YOUR_STUDY_BLOCK/PRESTUS/simulations/log_hpc/kwave_build_%j.out
#SBATCH -e /data/YOUR_STUDY_BLOCK/PRESTUS/simulations/log_hpc/kwave_build_%j.out
source /etc/profile 2>/dev/null || true
echo "== node $(hostname) =="
CUDA bash /data/YOUR_SOFTWARE_BLOCK/git/PRESTUS_setup/kwave-build/build_kwave.sh
