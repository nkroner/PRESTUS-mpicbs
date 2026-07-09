# Running PRESTUS on MPI-CBS — quickstart

The MPI-CBS-specific *glue* for running a subject end-to-end. For the science (parameters,
transducer, placement, interpreting outputs) see the PRESTUS docs in `doc/` and
<https://donders-institute.github.io/PRESTUS/>. Environment/decisions: the project `CLAUDE.md`.

**Templates here** (copy → edit → submit; don't run in place):
`01_segmentation.sbatch` · `run_pipeline.m` + `02_pipeline.sbatch`.

## Prerequisites (already set up)
- Conda env `PRESTUS_env_4.6.0`, MATLAB R2023b (`MATLAB --version 9.15 matlab`).
- Config: `config_prestus_mpicbs.yaml` in `/data/YOUR_SOFTWARE_BLOCK/git/PRESTUS_config/`.
- Data root: `/data/YOUR_STUDY_BLOCK/PRESTUS/{data,segmentation,simulations}`.
- For `cpp_gpu`: the compiled binary must be deployed — see `../mpicbs_cpp_gpu_build/README.md`.

## Two things that will bite you if forgotten
1. **Inputs must be RAS.** Non-RAS silently misplaces the transducer (PRESTUS bug). Check first:
   `python -c "import nibabel as nib; print(''.join(nib.aff2axcodes(nib.load('sub-XX_T1w.nii.gz').affine)))"` → want `RAS`.
   (Real Siemens/`dcm2niix` scans are RAS; only odd/legacy data isn't. See CLAUDE.md for the fix.)
2. **`sbatch` doesn't exist on interactive nodes** (`makrele` etc.). Submit over ssh to a
   submission host: `ssh "$(getserver -b)" 'sbatch /path/to/script.sbatch'`.

## Step 0 — stage the subject
Put `sub-<NN>_T1w.nii.gz` (+ optional `sub-<NN>_T2w.nii.gz`) in `/data/YOUR_STUDY_BLOCK/PRESTUS/data/`,
RAS-checked.

## Step 1 — segmentation (charm, CPU, ~1.5 h)
Copy `01_segmentation.sbatch`, set `SUBJ`/`T1`/`T2`, submit:
```bash
ssh "$(getserver -b)" 'sbatch /data/YOUR_STUDY_BLOCK/PRESTUS/segmentation/log_hpc/01_segmentation.sbatch'
```
→ produces `segmentation/m2m_sub-<NN>/`. (Do this once per subject; sims reuse it.)

## Step 2 — acoustic (+ optional thermal) on GPU
Copy `run_pipeline.m` + `02_pipeline.sbatch` (e.g. into `simulations/log_hpc/`). In
`run_pipeline.m` edit: `subject_id`, target (`mni_target_mm`/`target_name`), `code_type`
(`matlab_gpu` robust, or `cpp_gpu` ~4× faster), `resolution_mm`, and the stage flags
(set `run_heating_sims=1` for thermal — it also uses the timing block). Point `RUN_M` in the
sbatch at your edited `.m`, then:
```bash
ssh "$(getserver -b)" 'sbatch /data/YOUR_STUDY_BLOCK/PRESTUS/simulations/log_hpc/02_pipeline.sbatch'
```

## Monitor + outputs
```bash
ssh "$(getserver -b)" 'squeue -u $USER'                       # queue
ssh "$(getserver -b)" 'sacct -j <jobid> -X --format=State,Elapsed,NodeList'
# logs: /data/YOUR_STUDY_BLOCK/PRESTUS/simulations/log_hpc/pipeline_<jobid>.out|.err
```
Results in `simulations/sub-<NN>/`: `*_report*.html` (open in a browser), `*.csv` (Isppa/MI/focus
metrics), `nii/` (pressure/intensity volumes). **Always sanity-check the focus is in the brain**
(HTML report) **and outputs are finite** (esp. first `cpp_gpu` run on new hardware).

## Uncertainty analysis (optional advanced pipeline)
Runs 3 skull-property variants (default / liberal / conservative) + a unified report. Use the
`uncertainty.m` + `uncertainty.sbatch` templates here (matlab platform), or the commented slurm
block in `uncertainty.m` (5 parallel dependency-linked jobs). It bakes in the three traps we hit:
clear `transducer.target_isppa_wcm2` (else a free-water baseline runs on **CPU** in stage 1,
~80 min ×3), use `cpp_gpu`, and on the **slurm** path use **manual** placement (heuristic halts
there). Both platforms are validated (~8 min at 1.0 mm). See `doc/doc_uncertainty.md` and memory
`prestus-uncertainty-pipeline`.

## Notes
- Config `resolution_mm` may be a coarse smoke-test value — the template sets it explicitly
  (0.5 mm = production). At 0.5 mm keep `--gres gpu_mem:20000M` (needs a 24 GB+ GPU).
- The template uses `platform='matlab'` (one self-contained job). PRESTUS's *native*
  `prestus_pipeline_start(platform='slurm')` also works here (set `hpc.name='mpicbs'`), but with
  heuristic placement it's a 2-stage submit (submits a placement job, halts, re-run) — the
  template avoids that.
- Transducer is an **uncalibrated CTX-500 placeholder** — calibrate + set your real device
  before quantitative work.
