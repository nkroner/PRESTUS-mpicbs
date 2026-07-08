% ============================================================================
% PRESTUS UNCERTAINTY analysis (MPI-CBS) — default / liberal / conservative
% skull-property variants + a unified report. Copy, edit the EDIT blocks, run
% via uncertainty.sbatch (matlab platform) or switch to slurm (see bottom).
% Refs: doc/doc_uncertainty.md, RUNNING.md, memory prestus-uncertainty-pipeline.
%
% THREE GOTCHAS baked in below (each cost real debugging time — keep them):
%   (1) target_isppa_wcm2 = []  — otherwise a free-water baseline sim runs in
%       uncertainty STAGE 1, which is GPU-stripped to matlab_cpu → the baseline
%       runs ON CPU (~80 min at 1.0 mm, ×3 variants → hours / timeouts). Cleared.
%   (2) code_type = 'cpp_gpu'   — fast; matlab_gpu is ~4× slower + contention-prone.
%   (3) placement: heuristic works INLINE on the matlab platform (used here). On
%       the slurm platform heuristic HALTS (2-stage) → use manual placement there
%       (see the slurm block at the bottom).
% ============================================================================
root='/data/u_kroner_software/git/PRESTUS'; cfgdir='/data/u_kroner_software/git/PRESTUS_config';
addpath(genpath(fullfile(root,'functions'))); addpath(genpath(fullfile(root,'config'))); addpath(genpath(fullfile(root,'external')));
parameters = load_parameters('config_prestus_mpicbs.yaml', cfgdir);

% ── EDIT: subject + target ───────────────────────────────────────────────────
parameters.subject_id = 2;                                    % m2m_sub-<NN> must exist
parameters.placement.mode = 'heuristic';
parameters.placement.heuristic.mni_target_mm = [-12 -18 8];   % MNI [x y z] mm
parameters.placement.heuristic.target_name   = 'lThal';

% ── activate uncertainty + backend ───────────────────────────────────────────
parameters.simulation.uncertainty       = true;     % <- 3-variant uncertainty mode
parameters.simulation.medium            = 'layered';
parameters.simulation.code_type         = 'cpp_gpu';   % gotcha (2)
parameters.simulation.interactive       = 0;
parameters.transducer.target_isppa_wcm2 = [];          % gotcha (1) — skip CPU free-water baseline
parameters.io.overwrite_files           = 'always';
parameters.grid.resolution_mm           = 1.0;         % 1.0 = fast test; 0.5 = production (see sbatch)

parameters.modules.run_acoustic_sims      = 1;
parameters.modules.run_heating_sims       = 1;         % thermal per variant (skull heating differs)
parameters.modules.run_posthoc_water_sims = 0;

% ── sonication timing (required for thermal) ─────────────────────────────────
parameters.timing.pd=0.02; parameters.timing.pri=0.04;
parameters.timing.ptd=20; parameters.timing.ptri=20; parameters.timing.ptrd=20;   % single pulse train
parameters.timing.post_ptri_dur=20; parameters.timing.pt_timestep=0.02; parameters.timing.post_pt_timestep=1;
parameters.timing.equal_step_duration=0;

% ── DISPATCH: matlab platform (one GPU job, 5 stages sequential) ─────────────
parameters.platform = 'matlab';
prestus_pipeline(parameters);

% ── SLURM alternative (5 parallel dependency-linked jobs) ────────────────────
% Replace the two lines above with the block below and run this .m FROM a
% submission-capable node (a plain MATLAB session — it submits + returns; no GPU
% sbatch needed). heuristic HALTS on slurm, so switch to MANUAL placement:
%   parameters.placement.mode       = 'manual';
%   parameters.transducer.trans_pos = [ .. .. .. ];   % scalp position [T1 voxels]
%   parameters.transducer.focus_pos = [ .. .. .. ];   % target [T1 voxels]
%     (get these from a validated heuristic run's resolved trans_pos/focus_pos —
%      NOT a raw tpars search-candidate row)
%   parameters.platform      = 'slurm';
%   parameters.hpc.partition = 'short,group_servers';               % sim stages (GPU); short caps 3h
%   options = struct('sim_timelimit','01:00:00','stage1_timelimit','00:40:00', ...
%                    'report_timelimit','00:20:00','stage1_partition','short,group_servers', ...
%                    'report_partition','short,group_servers');
%   prestus_pipeline_start(parameters, options);   % → 5-job afterok graph via ssh-submit
