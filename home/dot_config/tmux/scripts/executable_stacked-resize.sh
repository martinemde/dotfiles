#!/usr/bin/env bash
set -euo pipefail

# Exit if stacking is disabled for this window
disabled=$(tmux show-option -wqv @stacked-disabled 2>/dev/null)
[ "$disabled" = "1" ] && exit 0

# Exit if pane is zoomed (resize conflicts with zoom state)
zoomed=$(tmux display-message -p '#{window_zoomed_flag}')
[ "$zoomed" = "1" ] && exit 0

# Get the active pane's column identifiers
active_info=$(tmux display-message -p '#{pane_id} #{pane_left} #{pane_width}')
active_id=${active_info%% *}
rest=${active_info#* }
active_left=${rest%% *}
active_width=${rest#* }

# Collect all panes in the current window
pane_data=$(tmux list-panes -F '#{pane_id} #{pane_left} #{pane_width} #{pane_active}')

# Find panes in the same column (matching pane_left and pane_width)
column_panes=()
while IFS=' ' read -r pid pleft pwidth pactive; do
    if [ "$pleft" = "$active_left" ] && [ "$pwidth" = "$active_width" ]; then
        column_panes+=("$pid:$pactive")
    fi
done <<< "$pane_data"

# Skip if only 1 pane in column (nothing to stack)
[ "${#column_panes[@]}" -le 1 ] && exit 0

# Collapse inactive panes first (gives room for expansion)
for entry in "${column_panes[@]}"; do
    pid=${entry%%:*}
    pactive=${entry##*:}
    if [ "$pactive" != "1" ]; then
        tmux resize-pane -t "$pid" -y 1 2>/dev/null || true
    fi
done

# Expand the active pane to fill remaining space
tmux resize-pane -t "$active_id" -y 9999 2>/dev/null || true
