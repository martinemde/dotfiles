#!/bin/sh

set -o errexit -o nounset

if [ "${DEBUG:-}" = "1" ]; then
    set -x
fi

ssh_dir="$HOME/.ssh"
config="$ssh_dir/config"
include='Include config.d/*.conf'

mkdir -p "$ssh_dir"
chmod 700 "$ssh_dir"

# Leave machine-local settings first: OpenSSH uses the first value it reads.
# Host * makes the include unconditional even after a local Host or Match block.
if [ ! -f "$config" ] || ! awk '
    BEGIN { global = 1 }
    tolower($1) == "host" { global = ($2 == "*" && NF == 2) }
    tolower($1) == "match" { global = 0 }
    global && $0 == "Include config.d/*.conf" { found = 1 }
    END { exit !found }
' "$config"; then
    umask 077
    printf '\nHost *\n%s\n' "$include" >>"$config"
fi
