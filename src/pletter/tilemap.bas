' map of levels.dat tiles to VDP quad tiles (multiply by 4 to get pattern index)
' if the tile isn't a simple tile (filpped or palett or subtile change, its $80 will be set)
' the remaining 7 bits becomes an index into the advanced tile attributes table
' followed by tile attributes (color table value)
tileMap:
  DATA BYTE $81, $00 ' 0 - Empty [*]
  DATA BYTE $31, $04 ' 1 - Zonk
  DATA BYTE $02, $02 ' 2 - Base
  DATA BYTE $2E, $00 ' 3 - Murphy
  DATA BYTE $8D, $04 ' 4 - Infotron [*]
  DATA BYTE $1F, $04 ' 5 - RAM chip - Chip
  DATA BYTE $06, $04 ' 6 - Wall
  DATA BYTE $07, $04 ' 7 - Exit
  DATA BYTE $30, $06 ' 8 - Floppy - Orange
  DATA BYTE $05, $04 ' 9 - Port - Right
  DATA BYTE $03, $04 ' 10 - Port - Down
  DATA BYTE $82, $04 ' 11 - Port - Left [*]
  DATA BYTE $83, $04 ' 12 - Port - Up [*]
  DATA BYTE $05, $04 ' 13 - Gravity port - Right
  DATA BYTE $03, $04 ' 14 - Gravity port - Down
  DATA BYTE $84, $04 ' 15 - Gravity port - Left [*]
  DATA BYTE $85, $04 ' 16 - Gravity port - Up [*]
  DATA BYTE $35, $00 ' 17 - Snik snak
  DATA BYTE $86, $04 ' 18 - Floppy - Yellow [*]
  DATA BYTE $8F, $04 ' 19 - Terminal [*]
  DATA BYTE $87, $04 ' 20 - Floppy - Red [*]
  DATA BYTE $88, $02 ' 21 - Port - Two-way vertical [*]
  DATA BYTE $89, $02 ' 22 - Port - Two-way horizontal [*]
  DATA BYTE $04, $04 ' 23 - Port - 4-way
  DATA BYTE $2F, $08 ' 24 - Electron
  DATA BYTE $02, $02 ' 25 - Bug
  DATA BYTE $22, $04 ' 26 - RAM chip - Left
  DATA BYTE $23, $04 ' 27 - RAM chip - Right
  DATA BYTE $1C, $0A ' 28 - Hardware (decoration)
  DATA BYTE $19, $02 ' 29 - Hardware (decoration)
  DATA BYTE $18, $0C ' 30 - Hardware (decoration)
  DATA BYTE $8A, $02 ' 31 - Hardware (decoration) [*]
  DATA BYTE $1E, $04 ' 32 - Hardware (decoration)
  DATA BYTE $8E, $04 ' 33 - Hardware (decoration) [*]
  DATA BYTE $25, $0A ' 34 - Hardware (decoration)
  DATA BYTE $26, $0A ' 35 - Hardware (decoration)
  DATA BYTE $1B, $0A ' 36 - Hardware (decoration)
  DATA BYTE $27, $0A ' 37 - Hardware (decoration)
  DATA BYTE $20, $04 ' 38 - RAM chip - Top
  DATA BYTE $21, $04 ' 39 - RAM chip - Bottom
  DATA BYTE $01, $04 ' 40 - Border - Corner
  DATA BYTE $8B, $02 ' 41 - Border - Horizontal [*]
  DATA BYTE $8C, $04 ' 42 - Border - Vertical [*]
  DATA BYTE $35, $00 ' 43 - Snik snak - U (Dup)
  DATA BYTE $36, $00 ' 44 - Snik Snak - UL
  DATA BYTE $34, $00 ' 45 - Snik Snak - L
  DATA BYTE $90, $00 ' 46 - Snik Snak - DL [*]
  DATA BYTE $91, $00 ' 47 - Snik Snak - D [*]
  DATA BYTE $92, $00 ' 48 - Snik Snak - DR [*]
  DATA BYTE $93, $00 ' 49 - Snik Snak - R [*]
  DATA BYTE $94, $00 ' 50 - Snik Snak - UR [*]
  DATA BYTE $31, $04 ' 51 - Zonk - H
  DATA BYTE $95, $00 ' 52 - Zonk - HL [*]
  DATA BYTE $33, $04 ' 53 - Zonk - V
  DATA BYTE $32, $04 ' 54 - Zonk - VL
  DATA BYTE $96, $00 ' 55 - Murphy [*]
  DATA BYTE $08, $04 ' 56 - Explode 0
  DATA BYTE $09, $04 ' 57 - Explode 1
  DATA BYTE $0A, $04 ' 58 - Explode 2
  DATA BYTE $0B, $04 ' 59 - Explode 3
  DATA BYTE $0C, $04 ' 60 - Explode 4
  DATA BYTE $0D, $04 ' 61 - Explode 5
  DATA BYTE $0E, $04 ' 62 - Explode 6

  ' for complex tiles, this map contains the four tile indices and their attributes
  ' format:  TL, TLA,  TR, TRA,  BL, BLA,  BR, BRA
