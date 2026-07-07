% ============================================================================
% PRESTUS pipeline driver (MPI-CBS). Copy this, edit the EDIT blocks, then run
% it via the companion 02_pipeline.sbatch on a GPU node. One subject + target;
% acoustic (+ optional thermal) in a single job. See RUNNING.md.
% ============================================================================
root   = '/data/u_kroner_software/git/PRESTUS';
cfgdir = '/data/u_kroner_software/git/PRESTUS_config';
addpath(genpath(fullfile(root,'functions')));
addpath(genpath(fullfile(root,'config')));
addpath(genpath(fullfile(root,'external')));
parameters = load_parameters('config_prestus_mpicbs.yaml', cfgdir);

% ── EDIT: subject + target ──────────────────────────────────────────────────
parameters.subject_id = 2;                                   % m2m_sub-<NN> must already exist
parameters.placement.mode = 'heuristic';
parameters.placement.heuristic.mni_target_mm = [-12 -18 8];  % MNI [x y z] mm
parameters.placement.heuristic.target_name   = 'lThal';      % short label -> filenames

% ── EDIT: backend + grid ────────────────────────────────────────────────────
parameters.simulation.code_type = 'matlab_gpu';  % 'matlab_gpu' (robust) | 'cpp_gpu' (~4x, needs built binary)
parameters.grid.resolution_mm   = 0.5;           % 0.5 = production; 0.75/1.0 = faster/coarser
parameters.simulation.medium    = 'layered';

% ── EDIT: which stages ──────────────────────────────────────────────────────
parameters.modules.run_acoustic_sims      = 1;
parameters.modules.run_heating_sims       = 0;   % 1 = also thermal (fills the timing block below)
parameters.modules.run_posthoc_water_sims = 0;
parameters.io.output_affix = '';                 % e.g. '_cppgpu' to keep parallel runs separate

% ── EDIT (only if run_heating_sims=1): sonication timing protocol ────────────
if parameters.modules.run_heating_sims
    parameters.timing.pd  = 0.02; parameters.timing.pri = 0.04;                 % pulse dur / rep interval [s]
    parameters.timing.ptd = 20;   parameters.timing.ptri = 20; parameters.timing.ptrd = 20;  % train (single: ptri=ptrd=ptd)
    parameters.timing.post_ptri_dur = 20;                                       % cooling to steady state [s]
    parameters.timing.pt_timestep = 0.02; parameters.timing.post_pt_timestep = 1;
    parameters.timing.equal_step_duration = 0;
end
% ────────────────────────────────────────────────────────────────────────────
parameters.platform               = 'matlab';   % run in THIS MATLAB; the sbatch is the Slurm layer
parameters.simulation.interactive = 0;
parameters.io.overwrite_files     = 'always';

prestus_pipeline(parameters);
