# PRESTUS-mpicbs — the MPI-CBS distribution of PRESTUS

A fork of [Donders-Institute/PRESTUS](https://github.com/Donders-Institute/PRESTUS) — the
transcranial-ultrasound simulation toolbox — **adapted for the MPI-CBS Leipzig compute
environment** and extended with a few generic features. Upstream `README.md` and `doc/` still
apply; this file describes only what this distribution adds and how to use it here.

## What this distribution adds on top of upstream

**Generic features (not MPI-CBS-specific — candidates to contribute upstream):**
- **Truly flat 2D matrix / phased arrays** (`is_curved: false`). Upstream matrix arrays require a
  curved bowl; this makes a genuinely flat aperture (e.g. a diced 2D matrix array) simulate
  end-to-end — electronic steering, free-water and through-skull. See `CLAUDE.md` for the caveats.
- **Bug fixes:** the `grid_step_mm` typo (never-set field → `grid.resolution_mm`), plus
  `log_timer` and `skull_rubber_wrap` fixes.

**MPI-CBS infrastructure:**
- **Slurm dispatch** (`hpc.name = 'mpicbs'`) — ssh-submit to the institute scheduler.
- **Run templates + how-tos** — `examples/mpicbs_run_templates/` (`RUNNING.md` + copy-edit-submit
  `.sbatch`/`.m` for segmentation, the pipeline, and uncertainty analysis).
- **cpp_gpu build recipe** — `examples/mpicbs_cpp_gpu_build/` (compile `kspaceFirstOrder-CUDA`
  against the cluster's CUDA 12.5 + gcc-12; the binary itself is **not shipped** — build your own).
- **Environment guide** — `SETUP_MPICBS.md` (storage, conda, software, Slurm, GPU).

## Getting started

1. **Environment:** read [`SETUP_MPICBS.md`](SETUP_MPICBS.md) first — storage blocks, conda,
   the software system, Slurm submission, the GPU/CUDA caveat.
2. **Install:** clone under your software block, `git submodule update --init --recursive`,
   create the `PRESTUS_env_4.6.0` conda env (conda-forge only), copy `PRESTUS_config/` and set
   your paths.
3. **Run a subject:** follow [`examples/mpicbs_run_templates/RUNNING.md`](examples/mpicbs_run_templates/RUNNING.md).

> **Paths are placeholders.** Every script/doc uses `/data/YOUR_SOFTWARE_BLOCK` and
> `/data/YOUR_STUDY_BLOCK` — substitute your own storage blocks (see `SETUP_MPICBS.md` §0).

## Staying current with upstream

This fork tracks `Donders-Institute/PRESTUS`. To pull upstream changes:

```bash
git remote add upstream https://github.com/Donders-Institute/PRESTUS.git   # once
git fetch upstream
git rebase upstream/main        # or merge; resolve conflicts in the MPI-CBS layer
```

See `PRESTUS_config/UPDATING.md` for the full procedure (it keeps the MPI-CBS patches on top of
the upstream base). As generic features here are merged upstream, they drop out of this fork's
delta.

## Layout of the additions

```
SETUP_MPICBS.md                     institute environment guide
CLAUDE.md                           PRESTUS-at-MPI-CBS decisions (agent + human)
examples/mpicbs_run_templates/      run a subject end-to-end (RUNNING.md + templates)
examples/mpicbs_cpp_gpu_build/      cpp_gpu build recipe (no binary)
PRESTUS_config/                     external config (template + UPDATING.md + BUILDING_CPP_GPU.md)
```
