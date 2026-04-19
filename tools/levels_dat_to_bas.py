#!/usr/bin/env python3
"""Convert Supaplex LEVELS.DAT into a trimmed CVBasic DATA stream.

Copyright (c) 2026 Troy Schrapel
License: MIT
GitHub: https://github.com/visrealm/retroplex

Keeps only the fields RetroPLEX needs: tile data (without the outer border),
gravity flag, freeze-zonks flag, and infotrons-needed count. Level titles are
now emitted separately (label `levelTitles`) so the selector can be loaded once
from BANK0 without decompressing every level. Everything else in the 1,536
byte level record is skipped. Emits one label per level in the form
`level001:` followed by DATA BYTE lines. By default writes
`src/pletter/levels.dat.bas`.

Format of LEVELS.DAT
+-------+------------------------------------------------------------------------------------------------------------------------------------
| Bytes	| Description
+-------+------------------------------------------------------------------------------------------------------------------------------------
| 1440	| The level itself (width*height=60*24=1440)
| 4	?   | [unused]
| 1	    | Gravitation start value (0=off, 1=on)
| 1	    | 20h + SpeedFix_version_hex: v5.4 => 74h; v6.0 => 80h. In the original Supaplex, this value is just 20h.
| 23	  | Level title
| 1	    | Freeze zonks start value (0=off, 2=on) (yes 2=on, no mistake!)
| 1	    | Number of infotrons needed. 0 means Supaplex will count the total number of infotrons in the level at the start and use that.
| 1	    | Number of gravity switch ports (maximum 10!)
| 10*6	| Coordinates of 10 special ports (entries for unused ports are ignored. 6 bytes per port: [hi][lo][grav][fr.zonks][fr.enemy][unused]
|       | [hi]        (2*(x+y*60)) div 256 (integer division) where (x,y) are the coordinates of the special port (0,0=left top)
|       | [lo]        (2*(x+y*60)) mod 256 (remainder of division) where (x,y) are the coordinates of the special port (0,0=left top)
|       | [grav]      1 (turn on or 0 (turn off gravity)
|       | [fr.zonks]  2 (turn on) or 0 (turn off freeze zonks)
|       | [fr.enemy]  1 (turn on) or 0 (turn off freeze enemies)
|       | [unused]    This value doesn't matter (might be used in future versions of the SpeedFix!)
| 4	    | Used by the SpeedFix to store some vital demo information. Unused in the original SUPAPLEX.EXE.
+-------+------------------------------------------------------------------------------------------------------------------------------------

"""
from __future__ import annotations

import argparse
from pathlib import Path
from typing import Iterable, List

LEVEL_SIZE = 1536
ORIG_TILE_WIDTH = 60
ORIG_TILE_HEIGHT = 24
OMITTED_BORDER = 1  # omit 1 tile from each side
TILE_WIDTH = ORIG_TILE_WIDTH  # 60 (include border in output)
TILE_HEIGHT = ORIG_TILE_HEIGHT  # 24 (include border in output)
ROW_STRIDE = 64  # pad to power-of-2 for fast addressing
TILE_DATA_LENGTH = ROW_STRIDE * TILE_HEIGHT
GRAVITY_OFFSET = 1444
TITLE_OFFSET = 1446
TITLE_LENGTH = 23
FREEZE_ZONKS_OFFSET = 1469
INFOTRONS_NEEDED_OFFSET = 1470
GRAVITY_PORTS_OFFSET = 1471

# Border tile indexes (RetroPLEX uses unified tiles)
BORDER_CORNER = 40
BORDER_HORIZONTAL = 41
BORDER_VERTICAL = 42

# Offsets in the trimmed layout we emit.
OUT_LEVEL_NUM_INDEX = 0
OUT_GRAVITY_INDEX = OUT_LEVEL_NUM_INDEX + 1
OUT_FREEZE_ZONKS_INDEX = OUT_GRAVITY_INDEX + 1
OUT_INFOTRONS_NEEDED_INDEX = OUT_FREEZE_ZONKS_INDEX + 1
OUT_GRAVITY_PORTS_INDEX = OUT_INFOTRONS_NEEDED_INDEX + 1
OUT_TILES_INDEX = OUT_GRAVITY_PORTS_INDEX + 1
TRIMMED_LEVEL_SIZE = OUT_TILES_INDEX + TILE_DATA_LENGTH
BYTES_PER_LINE = ROW_STRIDE

def chunk(seq: Iterable[int], size: int) -> Iterable[List[int]]:
    line: List[int] = []
    for b in seq:
        line.append(b)
        if len(line) == size:
            yield line
            line = []
    if line:
        yield line


def extract_tiles(level_bytes: bytes) -> List[int]:
    """Return 60x24 playfield with border tiles replaced by unified indexes, padded to 64-byte rows."""
    tiles: List[int] = []
    row_stride = ORIG_TILE_WIDTH
    
    for row in range(ORIG_TILE_HEIGHT):
        row_start = row * row_stride
        row_data = list(level_bytes[row_start : row_start + row_stride])
        
        # Replace border tiles with unified indexes
        for col in range(ORIG_TILE_WIDTH):
            tile = row_data[col]
            
            # Check if this is a border position
            is_top = row == 0
            is_bottom = row == ORIG_TILE_HEIGHT - 1
            is_left = col == 0
            is_right = col == ORIG_TILE_WIDTH - 1
            
            if (is_top or is_bottom) and (is_left or is_right):
                # Corner
                row_data[col] = BORDER_CORNER
            elif is_top or is_bottom:
                # Horizontal edge
                row_data[col] = BORDER_HORIZONTAL
            elif is_left or is_right:
                # Vertical edge
                row_data[col] = BORDER_VERTICAL
        
        tiles.extend(row_data)
        # Pad to 64 bytes
        padding = ROW_STRIDE - TILE_WIDTH
        tiles.extend([0] * padding)
    
    return tiles


