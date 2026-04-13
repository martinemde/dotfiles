#!/bin/sh
#
# install-home.sh -- Install dotfiles in home (non-work) mode
#
# Wrapper around install.sh that sets hosttype to "home" and skips
# the interactive host-type prompt. All arguments are forwarded to
# install.sh.
#
# USAGE:
#   ./install-home.sh                   # Install with home defaults
#   ./install-home.sh -- --force        # Pass --force to chezmoi init
#

set -o errexit -o nounset

script_dir="$(cd "$(dirname "$0")" && pwd)"

export CHEZMOI_NONINTERACTIVE=1
export CHEZMOI_HOSTTYPE=home

exec "$script_dir/install.sh" "$@"
