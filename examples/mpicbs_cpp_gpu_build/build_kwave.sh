#!/bin/bash
set -e
SRC=/data/u_kroner_software/git/PRESTUS_setup/kwave-build/source/kspaceFirstOrder-CUDA
BE=/data/u_kroner_software/miniforge/envs/kwave_build
echo "nvcc: $(which nvcc)"; nvcc --version | tail -2; echo "g++: $(g++ --version | head -1)"
# Old k-Wave 1.3 source assumed transitive std includes that gcc-12 libstdc++ no longer provides.
# Force-include the common headers into every nvcc compilation unit.
export NVCC_APPEND_FLAGS="-include cstdint -include cstddef -include string -include limits -include memory -include algorithm -include vector -include map"
cd "$SRC"
make clean >/dev/null 2>&1 || true
make -j8 LINKING=DYNAMIC \
  CUDA_DIR=/usr/local/cuda-12.5 \
  HDF5_DIR="$BE" ZLIB_DIR="$BE" \
  CPU_ARCH=AVX2 \
  CUDA_ARCH="--generate-code arch=compute_75,code=sm_75 --generate-code arch=compute_86,code=sm_86"
echo "== make exit: $? =="
file kspaceFirstOrder-CUDA 2>/dev/null && echo "--- ldd ---" && ldd kspaceFirstOrder-CUDA | grep -iE 'cufft|hdf5|cudart|not found'
