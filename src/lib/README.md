# src/lib/

CVBasic runtime prologues and epilogues, one pair per target CPU:

- `cvbasic_prologue.asm` / `cvbasic_epilogue.asm` - Z80 (ColecoVision, MSX, NABU, SG-1000)
- `cvbasic_6502_prologue.asm` / `cvbasic_6502_epilogue.asm` - 6502 (CreatiVision)
- `cvbasic_9900_prologue.asm` / `cvbasic_9900_epilogue.asm` - TMS9900 (TI-99/4A)

## Processing

CVBasic reads the appropriate prologue/epilogue for the target platform and wraps the compiled program with it. These are assembly support routines the generated code depends on (I/O, math helpers, VDP access, etc.).

These files are maintained alongside CVBasic itself; they are tracked here so the build is self-contained and reproducible without depending on whichever CVBasic version happens to be installed system-wide.
