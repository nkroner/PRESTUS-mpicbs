#!/bin/bash
# ── PRESTUS on MPI-CBS: STEP 1, charm segmentation (CPU only; no GPU/MATLAB) ──
# Copy this, edit the SUBJ/T1/T2 block, then submit from an interactive node with:
#     ssh "$(getserver -b)" 'sbatch /path/to/01_segmentation.sbatch'
# Produces  <seg>/m2m_sub-<NN>/  (~1.5 h, ~760 MB).  See RUNNING.md.
#SBATCH --job-name=charm
#SBATCH -p short,group_servers
#SBATCH -c 8
#SBATCH --mem 32G
#SBATCH --time 02:30:00
#SBATCH -o /data/YOUR_STUDY_BLOCK/PRESTUS/segmentation/log_hpc/seg_%j.out
#SBATCH -e /data/YOUR_STUDY_BLOCK/PRESTUS/segmentation/log_hpc/seg_%j.err

source /etc/profile 2>/dev/null || true    # MUST be before `set -e` (profile returns nonzero)
set -euo pipefail
ENVBIN=/data/YOUR_SOFTWARE_BLOCK/miniforge/envs/PRESTUS_env_4.6.0/bin
SIMLIB=/data/YOUR_SOFTWARE_BLOCK/miniforge/envs/PRESTUS_env_4.6.0/lib/python3.11/site-packages/simnibs/external/bin/linux
export PATH="$ENVBIN:$PATH"
export LD_LIBRARY_PATH="$SIMLIB:${LD_LIBRARY_PATH:-}"

# ── EDIT: subject + inputs (T1 required, T2 optional). Inputs MUST be RAS — check first! ──
SUBJ=002
T1=/data/YOUR_STUDY_BLOCK/PRESTUS/data/sub-${SUBJ}_T1w.nii.gz
T2=/data/YOUR_STUDY_BLOCK/PRESTUS/data/sub-${SUBJ}_T2w.nii.gz
# ──────────────────────────────────────────────────────────────────────────────────────

cd /data/YOUR_STUDY_BLOCK/PRESTUS/segmentation
echo "== node: $(hostname) =="; charm --version
charm sub-${SUBJ} "$T1" "$T2" --forcerun          # drop "$T2" for a T1-only run
ls -la "m2m_sub-${SUBJ}/final_tissues.nii.gz"
check_ComputeClusterSlurm_memory-usage 2>/dev/null || true
