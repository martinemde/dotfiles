# tmux

Resurrect and continuum are commit-pinned chezmoi archives. The small
`.chezmoidata/tmux-plugins.yaml` manifest owns their repositories, tracked branches,
and commits; Renovate updates those pins. TPM is not needed for two shell entrypoints
and would add a second installer/updater over chezmoi-owned files.

Load resurrect before continuum: resurrect publishes the save/restore script paths
that continuum consumes. Load both after the theme because continuum adds its save
command to `status-right`. Synchronous `run-shell` preserves that ordering. Manual
save/restore bindings and continuum's automatic save/restore stay upstream defaults;
`@continuum-restore` remains enabled. Upstream deliberately avoids automatic saves
and restores when another tmux server is detected.

Removing TPM from the manifest does not delete a previously installed TPM directory
or remove bindings from a running server. A fresh server uses only these local
entrypoints; any old TPM directory can be removed separately. No startup fallback
clones repositories or installs plugins.

`python3 bin/check-tmux-updates` downloads the exact rendered archive pins into a
temporary directory and runs the real tmux integration check. Nothing is installed.

The integration test accepts already-downloaded pinned sources through
`TMUX_PLUGIN_SOURCES` (directories `tmux-resurrect` and `tmux-continuum`). It never
fetches code and uses a temporary HOME and private socket, not the live tmux server.
