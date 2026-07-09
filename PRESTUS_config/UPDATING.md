# Updating the PRESTUS installation to a new release

Our PRESTUS toolbox lives at `/data/YOUR_SOFTWARE_BLOCK/git/PRESTUS`. Local `main` tracks the
public GitHub (`origin` = <https://github.com/Donders-Institute/PRESTUS.git>). Our MPI-CBS
adaptations + bug fixes live as commits on the branch **`feature/mpicbs-hpc-adapt`** (never
pushed — local only). Installed at v0.6.1 (2026-07).

## What updates, and what does NOT

- **Updated by git:** the toolbox code + `doc/`, and the **submodules** (k-Wave, export_fig,
  FEX-minimize, xml2struct, PlanTUS) if a release bumps their pins.
- **NOT touched (deliberately kept outside the repo):**
  - This project config dir `/data/YOUR_SOFTWARE_BLOCK/git/PRESTUS_config/` (`config_prestus_mpicbs.yaml`, this file).
  - The conda env `PRESTUS_env_4.6.0`.
  - Data/outputs on `/data/YOUR_STUDY_BLOCK/PRESTUS` and study blocks.

## Recipe

```bash
cd /data/YOUR_SOFTWARE_BLOCK/git/PRESTUS

# 1. Fetch upstream + fast-forward local main to the new release
git fetch origin
git checkout main
git merge --ff-only origin/main

# 2. Replay OUR patches on top of the new release (clean, linear history)
git checkout feature/mpicbs-hpc-adapt
git rebase main
#   (not comfortable with rebase? `git merge main` does the same with a merge commit)

# 3. Update submodules if the release moved their pins
git submodule update --init --recursive

# 4. Check the version, then RE-RUN A SMOKE TEST before trusting the update
cat VERSION
```

## Expect during the rebase

1. **Possible conflicts** — only in the 5 files we patched, and only if the release changed
   the same lines. Our edits are small/additive, so conflicts should be minor; git pauses and
   shows exactly what to reconcile. Our patched files:
   `functions/hpc/hpc_submit_job.m`, `functions/hpc/hpc_detect_system.m`,
   `functions/head/segmentation_run.m`, `functions/head/skull_rubber_wrap.m`,
   `functions/helper/log_timer.m`.
2. **Some patches may become redundant** — if upstream fixes the same bugs (`skull_rubber_wrap`,
   `log_timer`, or the RAS-orientation bug), git flags the overlap or drops the now-empty
   commit. That's good — keep whichever of our commits are still needed.

## Our commits (what they are, so you know what's still relevant)

- **HPC dispatch adaptation** (`hpc.name='mpicbs'`: MATLAB wrapper instead of `module load`,
  `--gpus`, ssh-submit via `getserver -b`, `source /etc/profile`) — MPI-CBS-specific, will
  stay ours (not upstreamable as-is).
- **`skull_rubber_wrap`** — removed a dead/crashing `niftiinfo` call. Upstreamable bug fix.
- **`log_timer`** — guard against a re-entrant-timer crash. Upstreamable bug fix.
- The **RAS-orientation bug** (transducer misregistered for non-RAS input) is NOT patched in
  our code — we work around it by feeding RAS data. Worth reporting upstream; if a release
  fixes it, no rebase impact.

## After updating

- **Always re-run one smoke test** (e.g. acoustic `sub-002`) — a release can change config
  keys, module behaviour, or a submodule needing small config tweaks.
- If the release requires a newer **SimNIBS**, rebuild/extend the conda env accordingly
  (see the install script in `/data/YOUR_SOFTWARE_BLOCK/git/PRESTUS_setup/`).
- **If you use the `cpp_gpu` backend:** a k-Wave submodule version bump means the compiled
  `kspaceFirstOrder-CUDA` binary should be **rebuilt** to match (version skew can break the
  HDF5 input interface → errors or wrong output). Re-run the recipe in `BUILDING_CPP_GPU.md`
  and redeploy to `external/k-wave/k-Wave/binaries/`. `matlab_gpu` is unaffected by updates.
