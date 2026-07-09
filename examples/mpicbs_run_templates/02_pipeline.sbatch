#!/bin/bash
# ── PRESTUS on MPI-CBS: STEP 2, acoustic (+optional thermal) on a GPU node ──
# Copy this, point RUN_M at your edited run_pipeline.m, then submit with:
#     ssh "$(getserver -b)" 'sbatch /path/to/02_pipeline.sbatch'
# Outputs land in <sim>/sub-<NN>/ (reports .html, .csv, nii/). See RUNNING.md.
#SBATCH --job-name=PS-pipeline
#SBATCH -p short,group_servers
#SBATCH --gpus 1
#SBATCH --gres gpu_mem:20000M      # >=20G -> RTX6000/A40 (needed for 0.5mm); drop it to also use 16G A4000
#SBATCH -c 8
#SBATCH --mem 96G
#SBATCH --time 02:30:00            # 'short' caps at 3h; use 'standard'/'long' for bigger grids
#SBATCH -o /data/YOUR_STUDY_BLOCK/PRESTUS/simulations/log_hpc/pipeline_%j.out
#SBATCH -e /data/YOUR_STUDY_BLOCK/PRESTUS/simulations/log_hpc/pipeline_%j.err

source /etc/profile 2>/dev/null || true
# Do NOT put the conda env on PATH/LD_LIBRARY_PATH here — SimNIBS's libstdc++ breaks MATLAB's
# licence check. PRESTUS injects the SimNIBS env per-call itself; leave MATLAB's env clean.
RUN_M=/data/YOUR_STUDY_BLOCK/PRESTUS/simulations/log_hpc/run_pipeline.m   # <- EDIT: your edited copy

echo "== node: $(hostname) =="; nvidia-smi
MATLAB --version 9.15 matlab -batch "run('${RUN_M}')"
rc=$?; echo "== matlab exit: $rc =="
check_ComputeClusterSlurm_memory-usage 2>/dev/null || true
exit $rc
