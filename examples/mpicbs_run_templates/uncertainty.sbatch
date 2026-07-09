#!/bin/bash
# ── PRESTUS uncertainty analysis, MATLAB platform (one GPU job) ──
# 3 variants (default/liberal/conservative) + unified report, sequential.
# Copy, point RUN_M at your edited uncertainty.m, then submit with:
#     ssh "$(getserver -b)" 'sbatch /path/to/uncertainty.sbatch'
# Budget ~3× a single run (3 variants). At 1.0 mm this is ~10 min; for 0.5 mm
# production, switch to `-p standard` and raise --time (short caps at 3 h).
#SBATCH --job-name=PS-uncert
#SBATCH -p short
#SBATCH --gpus 1
#SBATCH -c 8
#SBATCH --mem 96G
#SBATCH --time 02:59:00
#SBATCH -o /data/YOUR_STUDY_BLOCK/PRESTUS/simulations/log_hpc/uncertainty_%j.out
#SBATCH -e /data/YOUR_STUDY_BLOCK/PRESTUS/simulations/log_hpc/uncertainty_%j.err

source /etc/profile 2>/dev/null || true
# Do NOT put the conda env on PATH/LD_LIBRARY_PATH (breaks MATLAB's licence check).
RUN_M=/data/YOUR_STUDY_BLOCK/PRESTUS/simulations/log_hpc/uncertainty.m   # <- EDIT: your edited copy

echo "== node: $(hostname) =="; nvidia-smi --query-gpu=name --format=csv,noheader
MATLAB --version 9.15 matlab -batch "run('${RUN_M}')"
rc=$?; echo "== matlab exit: $rc =="
check_ComputeClusterSlurm_memory-usage 2>/dev/null || true
exit $rc
