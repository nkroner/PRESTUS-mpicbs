# Building the k-Wave `cpp_gpu` binary on MPI-CBS (self-serve, no IT)

**Outcome:** the compiled `kspaceFirstOrder-CUDA` runs ~**4× faster** than `matlab_gpu`
(sub-002, RTX 6000: freefield 634→155 s, acoustic 650→167 s) with **numerically identical**
results (all metrics Δ 0.00%, finite, no NaN). `matlab_gpu` remains the robust fallback.

The stock precompiled binaries (Donders `PRESTUS_bin`, k-wave.org) are built for **CUDA 11**
(`libcufft.so.10`) and don't run on our **CUDA 12.5** nodes. Fix = recompile against the
cluster's own CUDA 12.5. **`nvcc` 12.5 and `gcc-12` are on the GPU nodes**, so no IT ticket.

## Prerequisites (already in place)
- `nvcc` 12.5 at `/usr/local/cuda-12.5` (GPU compute nodes only — `comps09*`/`comps11*`).
- `gcc-12` (`/usr/bin/gcc-12`) — must be **GCC ≤ 12** (GCC ≥ 13.2 risks the silent-NaN bug).
- Build-deps conda env **`kwave_build`** (`mamba create -n kwave_build -c conda-forge hdf5 zlib zstd`)
  — provides HDF5 headers + `libhdf5.so.320`, which the binary finds at runtime via **rpath**.

## Recipe (all under `/data/u_kroner_software/git/PRESTUS_setup/kwave-build/`)
1. **Source:** `curl -L "http://www.k-wave.org/getfile.php?id=207" -o src.zip` (k-Wave 1.3 CUDA
   source; 1.3-binary + 1.4-toolbox is PRESTUS's intended combo). `unzip` → `source/kspaceFirstOrder-CUDA/`.
2. **Fix the Makefile** (this download ships recipes indented with **spaces, not tabs**):
   `sed -i -E 's/^ +(\$\(CXX\)|rm -f)/\t\1/' Makefile`
3. **Compile on a GPU node** (`build_kwave.sh` + `build_kwave.sbatch` here). Key points baked in:
   - `NVCC_APPEND_FLAGS="-include cstdint -include string -include limits ..."` — the 2019 source
     assumed transitive std includes that gcc-12's stricter libstdc++ no longer provides.
   - `CUDA_ARCH="--generate-code arch=compute_75,code=sm_75 --generate-code arch=compute_86,code=sm_86"`
     — our GPUs (Turing RTX 6000 + Ampere A4000/A40). The default arch list includes Kepler
     (`sm_30/35/37`) which **CUDA 12.5 removed** → must override.
   - `LINKING=DYNAMIC CUDA_DIR=/usr/local/cuda-12.5 HDF5_DIR=$kwave_build ZLIB_DIR=$kwave_build CPU_ARCH=AVX2`
   - Submit: `ssh "$(getserver -b)" 'sbatch .../build_kwave.sbatch'` (wrap the build in `CUDA bash ...`).
4. **Deploy:** copy the binary to **`external/k-wave/k-Wave/binaries/`** (this is
   `getkWavePath('binaries')` — NOT `external/k-wave/binaries/`). Also drop in `kspaceFirstOrder-OMP`
   there for `cpp_cpu`.

## Why it works at runtime
- k-Wave launches the binary with `system('export LD_LIBRARY_PATH=; cd <binaries>; ./kspaceFirstOrder-CUDA ...')`
  — it **clears `LD_LIBRARY_PATH`**, so MATLAB's older `libstdc++`/CUDA libs can't shadow ours.
- The binary's baked-in **rpath** (`kwave_build/lib` + `/usr/local/cuda-12.5/lib64`) resolves
  `libhdf5.so.320` + `libcufft.so.11` + `libcudart.so.12`. So it's self-contained; no env setup
  needed when PRESTUS runs it. **Requirement: the `kwave_build` conda env must persist.**

## Using it
Set `parameters.simulation.code_type = 'cpp_gpu'`. Everything else identical to `matlab_gpu`.
**Always NaN-check outputs** the first time on any new GPU/driver/CUDA combo (compiled-CUDA
silent-NaN is the known failure mode; it did NOT occur here on Turing/CUDA 12.5).

## On a PRESTUS/k-Wave update
If the k-Wave submodule version changes, **rebuild** (binary version should track the toolbox).
Re-run this recipe; the source/Makefile fixes are captured in `build_kwave.sh`.
