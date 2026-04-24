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

include "platform.bas"

' ==========================================
' ENTRY POINT
' ------------------------------------------
GOTO main

CONST FALSE                     = 0
CONST TRUE                      = -1

CONST CVBASIC_DIRECT_SPRITES    = 1

CONST #GPU_STAGING_ADDR         = $1800
CONST #BITMAP_ADDR              = $1800
CONST #BITMAP_FONT_ADDR         = $1E00
CONST #TILE_MAPPING_ADDR        = $2300
CONST #TILE_MAP_ADV_ADDR        = $2B00
CONST #LEVEL_STAGING_ADDR       = $1800 ' Temporary staging for 1-byte level data
CONST #LEVEL_WORKING_ADDR       = $9000 ' GPU expands to 2-byte tiles here

CONST #BMP_X                    = $2F06
CONST #BMP_Y                    = $2F07
CONST #BMP_TEXT_ADDR            = $2F08
CONST #BMP_TEXT_LEN             = $2F0A
CONST #BMP_TEXT_COLOR           = $2F0B
CONST #VDP_TIME_TEXT            = $2F0C ' 8 bytes   dirty|hh|mm|ss

CONST #VDP_USER_INPUT           = $2F10

CONST #GPU_START_ADDR           = $B400
CONST #GPU_LOAD_LEVEL           = #GPU_START_ADDR
CONST #GPU_UPDATE_SCROLL        = #GPU_START_ADDR + 4
CONST #GPU_RENDER_TEXT          = #GPU_START_ADDR + 8

' ==========================================
' INCLUDES
' ------------------------------------------
include "banksel.bas"
include "vdp-utils.bas"
include "vdp-dma.bas"
include "input.bas"