advancedTileMap:
  DATA BYTE $00, $00, $00, $00, $00, $00, $00, $00 '  - DYNAMIC BUFFER
  DATA BYTE $00, $00, $00, $00, $00, $00, $00, $00 ' 0 - Empty
  DATA BYTE $16, $14, $17, $15, $44, $44, $44, $44 ' 11 - Port - Left
  DATA BYTE $0D, $0F, $0C, $0E, $24, $24, $24, $24 ' 12 - Port - Up
  DATA BYTE $16, $14, $17, $15, $44, $44, $44, $44 ' 15 - Gravity port - Left
  DATA BYTE $0D, $0F, $0C, $0E, $24, $24, $24, $24 ' 16 - Gravity port - Up
  DATA BYTE $A0, $A1, $C1, $C3, $06, $06, $06, $06 ' 18 - Floppy - Yellow
  DATA BYTE $A2, $A3, $C1, $C3, $06, $06, $06, $06 ' 20 - Floppy - Red
  DATA BYTE $0D, $0F, $0D, $0F, $24, $24, $04, $04 ' 21 - Port - Two-way vertical
  DATA BYTE $16, $16, $17, $17, $44, $04, $44, $04 ' 22 - Port - Two-way horizontal
  DATA BYTE $60, $62, $61, $63, $04, $04, $04, $04 ' 31 - Hardware (decoration)
  DATA BYTE $03, $03, $03, $03, $04, $04, $04, $04 ' 41 - Border - Horizontal
  DATA BYTE $02, $02, $02, $02, $04, $04, $04, $04 ' 42 - Border - Vertical
  DATA BYTE $F0, $F2, $F1, $F3, $08, $08, $06, $06 ' 4 - Infotron
  DATA BYTE $90, $92, $91, $93, $02, $0A, $0A, $0A ' 33 - Hardware (decoration)
  DATA BYTE $74, $76, $75, $77, $0C, $0C, $0C, $04 ' 19 - Terminal
  DATA BYTE $D9, $DB, $D8, $DA, $20, $20, $20, $20 ' 46 - Snik Snak - DL
  DATA BYTE $D5, $D7, $D4, $D6, $20, $20, $20, $20 ' 47 - Snik Snak - D
  DATA BYTE $DB, $D9, $DA, $D8, $60, $60, $60, $60 ' 48 - Snik Snak - DR
  DATA BYTE $D2, $D0, $D3, $D1, $40, $40, $40, $40 ' 49 - Snik Snak - R
  DATA BYTE $DA, $D8, $DB, $D9, $40, $40, $40, $40 ' 50 - Snik Snak - UR
  DATA BYTE $CA, $C8, $CB, $C9, $44, $44, $44, $44 ' 52 - Zonk - HL
  DATA BYTE $BA, $B8, $BB, $B9, $40, $40, $40, $40 ' 55 - Murphy (right)
