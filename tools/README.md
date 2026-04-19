# Tools

Utility scripts used by the RetroPLEX build pipeline and asset authoring workflow:

- `cvpletter.py` - compress CVBasic `DATA BYTE` sections with Pletter and emit `.pletter.bas` files.
- `bin2cvb.py` - convert binary blobs to CVBasic `DATA BYTE` declarations.
- `bmpfont2cvb.py` - convert a bitmap font PNG into a CVBasic `DATA BYTE` block.
- `levels_dat_to_bas.py` - convert a Supaplex `LEVELS.DAT` file into a CVBasic source that the pletter pipeline can compress.
- `a99lint.py` - lightweight linter for TMS9900 (`.a99`) assembly.
- `cvblint.py` - lightweight linter for CVBasic (`.bas`) sources.

Licensed under MIT (see headers).