main: PROCEDURE
  vdpR1Flags = $02

  ' what are we working with?
  GOSUB vdpDetect

  VDP_REG(7) = defaultReg(7)
  VDP_REG(0) = defaultReg(0) ' VDP_REG() doesn't accept variables, so...
  VDP_REG(1) = defaultReg(1) OR vdpR1Flags  
  VDP_REG(2) = $1800 / $400
  VDP_REG(3) = $2000 / $40
  VDP_REG(4) = defaultReg(4)
  VDP_REG(5) = defaultReg(5)
  VDP_REG(6) = defaultReg(6)

  VPOKE $2700, $D0

  FILL_BUFFER($f0)
  DEFINE VRAM $2000, 32, VARPTR rowBuffer(0)

  ' font for hardware check and level selector
  DEFINE VRAM PLETTER #VDP_PATT_TAB1 + 32 * 8, 64 * 8, fontPattPletter

  ' Check for PICO9918
  IF isPICO9918 = FALSE THEN
    VDP_ENABLE_INT
    PRINT AT XY(8, 10), "PICO9918 REQUIRED"
    WHILE TRUE
    WEND
  END IF

  ' Check PICO9918 firmware version (need >= 1.1.0)
  VDP_REG(58) = 2 ' config index 2 = major/minor version
  VDP_REG(15) = 12 ' select status register 12
  fwVersion = VDP_STATUS ' read major/minor version
  VDP_REG(15) = 0 ' restore status register 0
  IF fwVersion < $11 THEN
    VDP_ENABLE_INT
    PRINT AT XY(9, 8), "PICO9918 FOUND"
    PRINT AT XY(4, 10), "FIRMWARE 1.1.0+ REQUIRED"
    PRINT AT XY(0, 12), "SEE GITHUB.COM/VISREALM/PICO9918"
    WHILE TRUE
    WEND
  END IF

  GOSUB levelSelect

  VDP_REG(2) = defaultReg(2)
  VDP_REG(3) = defaultReg(3)

  VDP_DISABLE_INT_DISP_OFF

  VDP_REG(29) = $02 ' 2K ECM pages, 2x Horz Pages 
  VDP_REG(49) = $33 ' ECM3 Tiles and Sprites
  VDP_REG(50) = $02 ' Position-based attributes

  BANKSEL(1)

  DEFINE VRAM PLETTER #VDP_PATT_TAB1, 0, tiles1Patt0Pletter
  DEFINE VRAM PLETTER #VDP_PATT_TAB2, 0, tiles1Patt1Pletter
  DEFINE VRAM PLETTER #VDP_PATT_TAB3, 0, tiles1Patt2Pletter

  DEFINE VRAM PLETTER #VDP_PATT_TAB1 + 96 * 8, 0, tiles2Patt0Pletter
  DEFINE VRAM PLETTER #VDP_PATT_TAB2 + 96 * 8, 0, tiles2Patt1Pletter
  DEFINE VRAM PLETTER #VDP_PATT_TAB3 + 96 * 8, 0, tiles2Patt2Pletter

  DEFINE VRAM PLETTER #VDP_PATT_TAB1 + 184 * 8, 0, spritesPatt0Pletter
  DEFINE VRAM PLETTER #VDP_PATT_TAB2 + 184 * 8, 0, spritesPatt1Pletter
  DEFINE VRAM PLETTER #VDP_PATT_TAB3 + 184 * 8, 0, spritesPatt2Pletter

  VPOKE #VDP_SPRITE_ATTR, $d0 ' Initialize upper SAT terminator
  VPOKE #VDP_SPRITE_ATTR + $80, $d0 ' Initialize lower SAT terminator ($2780)

  ' tile mapping data
  DEFINE VRAM PLETTER #TILE_MAPPING_ADDR, 0, tileMapPletter
  DEFINE VRAM PLETTER #TILE_MAP_ADV_ADDR, 0, advancedTileMapPletter

  ' Load the game GPU code up into high VRAM
  gpuChunks = #gpuRetroplexBinChunkCount(0)
  #DESTADDR = #GPU_START_ADDR
  FOR I = 1 TO gpuChunks
    #SRCADDR = #gpuRetroplexBinChunkCatalogue(I - 1)
    DEFINE VRAM PLETTER #GPU_STAGING_ADDR, 0, VARPTR #SRCADDR
    DMA_INIT(#GPU_STAGING_ADDR, #DESTADDR, 128, 16) ' we don't need to wait for this, it's too fast
    #DESTADDR = #DESTADDR + $800
  NEXT I

  ' STAGE 1: Upload level data to staging area at $1800 (1-byte per tile)
  #LEVELADDR = #levelsdatCatalogue(LEVEL)
  BANKSEL(levelsdatBanks(LEVEL))
  DEFINE VRAM PLETTER #LEVEL_STAGING_ADDR, 0, VARPTR #LEVELADDR
  BANKSEL(1)

  DIM INFTEXT(3)
  PRINT AT $700, <3> VPEEK(#LEVEL_STAGING_ADDR + 3)
  DEFINE VRAM READ $1F00, 3, VARPTR INFTEXT(0)

  DIM LEVELTEXT(3)
  PRINT AT $700, <3> VPEEK(#LEVEL_STAGING_ADDR + 0)
  DEFINE VRAM READ $1F00, 3, VARPTR LEVELTEXT(0)

  DEFINE VRAM $1F00, 23, VARPTR rowBuffer(0)

  VDP_REG($36) = #GPU_START_ADDR / 256 ' set gpu start address msb
  VDP_REG($37) = #GPU_START_ADDR ' set gpu start address lsb (triggers)

  GOSUB gpuWait

  ' STAGE 3: Now $1800 is free, load bitmap layer
  DEFINE VRAM PLETTER #BITMAP_ADDR, 0, panelPletter
  VDP_REG(31) = $D4 ' Bitmap enable, Priority, opaque, fat, palette #4
  VDP_REG(32) = #BITMAP_ADDR / $40 ' addr >> 6
  VDP_REG(33) = 0 ' x
  VDP_REG(34) = 168 ' y
  VDP_REG(35) = 256 ' w (truncates to 0, but means 256)
  VDP_REG(36) = 24 ' h

  GOSUB gpuWait

  DEFINE VRAM PLETTER #BITMAP_FONT_ADDR, 0, bmpFontPletter

  GOSUB gpuWait

  VPOKE #BMP_X, 8
  VPOKE #BMP_Y, 14
  VPOKE #BMP_TEXT_ADDR, $1f00 / 256
  VPOKE #BMP_TEXT_ADDR + 1, $1f00 * 256 / 256
  VPOKE #BMP_TEXT_LEN, 23
  VPOKE #BMP_TEXT_COLOR, $90
  VDP_REG($37) = #GPU_RENDER_TEXT ' set gpu start address lsb (triggers) 

  DEFINE VRAM $1f00, 3, VARPTR INFTEXT(0)

  GOSUB gpuWait
  VPOKE #BMP_X, 114
  VPOKE #BMP_TEXT_LEN, 3
  VPOKE #BMP_TEXT_COLOR, $40
  VDP_REG($37) = #GPU_RENDER_TEXT ' set gpu start address lsb (triggers) 

  GOSUB gpuWait
  VPOKE #BMP_X, 30
  VPOKE #BMP_Y, 3

  DEFINE VRAM $1f00, 3, VARPTR LEVELTEXT(0)

  VPOKE #BMP_TEXT_COLOR, $90
  VDP_REG($37) = #GPU_RENDER_TEXT ' set gpu start address lsb (triggers) 
  GOSUB gpuWait

  VPOKE $1f00, "0"
  VPOKE $1f01, "0"
  VPOKE $1f02, "0"

  VPOKE #BMP_X, 48
  VPOKE #BMP_TEXT_LEN, 2
  VPOKE #BMP_TEXT_COLOR, $40
  VDP_REG($37) = #GPU_RENDER_TEXT ' set gpu start address lsb (triggers) 
  GOSUB gpuWait
  VPOKE #BMP_X, 62
  VDP_REG($37) = #GPU_RENDER_TEXT ' set gpu start address lsb (triggers) 
  GOSUB gpuWait
  VPOKE #BMP_X, 76
  VDP_REG($37) = #GPU_RENDER_TEXT ' set gpu start address lsb (triggers) 

  ' NOTE: Hopefully, by this point, the level is loaded (though it might not be... )
  VPOKE #VDP_USER_INPUT, 0

  ' load the palette, but then fade it out using the gpu
  DEFINE VRAM PLETTER $2F80, 0, palettePletter ' copy source palette to VRAM
  BANKSEL(0)
  VPOKE $3EFE, 0
  VPOKE $3EFF, 0
  DEFINE VRAM $3F00, VARPTR gpuPalFadeEnd(0) - VARPTR gpuPalFade(0), gpuPalFade
  VDP_REG($36) = $3F ' set gpu start address msb
  VDP_REG($37) = $00 ' set gpu start address lsb (triggers)  

  VDP_ENABLE_INT

  ' fade the palette in over 32 frames
  FOR C = 0 TO 16
    WAIT
    WAIT
    VPOKE $3EFF, C
    VDP_REG($37) = $00 ' set gpu start address lsb (triggers)
  NEXT C

  WAIT
  VDP_REG($36) = #GPU_UPDATE_SCROLL / 256 ' set gpu start address msb
  VDP_REG($37) = #GPU_UPDATE_SCROLL

  DIM FRAME_CNT
  DIM TICKS_CNT

  DIM SECONDS
  DIM MINUTES
  DIM HOURS

  VPOKE #BMP_Y, 3
  VPOKE #BMP_TEXT_LEN, 2
  VPOKE #BMP_TEXT_COLOR, $40

  WHILE TRUE
    WAIT

    ' Check if GPU halted (Murphy death countdown expired)
    VDP_REG(15) = 2
    GAME_RUNNING = (VDP_STATUS AND $80)
    VDP_REG(15) = 0

    IF GAME_RUNNING = 0 THEN EXIT WHILE    


    GOSUB updateNavInput

    VPOKE #VDP_USER_INPUT, g_nav

    FRAME_CNT = FRAME_CNT + 1

    ' Update the display

    ' Update electrons
    IF (FRAME_CNT AND $07) = 0 THEN
      PATT = FRAME_CNT / 8
      PATT = PATT % 13
      IF PATT > 6 THEN PATT = 13 - PATT
      DEFINE VRAM #VDP_PATT_TAB1 + 188 * 8, 8 * 4, VARPTR electronPatt0(PATT * 32)
      DEFINE VRAM #VDP_PATT_TAB2 + 188 * 8, 8 * 4, VARPTR electronPatt1(PATT * 32)
      DEFINE VRAM #VDP_PATT_TAB3 + 188 * 8, 8 * 4, VARPTR electronPatt2(PATT * 32)
    END IF

    ' Update terminals
    IF ((FRAME_CNT + 4) AND $1f) = 0 THEN
      PATT =(FRAME_CNT + 4) / 32
      PATT = PATT % 7
      DEFINE VRAM #VDP_PATT_TAB1 + 116 * 8, 8 * 4, VARPTR terminalPatt0(PATT * 32)
      DEFINE VRAM #VDP_PATT_TAB2 + 116 * 8, 8 * 4, VARPTR terminalPatt1(PATT * 32)
      DEFINE VRAM #VDP_PATT_TAB3 + 116 * 8, 8 * 4, VARPTR terminalPatt2(PATT * 32)
    END IF

    ' Update murphy
    IF ((FRAME_CNT + 2) AND $3) = 0 THEN
      PATT =(FRAME_CNT + 2) / 2
      PATT = PATT % 8
      IF PATT > 3 THEN PATT = 7 - PATT
      IF g_nav = 0 THEN PATT = 1 ELSE PATT = PATT + 1
      DEFINE VRAM #VDP_PATT_TAB1 + 184 * 8, 8 * 4, VARPTR murphyPatt0(PATT * 32 + 32)
      DEFINE VRAM #VDP_PATT_TAB2 + 184 * 8, 8 * 4, VARPTR murphyPatt1(PATT * 32 + 32)
      DEFINE VRAM #VDP_PATT_TAB3 + 184 * 8, 8 * 4, VARPTR murphyPatt2(PATT * 32 + 32)
    END IF

  WEND
 

  ' fade the palette in over 32 frames
  VDP_REG($36) = $3F ' set gpu start address msb
  FOR C = 15 TO 0 STEP -1
    WAIT
    WAIT
    VPOKE $3EFF, C
    VDP_REG($37) = $00 ' set gpu start address lsb (triggers)
  NEXT C

  WAIT

  VDP_DISABLE_INT_DISP_OFF

  VDP($32) = $c0  ' Reset VDP registers
  VDP_DISABLE_INT_DISP_OFF

  GOTO main

END

include "electron.bas"
include "terminal.bas"
include "murphy.bas"
include "levels.bas"

include "gen/gpu/gpu-retroplex.bin.pletter.bas"
include "gen/gpu/gpu-pal-fade.bin.bas"

include "leveldata.bas"

#if BANK_SIZE
BANK 1
#endif
include "gen/pletter/palette.pletter.bas"
include "gen/pletter/tiles_1.pletter.bas"
include "gen/pletter/tiles_2.pletter.bas"
include "gen/pletter/sprites.pletter.bas"
include "gen/pletter/panel.pletter.bas"
include "gen/pletter/bmpfont.pletter.bas"
include "gen/pletter/tilemap.pletter.bas"
