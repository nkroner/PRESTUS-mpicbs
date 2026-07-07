# BabelBrain — existing setup (reference for Claude Code)

> Orientation on the **BabelBrain** install already working in this MPI-CBS environment, so
> Claude Code has context when it overlaps with PRESTUS (shared SimNIBS/`charm`, `wb_command`,
> GPU/Slurm patterns). Institute infrastructure is in `~/.claude/CLAUDE.md` — not repeated here.
>
> **Source & authority:** reconstructed from prior setup conversations (clean install March 2026,
> BabelBrain **v0.8.1**). The authoritative write-up is the existing **Notion "BabelBrain
> pipeline" page**; the official docs (<https://proteusmrighifu.github.io/BabelBrain/>) are the
> source of truth for anything *not* MPI-CBS-specific. Env/YAML names change between releases —
> verify against the current install.

## What it is

BabelBrain (Pichardo lab) takes a subject's MRI (optionally CT/PETRA), a SimNIBS head model, and
a transducer trajectory, and computes the transcranial pressure field, focal position, and
thermal rise. Acoustic/thermal FDTD solves run on GPU (CUDA preferred over OpenCL).

## Where it lives / how it's installed

- **Repo:** `/data/u_kroner_software/git/BabelBrain` (public repo, HTTPS clone).
- **Conda env: `BabelBrainLinux`** — note the name (a common error is calling it `BabelBrain`).
  conda-forge only (Anaconda block). Shell init uses `mamba shell init --shell bash` (not the
  old `mamba init bash`).
- **Two env YAMLs ship** — pick by GPU node: `environment_linux.yml` (standard; **use this** —
  works on the CUDA 12.5 nodes `comps09h*`/`comps11h*`/`drachenkopf`) vs.
  `environment_linux_cuda_13_driver_580.yml` (only for CUDA 13 / driver ≥ 580 nodes, i.e. the
  newest GPU servers).
- **SimNIBS 4.x** is needed for `charm`. Either `sc simnibs latest` (container, read-only,
  charm-only) or a writable **`simnibs_env`** conda env via the SimNIBS installer (recommended —
  it's the shared env PlanTUS also uses; reuse it, don't duplicate).
- **3D Slicer and `wb_command`** are installed institute-wide (`deb`) — don't install them;
  `which Slicer` / `which wb_command`.
- Optional **FAT skull atlas** (EnhanceTUS repo, Git-LFS) improves the skull mask; watch the
  `cp -r` nesting gotcha and the `simnibs_repo/simnibs/...` atlas path.

## The three MPI-CBS constraints that cause all the friction

1. **Anaconda block** → conda-forge-only envs (see global CLAUDE.md).
2. **No 3D OpenGL on remote desktops.** The single biggest constraint. 2D GUIs work over
   NoMachine; **3D viewers crash** (`Cannot create GLX context`, `failed to load driver: swrast`,
   `GLEW could not be initialized`, or a bare segfault). Workaround baked into the pipeline: the
   compute **finishes and writes output to disk before any viewer opens**, so results are
   inspected afterward (ideally on a local machine with a real GPU).
3. **Blackwell/newest-GPU incompatibility** with the `cupy` build in `BabelBrainLinux`: on
   mixed-GPU nodes, `export CUDA_VISIBLE_DEVICES=1` forces the usable card (e.g. the A100).

## Where to run

Cluster GPUs do the solves (A100 40 GB / A40 46–48 GB ample for 256-element grids; RTX 6000
24 GB and A4000 16 GB also fine). Local/workstation GPUs load the GUI but are too small for full
solves. Division of labour: `charm`/`recon-all` + acoustic/thermal compute on the cluster;
3D viewing on a local machine.

## Relationship to PRESTUS

- **Shares** the SimNIBS/`charm` preprocessing, `wb_command`, and the GPU/Slurm patterns — but
  uses a **separate conda env** (`BabelBrainLinux` + `simnibs_env`), distinct from PRESTUS's
  `PRESTUS_env_4.6.0`. There are therefore multiple SimNIBS installs on this account; don't
  conflate them.
- Useful precedent for how the no-3D-OpenGL and CUDA-generation constraints were handled — the
  same ones PRESTUS's GUI and `cpp_gpu` backend run into.
