# PRESTUS_config — MPI-CBS config template

**Template only.** Per PRESTUS convention the live config lives *outside* the toolbox so a
`git pull` can't clobber it. Copy this directory to your own location (e.g.
`/data/YOUR_SOFTWARE_BLOCK/git/PRESTUS_config`) and edit the placeholders there.

- `config_prestus_mpicbs.yaml` — **overrides only**, deep-merged onto the toolbox's
  `config/config_default.yaml` (the merge base — do not edit the default). Load with
  `load_parameters('config_prestus_mpicbs.yaml', '/data/YOUR_SOFTWARE_BLOCK/git/PRESTUS_config')`.
- `UPDATING.md` — how to update the toolbox while keeping the MPI-CBS patches on top.
- `BUILDING_CPP_GPU.md` — compile the cpp_gpu binary against the cluster's CUDA 12.5 + gcc-12.

Replace every `/data/YOUR_*` placeholder and any resolved paths (SimNIBS bin, LD_LIBRARY_PATH,
PlanTUS paths) with your own — see `../SETUP_MPICBS.md`.
