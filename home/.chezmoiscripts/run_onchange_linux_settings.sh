#!/bin/bash
set -euo pipefail
[ -n "${DEBUG:-}" ] && set -o xtrace

# Only configure GNOME if gsettings is available
command -v gsettings >/dev/null 2>&1 || exit 0

# Fast key repeat (matches macOS KeyRepeat 1)
gsettings set org.gnome.desktop.peripherals.keyboard delay 150
gsettings set org.gnome.desktop.peripherals.keyboard repeat-interval 15