def convert(dat_path: Path, out_path: Path) -> None:
    data = dat_path.read_bytes()
    if len(data) % LEVEL_SIZE != 0:
        raise ValueError(
            f"File size {len(data)} is not a multiple of level size {LEVEL_SIZE}."
        )

    level_count = len(data) // LEVEL_SIZE
    levels: List[dict[str, object]] = []
    for level_index in range(level_count):
        start = level_index * LEVEL_SIZE
        end = start + LEVEL_SIZE
        level_bytes = data[start:end]
        levels.append(
            {
                "number": level_index + 1,
                "title": level_bytes[TITLE_OFFSET : TITLE_OFFSET + TITLE_LENGTH].decode(
                    "ascii"
                ),
                "gravity": level_bytes[GRAVITY_OFFSET],
                "freeze_zonks": level_bytes[FREEZE_ZONKS_OFFSET],
                "infotrons": level_bytes[INFOTRONS_NEEDED_OFFSET],
                "gravity_ports": level_bytes[GRAVITY_PORTS_OFFSET],
                "tiles": extract_tiles(level_bytes),
            }
        )

    lines: List[str] = []
    lines.append(f"' Generated from {dat_path.name} ({level_count} levels)")
    lines.append(f"' Input level size: {LEVEL_SIZE} bytes; output trimmed to {TRIMMED_LEVEL_SIZE} bytes")
    lines.append("' Output layout (offsets shown within trimmed level):")
    lines.append(f"'   0          Level number (1-111)")
    lines.append(f"'   {OUT_GRAVITY_INDEX}         Gravity (0=off, 1=on)")
    lines.append(f"'   {OUT_FREEZE_ZONKS_INDEX}         Freeze zonks (0=off, 2=on)")
    lines.append(f"'   {OUT_INFOTRONS_NEEDED_INDEX}         Infotrons needed (0 means all)")
    lines.append(f"'   {OUT_GRAVITY_PORTS_INDEX}         Gravity port count (not implemented)")
    lines.append(f"'   {OUT_TILES_INDEX}-{TRIMMED_LEVEL_SIZE - 1}    Tiles (60x24, row-major, 64-byte stride). Border tiles unified.")
    lines.append(f"'   Border tiles: {BORDER_CORNER}=corners, {BORDER_HORIZONTAL}=horiz edges, {BORDER_VERTICAL}=vert edges")
    lines.append(f"' Level titles emitted separately (label levelTitles): count then {TITLE_LENGTH}-char ASCII names (space padded)")
    lines.append("' Dropped: unknown bytes, version byte, demo bytes")
    lines.append(f"' DATA BYTE lines are hex ($xx), {BYTES_PER_LINE} bytes per line")
    lines.append("'")
    lines.append("' Banking pragmas for cvpletter.py")
    lines.append("' #BANKING")
    lines.append("' #BANK 2")
    lines.append("' #BANK0 levelTitles,level001,level002,level003,level004")

    lines.append("\nlevelTitles:")
    lines.append(f"DATA BYTE {level_count} ' level count")
    for level in levels:
        lines.append(f"DATA BYTE \"{level['title']}\"")

    for level in levels:
        label = f"\nlevel{level['number']:03d}:"
        lines.append(label)
        lines.append(f"DATA BYTE {level['number']} ' {level['title'].rstrip()}")
        lines.append(f"DATA BYTE {level['gravity']} ' gravity")
        lines.append(f"DATA BYTE {level['freeze_zonks']} ' freeze zonks")
        lines.append(f"DATA BYTE {level['infotrons']} ' infotrons")
        lines.append(f"DATA BYTE {level['gravity_ports']} ' grav ports")
        for chunk_bytes in chunk(level["tiles"], BYTES_PER_LINE):
            # Use hex for easier visual alignment in CVBasic sources.
            byte_list = ",".join(f"${b:02X}" for b in chunk_bytes)
            lines.append(f"DATA BYTE {byte_list}")

    out_path.write_text("\n".join(lines), encoding="ascii")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "dat",
        nargs="?",
        type=Path,
        default=Path("res/LEVELS.DAT"),
        help="Path to LEVELS.DAT (default: res/LEVELS.DAT)",
    )
    parser.add_argument(
        "-o",
        "--out",
        type=Path,
        default=Path("src/pletter/levelsdat.bas"),
        help="Output .bas file (default: res/levels_from_dat.bas next to input)",
    )
    args = parser.parse_args()

    dat_path = args.dat
    if not dat_path.is_file():
        raise SystemExit(f"Input file not found: {dat_path}")

    out_path = args.out or dat_path.with_name("levels_from_dat.bas")
    out_path.parent.mkdir(parents=True, exist_ok=True)

    convert(dat_path, out_path)
    print(f"Wrote {out_path} from {dat_path}")


if __name__ == "__main__":
    main()
