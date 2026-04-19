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

' VDP constants
CONST #VDP_NAME_TAB1            = $2000
CONST #VDP_NAME_TAB2            = #VDP_NAME_TAB1 + $0400

CONST #VDP_PATT_TAB1            = $0000
CONST #VDP_PATT_TAB2            = #VDP_PATT_TAB1 + $0800
CONST #VDP_PATT_TAB3            = #VDP_PATT_TAB2 + $0800

CONST #VDP_COLOR_TAB1           = $2800
CONST #VDP_COLOR_TAB2           = #VDP_COLOR_TAB1 + $0400

CONST #VDP_SPRITE_ATTR          = $2700
CONST #VDP_SPRITE_PATT          = #VDP_PATT_TAB1

CONST TILE_SIZE                 = 8

CONST NAME_TABLE_WIDTH          = 32
CONST NAME_TABLE_HEIGHT         = 24

#if TMS9918_TESTING
  DEF FN VDP_REG(VR) = IF (VR < 8) THEN VDP(VR)
  DEF FN VDP_STATUS = 0
#else
  DEF FN VDP_REG(VR) = VDP(VR)
  DEF FN VDP_STATUS = USR RDVST
#endif

DEF FN VDP_CONFIG(I) = VDP_REG(58) = I : VDP_REG(59) ' = xxx
DEF FN VDP_STATUS_REG = VDP_REG(15)
DEF FN VDP_STATUS_REG0 = VDP_STATUS_REG = 0

' VDP helpers
DEF FN VDP_DISABLE_INT = VDP_REG(1) = $C0 OR vdpR1Flags
DEF FN VDP_ENABLE_INT = VDP_REG(1) = $E0 OR vdpR1Flags
DEF FN VDP_DISABLE_INT_DISP_OFF = VDP_REG(1) = $80 OR vdpR1Flags
DEF FN VDP_ENABLE_INT_DISP_OFF = VDP_REG(1) = $A0 OR vdpR1Flags
' name table helpers
DEF FN XY(X, Y) =((Y) * NAME_TABLE_WIDTH +(X)) ' PRINT AT XY(1, 2), ...
DEF FN XY1(X, Y) =((#VDP_NAME_TAB2 - #VDP_NAME_TAB1) + XY(X, Y))
DEF FN PATT_OFFSET(P) =((P) * 8)
DEF FN TILES_PX(C) =((C) * 8)

DEF FN NAME_TAB_XY(X, Y) =(#VDP_NAME_TAB1 + XY(X, Y)) ' DEFINE VRAM NAME_TAB_XY(1, 2), ...
DEF FN NAME_TAB1_XY(X, Y) =(#VDP_NAME_TAB2 + XY(X, Y)) ' DEFINE VRAM NAME_TAB_XY(1, 2), ...
DEF FN PUT_XY(X, Y) = VPOKE NAME_TAB_XY(X, Y) ' place a byte in the name table
DEF FN GET_XY(X, Y) = VPEEK(NAME_TAB_XY(X, Y)) ' read a byte from the name table

DEF FN NAME_TABLE0 = VDP(2) = 6
DEF FN NAME_TABLE1 = VDP(2) = 7

' used as a staging area for dynamic vram data (instead of a VPOKE in a loop or similar)
DIM rowBuffer(NAME_TABLE_WIDTH)
DEF FN FILL_BUFFER(val) = CH = val : GOSUB fillBuffer
DEF FN COPY_BUFFER(cnt, adr) = FOR J = 0 TO cnt - 1 : rowBuffer(J) = adr(J) : NEXT J

CH = 0

fillBuffer: PROCEDURE
  FOR J = 0 TO NAME_TABLE_WIDTH - 1 : rowBuffer(J) = CH : NEXT J
  END

  ' -----------------------------------------------------------------------------
  ' TMS9900 machine code (for PICO9918 GPU) to write $00 to VDP $3F00
  ' -----------------------------------------------------------------------------
  DIM vdpR1Flags

  ' -----------------------------------------------------------------------------
  ' detect the vdp type. sets isF18ACompatible
  ' -----------------------------------------------------------------------------
vdpDetect: PROCEDURE
    GOSUB vdpUnlock
    DEFINE VRAM $3F00, VARPTR gpuVdpDetectEnd(0) - VARPTR gpuVdpDetect(0), gpuVdpDetect
    VDP_REG($36) = $3F ' set gpu start address msb
    VDP_REG($37) = $00 ' set gpu start address lsb (triggers)
    isF18ACompatible = VPEEK($3F00) = 0 ' check result
    isV9938 = FALSE
    isPICO9918 = FALSE
    IF isF18ACompatible = FALSE THEN
      VDP_STATUS_REG = 4
      isV9938 =((VDP_STATUS AND $fe) = $fe)
      VDP_STATUS_REG0
    ELSE
      VDP_STATUS_REG = 1
      isPICO9918 =((VDP_STATUS AND $e8) = $e8)
      VDP_STATUS_REG0
    END IF
    IF isV9938 THEN ' avoid warning
    END IF
  END

  ' -----------------------------------------------------------------------------
  ' unlock F18A mode
  ' -----------------------------------------------------------------------------
vdpUnlock: PROCEDURE
    VDP_DISABLE_INT_DISP_OFF
    VDP_REG(57) = $1C ' unlock
    VDP_REG(57) = $1C ' unlock... again
    VDP_ENABLE_INT_DISP_OFF
  END

gpuWait: PROCEDURE
    VDP_REG(15) = 2
    WHILE VDP_STATUS AND $80
    WEND
    VDP_REG(15) = 0
  END

defaultReg:
    ' default VDP register values
    DATA BYTE $00 ' R0
    DATA BYTE $02 ' R1
    DATA BYTE #VDP_NAME_TAB1 / $400 ' Name  (>> 10)
    DATA BYTE #VDP_COLOR_TAB1 / $40 ' Color (>> 6)
    DATA BYTE #VDP_PATT_TAB1 / $800 ' Patt  (>> 11)
    DATA BYTE #VDP_SPRITE_ATTR / $80 ' Spr Attr (>> 7)
    DATA BYTE #VDP_SPRITE_PATT / $800 ' Spr Patt  (>> 11)
    DATA BYTE $00 ' FG | BG

  include "gen/gpu/gpu-vdp-detect.bin.bas"
