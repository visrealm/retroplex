# Supaplex Level format

Freeware DOS puzzle game **Supaplex** stores all levels in a single `levels.dat` file. The file is uncompressed; each level occupies exactly **1536 bytes** and levels are stored sequentially. The original `levels.dat` shipped with the game is 170,496 bytes (111 levels).

- Extension: `.dat`
- Released: 1991
- Grid: 60 × 24 tiles (1 byte per tile)

## Level record layout (per-level offsets)
| Offset | Length | Contents | Details |
| --- | --- | --- | --- |
| 0 | 1440 | Tile data | 60 × 24 tiles, one byte per tile |
| 1440 | 4 | Unknown | Unused |
| 1444 | 1 | Gravity | 0 = off, 1 = on |
| 1445 | 1 | Unknown | SpeedFix version uses as version indicator; original is always `0x20` |
| 1446 | 23 | Title | Exactly 23 chars, space-padded, no NUL |
| 1469 | 1 | Freeze zonks | 0 = off, 2 = on |
| 1470 | 1 | Infotrons needed | Minimum infotrons to clear; 0 means all |
| 1471 | 1 | Gravity port count | Maximum 10 |
| 1472 | 60 | Gravity ports | 10 entries × 6 bytes; use only `gravity port count` entries |
| 1532 | 4 | Unknown | SpeedFix stores demo info; unused in original |

## Gravity port entry (6 bytes each)
| Offset | Length | Contents | Details |
| --- | --- | --- | --- |
| 0 | 2 | Coordinates | 16-bit big-endian unsigned; formula `2 * (x + y * 60)` |
| 2 | 1 | Gravity | 0 = off, 1 = on |
| 3 | 1 | Freeze zonks | 0 = off, 2 = on |
| 4 | 1 | Freeze enemies | 0 = off, 1 = on |
| 5 | 1 | Unknown | Unused |

## Tile values
| Hex | Name | Description |
| --- | --- | --- |
| 00 | Empty |  |
| 01 | Base |  |
| 02 | Zonk | Falls down; rolls sideways if stacked on zonks/infotrons/RAM chips when possible |
| 03 | Murphy | Player start |
| 04 | Infotron |  |
| 05 | RAM chip - Chip |  |
| 06 | Wall |  |
| 07 | Exit |  |
| 08 | Floppy - Orange | Falls and explodes if it hits something |
| 09 | Port - Right |  |
| 0A | Port - Down |  |
| 0B | Port - Left |  |
| 0C | Port - Up |  |
| 0D | Gravity port - Right |  |
| 0E | Gravity port - Down |  |
| 0F | Gravity port - Left |  |
| 10 | Gravity port - Up |  |
| 11 | Snik snak | Enemy that follows the left edge of its travel direction |
| 12 | Floppy - Yellow | Explodes when player touches a terminal |
| 13 | Terminal | Trigger for yellow floppies to explode |
| 14 | Floppy - Red | Can be picked up/placed; explodes shortly after placement |
| 15 | Port - Two-way vertical |  |
| 16 | Port - Two-way horizontal |  |
| 17 | Port - 4-way |  |
| 18 | Electron | Enemy follows left edge; spawns infotrons when killed |
| 19 | Bug | Periodically sparks; kills player when sparking |
| 1A | RAM chip - Left |  |
| 1B | RAM chip - Right |  |
| 1C | Hardware (decoration) |  |
| 1D | Hardware (decoration) |  |
| 1E | Hardware (decoration) |  |
| 1F | Hardware (decoration) |  |
| 20 | Hardware (decoration) |  |
| 21 | Hardware (decoration) |  |
| 22 | Hardware (decoration) |  |
| 23 | Hardware (decoration) |  |
| 24 | Hardware (decoration) |  |
| 25 | Hardware (decoration) |  |
| 26 | RAM chip - Top |  |
| 27 | RAM chip - Bottom |  |
