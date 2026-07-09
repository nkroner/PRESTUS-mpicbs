# PRESTUS at MPI-CBS — compute setup

This is the institute-environment guide for the **MPI-CBS distribution of PRESTUS**. Read it
once before your first run. It complements — does not replace — the upstream PRESTUS docs in
`doc/`. PRESTUS-specific decisions live in `CLAUDE.md`; how to run a subject end-to-end lives in
`examples/mpicbs_run_templates/RUNNING.md`.

## 0. Path placeholders (important)

All MPI-CBS scripts and docs in this repo use **placeholders** instead of real paths, because
every user has their own storage blocks. Substitute your own before running:

| Placeholder | What it is | Example |
|---|---|---|
| `/data/YOUR_SOFTWARE_BLOCK` | your **personal software block** (single-user); holds Miniforge + this git clone | `/data/u_jdoe_software` |
| `/data/YOUR_STUDY_BLOCK` | your **study / working-data block** (protected `p_…`); sim in/outputs | `/data/p_01234` |
| `/data/YOUR_STUDY_BLOCK_FAST` | the fast (`pt_…`) sibling of the study block | `/data/pt_01234` |
| `/data/YOUR_OTHER_STUDY_BLOCK` | any additional study block | `/data/p_05678` |
| `$HOME` | your 10 GB home (`/data/<your-home>`) — login/config only | `/data/hu_jdoe` |

Find your blocks with `mydata` (lists your mounts) and `cbsdata -s /data/<block>` (owner/type/
quota). The simplest way to adopt a template: copy it, then find-replace the placeholders.

## 1. Storage — where things go

- **Home (`$HOME`, 10 GB)** — dotfiles/config only. **Never install software or write data here**;
  if home fills you can't log in. Check with `homedirusage`.
- **Code + conda env → `/data/YOUR_SOFTWARE_BLOCK/git/PRESTUS`** (this clone). Stays there.
- **Working data → `/data/YOUR_STUDY_BLOCK/PRESTUS`** — segmentations, acoustic/thermal outputs,
  curated results. Protected `p_…` blocks get a nightly copy + snapshots (for irreproducible
  data); fast `pt_…` blocks get snapshots only (for regenerable data) — **but quota decides**:
  a `pt_` block can be far smaller than its `p_` sibling, so bulk sim output may have to live on
  `p_` despite being regenerable. Heavy per-job transient I/O → node-local `/tmp` (see §4).
- **External config → `/data/YOUR_SOFTWARE_BLOCK/git/PRESTUS_config`** — kept *outside* the
  toolbox so updates don't clobber it (see `PRESTUS_config/`, `config_prestus_mpicbs.yaml`).

## 2. Python / Conda

- **Miniforge only**, `conda-forge` channel only — the **Anaconda default channels are BLOCKED**
  at MPI-CBS (licence). Strip `defaults`/`anaconda` from any `environment.yml` or `conda create`
  fails. `pip`/PyPI/GitHub wheels are unaffected.
- Miniforge lives at `/data/YOUR_SOFTWARE_BLOCK/miniforge`; the institute `install-conda` helper
  bootstraps it correctly (out of `$HOME`). Envs live under `.../miniforge/envs/<name>`.
- Activate with the full `conda activate <env>` (no `ca` shorthand on these systems).
- PRESTUS env: **`PRESTUS_env_4.6.0`** (SimNIBS 4.6.0 + PlanTUS deps). `wb_command` comes from
  the system `deb` install (`/bin/wb_command`), not the env.

## 3. Software — know the deployment type

- **`deb` (direct lowercase commands):** `gmsh`, `dcm2niix`, `wb_command`, `git`, `datalad`, …
- **UPPERCASE wrappers (versioned network installs):** enable then run, e.g.
  `MATLAB --version 9.15 matlab -nodesktop`, `FSL FREESURFER MATLAB`; `+`-suffixed override the
  default version. Enable a dependency before its dependent.
