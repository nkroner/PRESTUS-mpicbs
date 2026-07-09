# CLAUDE.md — PRESTUS (project)

> Project memory for the PRESTUS ultrasound-simulation toolbox at MPI-CBS.
> **The MPI-CBS institute environment (storage, Conda, software system, Slurm, GPUs, MATLAB) is
> documented in [`SETUP_MPICBS.md`](SETUP_MPICBS.md) — read that first for the compute setup.**
> This file covers only PRESTUS-specific setup and decisions.

## Read the PRESTUS docs first

The full PRESTUS documentation lives **in this repo** under `doc/` — the source markdown behind
<https://donders-institute.github.io/PRESTUS/>. **Consult it before any install or config
decision.** For how *your installed version* behaves, local `doc/` is the right authority: it
matches this checkout's code, offline and with no rendering loss.

**Branch caveat (important — local `doc/` is NOT a full mirror of the live site).** This branch
is based on **`main`**, but the live docs site is built from the **`development`** branch, which
is **ahead**. So:

- **Core install / config / the stable pipeline → local `doc/`** (matches your code; most pages
  are byte-identical to live anyway).
- **Advanced or newest features → check the live site** — local `doc/` lacks them entirely:
  group HTML report, multi-transducer / sequential-thermal / limited-acoustic-FOV, defacing
  (`pydeface`), the newer `grid.*_fov_*` / `thermal_*` / `deface` parameters.
- **Localite neuronav is a docs-lag, NOT a code-lag (verified 2026-07).** The handling —
  `InstrumentMarker` markertype, `tracker_to_bowl_mm` offset calibration, zero-origin
  planning-image affine (`canonical_affine_transform`/`ras_to_grid`) — is **already implemented
  in our checkout and usable now**. What lags is only our local `doc/doc_placement_neuronav.md`
  (no `InstrumentMarker`/`EntryTarget` sections; missing the blunt "don't reproject Localite
  coords with the SimNIBS **m2m** T1 header → shifts tens of mm; use the **planning** T1 header"
  warning). `doc_coordinate_systems.md` *does* cover the zero-origin/m2m content. So: the feature
  works here — just **read the live `doc_placement_neuronav` page for guidance** when doing real
  Localite placement.
- Because the site tracks `development`, its **code** is likely ahead of this branch too: if a
  live-doc claim doesn't match local PRESTUS behaviour, that branch gap is why — trust local
  code's behaviour, and integrate `development` deliberately later (not mid-setup).

Framing: the docs assume the **Donders HPC** (its modules, paths, scheduler, defaults). **This
is MPI-CBS, not that** — adapt everything to the global file's constraints (10 GB home,
conda-forge-only, the UPPERCASE system, `getserver`/Slurm, conda envs under
`/data/YOUR_SOFTWARE_BLOCK/miniforge/envs`).

**MPI-CBS how-tos (ours, not upstream):** run a subject end-to-end →
`examples/mpicbs_run_templates/RUNNING.md` (+ copy-edit-submit templates); build/deploy the
`cpp_gpu` binary → `examples/mpicbs_cpp_gpu_build/README.md`; update the install →
`PRESTUS_config/UPDATING.md`. Start from `RUNNING.md` when actually running work here.

`doc/` entry points: setup — `doc_installation.md`, `doc_getting-started.md`, `doc_gui.md`;
reference — `doc_parameters.md`, `doc_modules.md`, `doc_backend.md`, `doc_hpc.md`,
`doc_coordinate_systems.md`, `doc_functions.md`; transducer — `doc_transducer.md`,
`doc_async_transducer.md`, `doc_calibration.md`; placement — `doc_placement.md` +
`doc_placement_{heuristic,neuronav,plantus}.md`; head/media — `doc_preproc.md`, `doc_medium.md`,
`doc_pseudoCT.md`; sims — `doc_simulations-{acoustic,thermal}.md`; advanced — `doc_advanced.md`,
`doc_uncertainty.md`, `doc_multi_isppa.md`, `doc_group.md`; ops — `doc_testing.md`,
`doc_troubleshooting.md`, `doc_telemetry.md`, `doc_usage-statistics.md`, `doc_outputs.md`,
`CHANGELOG.md`. When in doubt, open the relevant file rather than guessing.

## Install layout — code vs. data

- **Toolbox (code + conda env) → `/data/YOUR_SOFTWARE_BLOCK/git/PRESTUS`** (personal software
  block). Stays here — this is the install.
