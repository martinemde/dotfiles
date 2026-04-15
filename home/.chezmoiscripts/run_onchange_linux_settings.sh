#!/bin/bash
set -euo pipefail
[ -n "${DEBUG:-}" ] && set -o xtrace

# Skip on headless systems: gsettings ships in base packages, but the GNOME
# schemas it configures only exist when the desktop is actually installed.
command -v gsettings >/dev/null 2>&1 || exit 0
gsettings list-schemas 2>/dev/null | grep -q '^org\.gnome\.desktop\.peripherals\.keyboard$' || exit 0

# Fast key repeat (matches macOS KeyRepeat 1)
gsettings set org.gnome.desktop.peripherals.keyboard delay 150
gsettings set org.gnome.desktop.peripherals.keyboard repeat-interval 15
