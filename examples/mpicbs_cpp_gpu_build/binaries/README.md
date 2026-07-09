# Prebuilt cpp_gpu binary — not shipped

The compiled `kspaceFirstOrder-CUDA` is **environment-specific** (its rpath points at the
conda env it was built against) and is deliberately **not committed** to this distribution.

Build your own with the recipe in `../README.md` (or `PRESTUS_config/BUILDING_CPP_GPU.md`),
then deploy it into `external/k-wave/k-Wave/binaries/` (that is `getkWavePath('binaries')`).