- **`sc` / `SCWRAP` (frozen Singularity containers):** `sc simnibs`, `sc fsl 6.0.6 <cmd>`,
  `SCWRAP ants 2.6.0 script.sh`.
- Neuroimaging tools you usually don't rebuild: **SimNIBS** (`sc simnibs`), **FSL**, **FreeSurfer**,
  **ANTs** (`sc ants`), **Connectome Workbench** (`wb_command`, deb), **gmsh** (deb).

## 4. MATLAB

- Use **`MATLAB --version 9.15`** (R2023b) — matches PRESTUS's HPC scripts and avoids
  newer-MATLAB-plus-GPU issues. Parallel Computing Toolbox is licensed, so the `gpuArray`
  acoustic backend works. Batch: `matlab -nodesktop -nosplash -batch "<code>"`.
- **Don't orchestrate pipelines from MATLAB** — it perturbs the library environment; drive
  workflows from the shell, use MATLAB only to run MATLAB code.

## 5. Running compute — pick the right tier

- **RemoteLinux terminal desktop = capped at 3 CPU cores/user.** Fine for editing, crawls for compute.
- **`getserver` interactive compute servers** = full shared machine, for GUIs + dev/testing.
  `getserver -sL` = least-loaded; **`getserver -sLi` = least-loaded *with an NVIDIA GPU*** (plain
  `-sL` can land on a GPU-less node). Verify the GPU is seen after landing.
- **Slurm = real batch compute.** `sbatch`/`squeue` **do not exist on interactive servers** —
  submit over SSH:
  ```bash
  ssh "$(getserver -b)" 'sbatch /data/YOUR_STUDY_BLOCK/.../job.sh'
  ssh "$(getserver -b)" 'squeue -u $USER'
  ```
  `sbatch` queues and returns (preferred); jobs survive node reboots. Pick the shortest partition
  that fits (`short` / `standard` / `long` / `group_servers`); `sinfo --summarize` shows occupancy.
  Fair-share priority drops the more you consume (14-day half-life) — spread large batches out.
- Directives: `#SBATCH -c <cores> --mem <N>G --time <min> --gpus 1`; log dir must exist first.
  **Enable environments *inside* the job** (the submit shell isn't inherited).

## 6. GPUs & CUDA — the k-Wave caveat

- Request a GPU with `--gpus 1` (optionally `--gpus ampere:1` for a dedicated single-GPU node,
  which queues but avoids contention). Discover the live GPU landscape with
  `sinfo -N -o "%.12P %.12N %.4c %.10m %.30G %.20f %N"`.
- **Nodes run CUDA 12.5**; there is no older CUDA selectable via Slurm. Precompiled CUDA binaries
  built for older CUDA/GPU generations can fail on the newer Ampere/Ada cards — a known failure
  mode is **silent all-NaN output**. For the compiled `cpp_gpu` backend, **build against the
  cluster's own CUDA 12.5 + gcc-12** (recipe: `examples/mpicbs_cpp_gpu_build/README.md` /
  `PRESTUS_config/BUILDING_CPP_GPU.md`) and **NaN-check** outputs on any new GPU/driver combo.
  The MATLAB `gpuArray` backend sidesteps this entirely (uses MATLAB's own CUDA runtime) and is
  the fastest route to a first working pipeline.

## 7. First-run checklist

1. Clone under `/data/YOUR_SOFTWARE_BLOCK/git/`; `git submodule update --init --recursive`.
2. Create the `PRESTUS_env_4.6.0` conda env (conda-forge only).
3. Copy `PRESTUS_config/` and set your paths in `config_prestus_mpicbs.yaml`.
4. (Optional) build the `cpp_gpu` binary — or start on `matlab_gpu`.
5. Follow `examples/mpicbs_run_templates/RUNNING.md` for a subject end-to-end.

Authoritative live fallback: the CBS IT wiki (`cbswiki.cbs.mpg.de/bin/view/EDV/FuerUser/`,
pages `ComputeClusterSlurm`, `SoftwareLinux`, `StorageStudies`, `SoftwarePython`). Tickets:
<https://tickets.cbs.mpg.de>.
