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

LEVEL = 1
PAGE = 0
CONST MAXPAGE                   = (LEVEL_COUNT - 1) / 24

levelSelect: PROCEDURE


  ' generate list
  ' to get level names, ...
  DEFINE VRAM PLETTER $2800, 0, levelTitlesPletter

  GOSUB renderLevelPage

  VDP_ENABLE_INT

  SCR_IDX = 0
  WHILE $FF
    WAIT
    GOSUB updateNavInput

    IF NAV(NAV_DOWN) THEN
      IF SCR_IDX = 23 THEN
        GOSUB nextPage
        IF PAGE = MAXPAGE THEN SCR_IDX =((LEVEL_COUNT - 1) % 24)
      ELSE
        IF PAGE < MAXPAGE OR SCR_IDX <((LEVEL_COUNT - 1) % 24) THEN
          SCR_IDX = SCR_IDX + 1
        END IF
      END IF
    END IF

    IF NAV(NAV_UP) THEN
      IF SCR_IDX = 0 THEN
        GOSUB prevPage
      ELSE
        SCR_IDX = SCR_IDX - 1
      END IF
    END IF

    IF NAV(NAV_RIGHT) THEN
      GOSUB nextPage
      SCR_IDX = 0
    END IF

    IF NAV(NAV_LEFT) THEN
      GOSUB prevPage
      SCR_IDX = 0
    END IF

    IF NAV(NAV_OK) THEN
      EXIT WHILE
    END IF

    PRINT AT XY(0, SCR_IDX - 1), " "
    PRINT AT XY(0, SCR_IDX + 1), " "
    PRINT AT XY(31, SCR_IDX - 1), " "
    PRINT AT XY(31, SCR_IDX + 1), " "
    PRINT AT XY(0, SCR_IDX), ">"
    PRINT AT XY(31, SCR_IDX), "<"

    FOR I = 0 TO 4
      WAIT
      GOSUB updateNavInput
      IF g_nav = NAV_NONE THEN EXIT FOR
    NEXT I
  WEND

  LEVEL =(PAGE * 24) + SCR_IDX + 1
  #TITLEADDR = $2800 + 1 +((LEVEL - 1) * 23)
  DEFINE VRAM READ #TITLEADDR, 23, VARPTR rowBuffer(0)


END

renderLevelPage: PROCEDURE
  LMIN = PAGE * 24 + 1
  LMAX =(PAGE + 1) * 24
  IF LMAX > LEVEL_COUNT THEN LMAX = LEVEL_COUNT

  #TITLEADDR = $2800 + 1 +((LMIN - 1) * 23)
  FILL_BUFFER(" ")
  FOR Y = 0 TO 23
    DEFINE VRAM $1800 + XY(0, Y), 32, VARPTR rowBuffer(0)
  NEXT Y

  I = 0
  FOR LEVEL = LMIN TO LMAX
    DEFINE VRAM READ #TITLEADDR, 23, VARPTR rowBuffer(0)
    PRINT AT XY(2, I), <3> LEVEL
    DEFINE VRAM $1800 + XY(7, I), 23, VARPTR rowBuffer(0)
    #TITLEADDR = #TITLEADDR + 23
    I = I + 1
  NEXT LEVEL
END

prevPage: PROCEDURE
  IF PAGE > 0 THEN
    PAGE = PAGE - 1
    GOSUB renderLevelPage
  END IF
END

nextPage: PROCEDURE
  IF PAGE < MAXPAGE THEN
    PAGE = PAGE + 1
    GOSUB renderLevelPage
  END IF
END

include "gen/pletter/font.pletter.bas"
