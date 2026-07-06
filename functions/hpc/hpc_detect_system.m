function hpc_type = hpc_detect_system()
% HPC_DETECT_SYSTEM  Detect the available HPC job scheduler
%
% Checks for sbatch (SLURM) and qsub (PBS/Torque) on the system PATH.
% Returns the first scheduler found. Errors if neither is available.
%
% Use as:
%   hpc_type = hpc_detect_system()
%
% Output:
%   hpc_type - 'slurm' if sbatch is on PATH; 'qsub' if qsub is on PATH
%
% Errors:
%   Throws an error if neither sbatch nor qsub is found.
%
% See also: HPC_SUBMIT_JOB, HPC_VALIDATE_PARAMETERS

[sbatch_out, sbatch_path] = system('which sbatch');
[qsub_out, qsub_path] = system('which qsub');

if sbatch_out == 0
    hpc_type = 'slurm';
elseif qsub_out == 0
    hpc_type = 'qsub';
else
    % MPI-CBS: interactive/compute nodes lack the Slurm client locally, but a
    % submission host is reachable via `getserver -b`. Fall back to checking
    % there (only runs when no local scheduler is found, so it's a no-op on
    % clusters like Donders where sbatch is local).
    [ssh_out, ~] = system('ssh -o BatchMode=yes "$(getserver -b)" which sbatch >/dev/null 2>&1');
    if ssh_out == 0
        hpc_type = 'slurm';
    else
        error('No HPC system detected (sbatch/qsub)');
    end
end
end
