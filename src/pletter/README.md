# src/pletter/

Uncompressed CVBasic `DATA BYTE` sources for game assets: tile sheets, sprite sheets, palette, status panel graphics, font bitmaps, and the level pack.

## Processing

Every `.bas` file in this directory is picked up by the build via a `CONFIGURE_DEPENDS` glob and Pletter-compressed:

```
 file.bas  --[pletter]-->  file.pletter.bas
```

**`tools/cvpletter.py`** handles the compression and writes outputs to `src/gen/pletter/` (gitignored). The host CVBasic source includes the `.pletter.bas` outputs and decompresses them at runtime.

## Regenerating inputs

Some files in here are themselves generated from source assets:

- `levelsdat.bas` - generated from `res/LEVELS.DAT` by `tools/levels_dat_to_bas.py`.
- `bmpfont.bas` - generated from a bitmap font PNG by `tools/bmpfont2cvb.py`.

The rest are either authored by hand or produced by external asset tools (e.g. Magellan exports).
