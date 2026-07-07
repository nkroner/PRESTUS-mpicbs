# PlanTUS — existing setup (reference for Claude Code)

> Orientation on the **PlanTUS** trajectory-planning setup in this MPI-CBS environment, for
> context when it overlaps with PRESTUS (shared SimNIBS/`charm`, `wb_command`, per-subject
> preprocessing). Institute infrastructure is in `~/.claude/CLAUDE.md` — not repeated here.
>
> **Source & authority:** reconstructed from prior setup conversations. The authoritative
> write-up is the existing **Notion "PlanTUS pipeline" page**; treat the upstream repos as the
> source of truth for anything not MPI-CBS-specific.

## What it is

PlanTUS plans TUS transducer trajectories (scalp entry + orientation to reach a target ROI),
working from a SimNIBS head model and cortical/ROI surfaces. It renders results via Connectome
Workbench.

## Two variants — don't confuse them

- **Standalone `mlueckel/PlanTUS`** — the original, run on its own. This is what the Notion
  PlanTUS page documents.
- **BabelBrain-integrated fork `spichardo/PlanTUS`** (`/data/u_kroner_software/git/PlanTUS`) —
  adds wrapper code so BabelBrain can drive PlanTUS from its GUI. Clone this one *only* for the
  in-GUI integration.

## How it's wired (the subtle part)

- PlanTUS runs **inside SimNIBS's own Python interpreter** (`simnibs_env`), dispatched via
  `PlanTUS_wrapper.py` — **not** in a PlanTUS-specific or BabelBrain env.
- Therefore its Python deps go **into `simnibs_env`**: `pip install nilearn pynput PyQt5`
  (`vtk` already ships in SimNIBS 4). Installing them into `BabelBrainLinux` instead is the
  classic bug — it yields `ModuleNotFoundError: nilearn` and a downstream missing
  `distances_skin.func.gii`.
- Needs **`wb_command`** (institute `deb` package `connectome-workbench`, typically
  `/usr/bin/wb_command`) — don't download it, point PlanTUS at the installed path.
- The integration panel usually asks only for **SimNIBS root**, **PlanTUS folder**, and
  **`wb_command`** — recent releases piggyback on SimNIBS for the FSL/FreeSurfer bits (and our
  containerised `FSL`/`FREESURFER` hide their binaries anyway).

## Per-subject preprocessing (shared with BabelBrain)

`charm` (head model) + FreeSurfer `recon-all` + target-ROI extraction, run on Slurm. Known
gotchas: the T2 for `charm` must be a **true T2** (a Siemens `*_dark-fluid_*`/FLAIR suppresses
CSF and is wrong — run T1-only if that's all there is); add `--forceqform` on qform/sform
mismatch; **no spaces** in filenames/IDs; and a `$FSLDIR` expansion issue when calling FSL
outside the FSL wrapper shell.

## Relationship to PRESTUS

- PRESTUS **bundles its own PlanTUS** as a submodule (pinned `v0.1.1`, under
  `external/PlanTUS`) and drives it through its own `PRESTUS_env_4.6.0` — this is **separate**
  from the standalone `mlueckel`/`spichardo` PlanTUS + `simnibs_env` described here. Same tool
  lineage, different install; don't cross-wire them.
- The `simnibs_env` deps pattern (`nilearn`, `pynput`, `vtk`, `wb_command`) is the same set
  PRESTUS's PlanTUS placement mode needs — useful precedent, already solved once here.
