# RetroPLEX

A Supaplex clone for TMS9918A powered computers with a [PICO9918](https://github.com/visrealm/pico9918) enhanced VDP replacement, written in [CVBasic](https://github.com/visrealm/CVBasic) with a TMS9900 assembly GPU engine.

## Build Status

| Platform | Windows | Linux | macOS |
|----------|---------|-------|-------|
| ROMs | [![](https://github.com/visrealm/retroplex/actions/workflows/build-windows.yml/badge.svg)](https://github.com/visrealm/retroplex/actions/workflows/build-windows.yml) | [![](https://github.com/visrealm/retroplex/actions/workflows/build-linux.yml/badge.svg)](https://github.com/visrealm/retroplex/actions/workflows/build-linux.yml) | [![](https://github.com/visrealm/retroplex/actions/workflows/build-macos.yml/badge.svg)](https://github.com/visrealm/retroplex/actions/workflows/build-macos.yml) |

## Supported devices

Any of the following, fitted with a **PICO9918** (or compatible enhanced VDP with sufficient VRAM) in place of the stock TMS9918A:

* TI-99/4A
* ColecoVision
* MSX
* NABU
* SC-3000/SG-1000

Can be compiled for other targets supported by CVBasic too.

The original F18A is not currently supported - it does not have enough VRAM to hold all of RetroPLEX's assets and GPU code. Making it fit is on the roadmap.

### Video

[![RetroPLEX gameplay](https://img.visualrealmsoftware.com/youtube/thumb/A4wrG8Qgm84)](https://youtu.be/A4wrG8Qgm84)

### Play online

You can play the latest build for the TI-99/4A (with PICO9918) online courtesy of JS99'er: [RetroPLEX on JS99'er](https://js99er.visrealm.au/#/?cart=software/retroplex-8.bin)

## How it works

RetroPLEX loads the original Supaplex `LEVELS.DAT` and runs the game engine on the enhanced VDP's GPU. The host CPU (TMS9900, Z80, or 6502, depending on target) is used primarily for orchestration, audio, and I/O. Rendering, scrolling, and enemy logic run as TMS9900 assembly executing in VRAM on the GPU itself - that code is portable across hosts because it runs on the VDP.

## Hardware Requirements

- A supported host (see [Supported devices](#supported-devices)) fitted with a **PICO9918** in place of the stock TMS9918A
- TI-99/4A additionally needs a 32K memory expansion
- A way to run the built cartridge/ROM on the host (cartridge loader, disk, emulator with PICO9918 support, etc.)

## Status

Work in progress. Expect missing features, rough edges, and ongoing changes.

## Building

### Prerequisites

* CMake 3.13 or later
* Python 3 with Pillow (for graphics conversion - see `tools/requirements.txt`)
* Git
* C compiler (GCC, Clang, MSVC, etc.)

The build system automatically downloads and builds all required tools from source:

* [CVBasic](https://github.com/visrealm/CVBasic) - Cross-compiler
* [gasm80](https://github.com/visrealm/gasm80) - Z80/6502 assembler
* [XDT99](https://github.com/endlos99/xdt99) - TI-99/4A cross-assembler
* [Pletter](https://github.com/nanochess/Pletter) - Graphics compression

### Quick Start

```bash
# Clone the repository
git clone https://github.com/visrealm/retroplex.git
cd retroplex

# Create build directory
mkdir build
cd build

# Configure
cmake ..

# Build all platforms
cmake --build . --target all_platforms
```

ROMs will be generated in `build/roms/`, with intermediate assembly under `build/asm/`.

### Individual Platform Targets

Build specific platforms:

```bash
cmake --build . --target ti99              # TI-99/4A
cmake --build . --target coleco            # ColecoVision
cmake --build . --target msx_asc16         # MSX (ASCII 16K)
cmake --build . --target msx_konami        # MSX (Konami)
cmake --build . --target nabu              # NABU
cmake --build . --target sg1000            # SG-1000/SC-3000
cmake --build . --target creativision      # CreatiVision
```

Enabled targets are listed in [`project-config.cmake`](project-config.cmake).

### Build Options

```bash
# Use existing tools instead of building from source
cmake .. -DBUILD_TOOLS_FROM_SOURCE=OFF
```

### Continuous integration

GitHub Actions workflows under [`.github/workflows/`](.github/workflows/) build on Windows, Linux, and macOS for every push, pull request, and manual dispatch. Each run uploads the produced ROMs as an artifact named `retroplex_<version>_<os>`.

## Build Pipeline & Tooling

The build is glob-driven - drop a file into the right directory and it is picked up automatically on the next CMake run (via `CONFIGURE_DEPENDS` globs). There are three automatic pipelines:

### 1. GPU assembly - `src/gpu/**/*.a99`

Any `.a99` file anywhere under `src/gpu/` is run through the full GPU pipeline:

```
 .a99  --[xas99]-->  .bin  --[bin2cvb]-->  .bin.bas  --[pletter]-->  .bin.pletter.bas
```

- **xas99** (from [XDT99](https://github.com/endlos99/xdt99)) assembles TMS9900 source to a raw binary.
- **`tools/bin2cvb.py`** wraps the binary as CVBasic `DATA BYTE` rows so it can be embedded in the cart.
- **`tools/cvpletter.py`** runs the payload through Pletter compression and emits a `.pletter.bas` that unpacks at runtime.

Outputs land in `src/gen/gpu/` (gitignored). They're regenerated whenever the source `.a99` changes. This is how the game engine (gameloop, scrolling, moving objects, renderers) gets shipped into the cartridge and uploaded to VRAM for the F18A/PICO9918 GPU to execute.

### 2. Pletter-compressed assets - `src/pletter/*.bas`

Any `.bas` file in `src/pletter/` is treated as uncompressed `DATA BYTE` payload and run through Pletter:

```
 file.bas  --[pletter]-->  file.pletter.bas
```

Outputs land in `src/gen/pletter/` (gitignored). This is where tile sheets, sprites, palettes, the status panel, font bitmaps, and the level pack are compressed before being linked into the ROM.

### 3. Platform ROMs - `src/*.bas`

The root-level `.bas` files (CVBasic source for the host CPU) are compiled by CVBasic into platform-specific assembly, then assembled and linked into cartridges for each enabled target. The TI-99 pipeline additionally runs `linkticart.py` to produce a properly headered cartridge, auto-detecting banked vs non-banked builds.

### External toolchains (auto-fetched)

CMake fetches and builds the required toolchains on first configure. You don't need to install anything by hand:

- **[CVBasic](https://github.com/visrealm/CVBasic)** - Oscar Toledo G.'s BASIC-like cross-compiler; the host CPU language.
- **[gasm80](https://github.com/visrealm/gasm80)** - Z80/6502/TMS9900 assembler used by CVBasic's output.
- **[XDT99](https://github.com/endlos99/xdt99)** - TI-99 developer toolkit (provides `xas99` and `linkticart`).
- **[Pletter](https://github.com/nanochess/Pletter)** - LZ-family compressor with a small unpacker suitable for 8-bit machines.

### Helper scripts under `tools/`

- `cvpletter.py` - wraps Pletter to operate on CVBasic `DATA BYTE` sections.
- `bin2cvb.py` - converts a raw binary into a CVBasic `DATA BYTE` block.
- `bmpfont2cvb.py` - converts a bitmap font PNG into CVBasic data.
- `levels_dat_to_bas.py` - converts a Supaplex `LEVELS.DAT` into a `.bas` that the pletter pipeline can compress.
- `a99lint.py` / `cvblint.py` - lightweight linters for TMS9900 assembly and CVBasic sources.

### Adding new content

- **New GPU code:** create a `.a99` file anywhere under `src/gpu/` - no CMake edits required.
- **New compressed asset:** drop a `.bas` file into `src/pletter/` - no CMake edits required.
- **New platform target:** add it to `ENABLED_TARGETS` in `project-config.cmake`.

## Repository Layout

- `src/*.bas` - CVBasic sources compiled for the host CPU (TMS9900 / Z80 / 6502 depending on target): boot, loader, audio, input, level unpacking
- `src/gpu/*.a99` - TMS9900 assembly that runs on the F18A/PICO9918 GPU
- `src/gpu/game/` - gameplay engine: game loop, scrolling, movement, rendering
- `src/gpu/game/moving/` - per-object behaviour (Murphy, zonks, infotrons, sniksnaks, electrons, orange disks, explosions, bugs)
- `src/gpu/game/render/` - sprite, tile, and text rendering
- `src/pletter/` - compressed asset sources (tiles, sprites, palette, panel, levels, fonts)
- `src/lib/` - CVBasic runtime prologues/epilogues
- `res/` - game assets: `LEVELS.DAT`, Magellan tile/sprite sheets, palettes, panel graphics
- `tools/` - helper scripts: `cvpletter.py`, `bin2cvb.py`, bitmap/font converters, linters
- `docs/` - design spreadsheets (VRAM map, tile map, object state encoding)
- `.vscode/extensions/` - syntax highlighting for CVBasic and TMS9900 assembly
- `CMakeLists.txt` + `visrealm_cvbasic.cmake` - build system
- `project-config.cmake` - enabled targets and project metadata

## Credits

- Original Supaplex - Dream Factory / Digital Integration (1991)

## License

This code is licensed under the [MIT](https://opensource.org/licenses/MIT "MIT") license.

Supaplex and its assets remain the property of their respective owners. This repository contains no original Supaplex code or artwork; `LEVELS.DAT` is the standard community level pack bundled for compatibility testing.
