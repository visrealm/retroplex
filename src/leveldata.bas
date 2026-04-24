'
' Project: retroplex
'
' RetroPLEX - A Supaplex clone for retro computers
'
' Copyright (c) 2026 Troy Schrapel
'
' This code is licensed under the MIT license
'
' https://github.com/visrealm/retroplex
'

' Platform-specific level data layout.
'
' cvpletter.py emits one data file per bank (b0.bas, b2.bas, ...). Each file
' contains only pletter-compressed level blocks; the BANK <n> directive is
' emitted here, so the same per-bank data files can also be consumed by
' non-banked targets by simply omitting the BANK lines.
'
' Bank 0 always holds: the level catalogue, the levelsdatBanks table, and
' the bank-0-pinned labels (levelTitles + first few levels).

' ---- Bank 0 ----
#if BANK8
  include "gen/pletter/levelsdat.pletter_8k.b0.bas"
#elif BANK_SIZE
  include "gen/pletter/levelsdat.pletter_16k.b0.bas"
#elif NABU
  include "gen/pletter/levelsdat.pletter_32k.b0.bas"
  include "gen/pletter/levelsdat.pletter_32k.b2.bas"
#else
  include "gen/pletter/levelsdat.pletter.bas"
#endif

' ---- Remaining banks ----
#if BANK8
BANK 2
  include "gen/pletter/levelsdat.pletter_8k.b2.bas"
BANK 3
  include "gen/pletter/levelsdat.pletter_8k.b3.bas"
BANK 4
  include "gen/pletter/levelsdat.pletter_8k.b4.bas"
BANK 5
  include "gen/pletter/levelsdat.pletter_8k.b5.bas"
BANK 6
  include "gen/pletter/levelsdat.pletter_8k.b6.bas"
BANK 7
  include "gen/pletter/levelsdat.pletter_8k.b7.bas"
#elif BANK_SIZE
BANK 2
  include "gen/pletter/levelsdat.pletter_16k.b2.bas"
BANK 3
  include "gen/pletter/levelsdat.pletter_16k.b3.bas"
BANK 4
  include "gen/pletter/levelsdat.pletter_16k.b4.bas"
#endif