- **Conda env: `PRESTUS_env_4.6.0`** under `/data/YOUR_SOFTWARE_BLOCK/miniforge/envs/` — SimNIBS
  4.6.0 (PRESTUS's tested pin) + PlanTUS Python deps (`nilearn`, `vtk`, `h5py`, `pynput`).
  Connectome Workbench is **not** in the env — `wb_command` comes from the system `deb` install
  (`/bin/wb_command`). If PlanTUS placement is adopted (it auto-discovers `wb_command` in the
  env `bin/`), either install `connectome-workbench` into the env then, or set
  `placement.plantus.connectome_wb_path` to `/bin`.
- **Working data → `/data/YOUR_STUDY_BLOCK/PRESTUS`** (LITFUS_MRT, general TUS-dev storage): Ernie
  download, `charm` segmentations, acoustic/thermal sim outputs, curated results.
  - **Capacity note:** bulk outputs go on the **`p_03135`** block (1 TB) *despite being
    regenerable*, because **`pt_03135` is only 10 GB** — too small for sim output. Reserve
    `pt_03135` for small transient scratch; use node-local `/tmp` for heavy per-job I/O and copy
    finals back (see the global file's storage/Slurm sections).
- Study-specific subject data/outputs → that study's own block (e.g. UMBRELLA/NAcc →
  `/data/YOUR_OTHER_STUDY_BLOCK`). Keep the toolbox **study-agnostic** — it's for all current & future TUS
  studies.
- **Shared MPI-CBS distribution.** This is the institute's PRESTUS deployment; each user keeps
  their own install under their personal software block and their own data under their study
  block (all such paths are placeholders — see `SETUP_MPICBS.md`).

## Input images — check orientation first (PRESTUS assumes RAS)

**Before running any subject, confirm the input T1/T2 is in RAS orientation.** PRESTUS has a
bug (v0.6.1) where `preproc_head` reorients the head *image* to RAS+ but **not** the
transducer/focus *coordinates* — so non-RAS input silently misregisters the transducer and
focus (they land in the jaw/cheeks, focus in water) while the simulation still runs to
completion and looks fine. One-line check:

```python
import nibabel as nib
print(''.join(nib.aff2axcodes(nib.load('sub-XXX_T1w.nii.gz').affine)))   # want: RAS
```

In practice this is a non-issue for our real scans — Siemens MPRAGE / `dcm2niix` output (e.g.
`/data/YOUR_OTHER_STUDY_BLOCK/...`) is **RAS**, so `ensure_ras_plus` is a no-op and nothing breaks. It only
bit us on the **SimNIBS Ernie *example* T1, which is PSR** (unusual, axis-permuted). If a
dataset ever comes in non-RAS, reorient before `charm`: `nib.as_closest_canonical(im)` **then
`im.set_qform(im.affine, code=1)` + `set_sform(..., code=1)`** (canonical alone leaves
`qform_code=0`, which charm rejects). Only PSR is confirmed to break; treat any non-RAS as
suspect. (Worth reporting upstream eventually.)

## MATLAB for PRESTUS

Use **`MATLAB -v 9.15`** (R2023b): it matches PRESTUS's HPC scripts and the version its docs
assume, and avoids newer-MATLAB-plus-GPU issues. Parallel Computing Toolbox is licensed here, so
the `gpuArray` acoustic backend is available.

## Acoustic backend & the CUDA/k-Wave caveat

- The bundled k-Wave submodule sits on PRESTUS's **pinned commit** (~Aug 2023) — what it was
  tested against. Don't bump it independently of PRESTUS.
- **Start with the MATLAB `gpuArray` backend.** It uses MATLAB's own CUDA runtime and
  **sidesteps the institute CUDA-binary problem entirely** — fastest route to a working pipeline.
- The compiled **`cpp_gpu`** backend is **built and validated** (2026-07): we recompiled
  `kspaceFirstOrder-CUDA` against the cluster's own **CUDA 12.5 + gcc-12** — **no IT ticket
  needed** (the stock CUDA-11 precompiled binaries won't load). It runs **~4× faster** than
  `matlab_gpu` with numerically identical results (validated finite/no-NaN on Turing/CUDA 12.5).
  Recipe + prebuilt binary: `PRESTUS_config/BUILDING_CPP_GPU.md` and
  `examples/mpicbs_cpp_gpu_build/`. Deploy = copy the binary into `external/k-wave/k-Wave/binaries/`
  (that's `getkWavePath('binaries')`, NOT `external/k-wave/binaries/`); runtime needs the
  `kwave_build` conda env to persist (binary rpath). **Still NaN-check** on any new
  GPU/driver/CUDA combo — the silent-all-NaN gotcha (global file "GPUs & CUDA") is exactly why
  it's built against 12.5 rather than run from a stock older-CUDA binary. Rebuild it whenever the
  k-Wave submodule version changes.

## Related tools sharing SimNIBS

**BabelBrain** and **PlanTUS** are already installed for this environment and also use
SimNIBS / `wb_command` — useful references for how MPI-CBS constraints were solved. Reference files exist at docs/BabelBrain_setup.md and docs/PlanTUS_setup.md — read them when working on anything that touches shared SimNIBS/charm/wb_command/GPU-Slurm setup, or when reconciling multiple SimNIBS/PlanTUS installs on this account.

## Live PRESTUS state — source of truth

Resolved, evolving config (`simnibs_bin_path`, `ld_library_path`, `plantus.script_path`/
`env_path`, the config overrides, the Slurm job template) is **not duplicated here** to avoid
drift. Source of truth: the **external project config dir
`/data/YOUR_SOFTWARE_BLOCK/git/PRESTUS_config/`** — kept outside the toolbox (per
`doc_getting-started.md`) so toolbox updates don't clobber it. It holds
`config_prestus_mpicbs.yaml` (an **overrides-only** file — only the deltas from the default,
deep-merged onto it) plus a copy of `config_default.yaml` as the merge base (never edit the
default). Load with
`load_parameters('config_prestus_mpicbs.yaml', '/data/YOUR_SOFTWARE_BLOCK/git/PRESTUS_config')`.
See also Claude Code's own project memory (`/memory`). This file holds the durable decisions;
live paths live with the config.

**Git branch — do not lose our patches.** This install runs on branch
**`feature/mpicbs-hpc-adapt`**, not `main`. Essential local changes live ONLY here: the MPI-CBS
Slurm dispatch (`hpc.name='mpicbs'` ssh-submit), two bug fixes (`log_timer`, `skull_rubber_wrap`),
and the `examples/mpicbs_*` how-tos + `CLAUDE.md`. A plain `git checkout main` silently reverts
all of it and breaks the pipeline. To update PRESTUS, follow `PRESTUS_config/UPDATING.md` (fetch
`main`, then **rebase this branch onto it**) — never just switch to `main`.
