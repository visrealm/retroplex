# src/gpu/

TMS9900 assembly that runs on the F18A/PICO9918 GPU (not on the host CPU). These files implement the game engine: gameloop, scrolling, moving-object behaviour, sprite/tile/text rendering, palette fades, VDP detection, and DMA helpers.

## Processing

Every `.a99` file anywhere under `src/gpu/` (including subdirectories) is picked up by the build via a recursive `CONFIGURE_DEPENDS` glob and run through this pipeline:

```
 .a99  --[xas99]-->  .bin  --[bin2cvb]-->  .bin.bas  --[pletter]-->  .bin.pletter.bas
```

1. **xas99** (XDT99) assembles the TMS9900 source to a raw binary.
2. **`tools/bin2cvb.py`** wraps the binary as CVBasic `DATA BYTE` rows.
3. **`tools/cvpletter.py`** Pletter-compresses the payload.

The `.bin.pletter.bas` outputs are written to `src/gen/gpu/` (gitignored) and included from the CVBasic host source. At runtime the host decompresses each blob into VRAM for the GPU to execute.

## Subdirectories

- `game/` - the game engine itself (gameloop, scrolling, movement, rendering). Individual files in here are not separately documented.
- Top-level `.a99` files handle GPU setup: VDP detection, palette fades, DMA, and the main GPU entry point.
