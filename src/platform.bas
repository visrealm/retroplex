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

#if TI994A
  CONST BANK_SIZE                 = 8
  CONST BANK8                     = 1
#elif COLECOVISION
  CONST BANK_SIZE                 = 16
#elif MSX
  CONST BANK_SIZE                 = 16
#elif SG1000
  CONST BANK_SIZE                 = 16
#else
  CONST BANK_SIZE                 = 0
#endif
