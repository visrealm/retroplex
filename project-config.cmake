# Minimal per-project settings
# Adjust these values to suit your game/demo.

set(PROJECT_NAME retroplex)
set(VERSION "v0-0-1")
set(MAIN_SOURCE "retroplex.bas")
set(CART_TITLE "RETROPLEX")

# Override CVBasic executable (leave empty to use bundled/default tooling)
# set(CVBASIC_CUSTOM_EXE "C:/projects/CVBasic/build/cvbasic.exe" CACHE FILEPATH "Path to prebuilt CVBasic executable")

# List the platform targets you want built. Removing a target also skips
# downloading/building its toolchain (e.g., TI-99 / XDT99) when possible.
set(ENABLED_TARGETS
    coleco
    msx_asc16
    msx_konami
    ti99       # uncomment to enable TI-99/4A and build XDT99 tools
    nabu
    sg1000
    #creativision
    # nabu_mame  # uncomment to enable NABU MAME packaging target
)
 