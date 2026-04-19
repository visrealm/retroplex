# src/

CVBasic sources compiled for the host CPU (TMS9900 on the TI-99/4A, Z80 or 6502 on other CVBasic targets).

## Processing

Every `.bas` file directly under `src/` is picked up by the build via a `CONFIGURE_DEPENDS` glob. They are compiled together by CVBasic into platform-specific assembly, then assembled and linked into a cartridge/ROM for each enabled target in [`project-config.cmake`](../project-config.cmake).

The main source is set by `MAIN_SOURCE` in `project-config.cmake` (currently `retroplex.bas`). The other `.bas` files in this directory are included from the main source.

## Subdirectories

- [`gpu/`](gpu/) - TMS9900 assembly that runs on the F18A/PICO9918 GPU (separate pipeline).
- [`pletter/`](pletter/) - uncompressed asset sources that are Pletter-compressed at build time.
- [`lib/`](lib/) - CVBasic runtime prologues/epilogues for each target CPU.
- `gen/` - generated outputs from the GPU and pletter pipelines (created by the build, gitignored).
