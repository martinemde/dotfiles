# Ghostty Terminal Configuration

This dotfiles repository includes configuration for [Ghostty](https://ghostty.org/), a fast, native, GPU-accelerated terminal emulator.

## Overview

- **Configuration Location**: `home/dot_config/ghostty/`
- **Font**: MonoLisa Nerd Font with advanced ligatures
- **Theme**: Catppuccin Mocha
- **Shell Integration**: Zsh with cursor, sudo, and title features
- **Keybinding Style**: tmux-inspired with `Ctrl+s` prefix

## File Hyperlink Support

Ghostty supports OSC 8 hyperlinks, allowing terminal output to include clickable file links that open in Neovim.

### Current Status

- **OSC 8 Hyperlinks**: ✅ Fully supported
- **Link Previews**: Configured to show for OSC 8 hyperlinks only
- **Regex-based `link` config**: ⏳ Not yet implemented ([#1972](https://github.com/ghostty-org/ghostty/issues/1972))

### What Works Now

#### Git Delta Integration

**Location**: `home/dot_config/git/delta.gitconfig`

Git diffs automatically include clickable file hyperlinks:

```toml
[delta]
hyperlinks = true
```

When viewing git diffs with delta, file paths are clickable with Cmd (macOS) or Ctrl (Linux) + click.

#### OSC 8 Shell Wrappers

**Location**: `home/dot_config/shell/osc8-hyperlinks.sh`

Provides shell functions that emit OSC 8 hyperlinks for common operations:

- **`flink <file> [line]`** - Print file path as clickable hyperlink
- **`hgrep <pattern> ...`** - grep with hyperlinked results
- **`hrg <pattern> ...`** - ripgrep with hyperlinked results (if rg installed)
- **`hls ...`** - ls with hyperlinked files (if gls/GNU ls installed)

Example usage:

```bash
# Make a file path clickable
flink /path/to/file.txt 42

# Search with clickable results
hgrep "TODO" src/*.js
hrg "function.*process" --type rust

# List with clickable filenames
hls --color=auto
```

#### Opening Files in Neovim

**Script**: `home/dot_local/bin/executable_nvim-open`

Handles file:// URIs and opens files in existing Neovim instance:

```bash
# Direct invocation
nvim-open /path/to/file.txt
nvim-open /path/to/file.txt:42
nvim-open file:///path/to/file.txt:42

# Via hyperlink (when ghostty link config is implemented)
# Cmd/Ctrl + click on hyperlink → calls nvim-open → opens in nvim
```

**How it works**:

1. Parses file:// URIs and file:line formats
2. Connects to nvim server at `/tmp/nvimsocket`
3. Opens file in existing instance (or starts new nvim if no server)
4. Jumps to line number if provided

### Future: Regex-based Link Configuration

**Location**: `home/dot_config/ghostty/config-hyperlinks`

When ghostty implements the `link` configuration option, uncomment these patterns to make arbitrary file paths clickable:

```toml
link = regex:^(/[^:]+)(:\d+)?$,action:exec:~/.local/bin/nvim-open

link = regex:^file://(/[^:]+)(:\d+)?$,action:exec:~/.local/bin/nvim-open

link = regex:^([a-zA-Z0-9_\-\.\/]+):(\d+):,action:exec:~/.local/bin/nvim-open# File paths: /path/to/file or /path/to/file:123
# File URIs: file:///path/to/file:123
# Relative paths from tool output: src/file.rs:42:
```

**Why not implemented yet**: Automatically detecting file paths via regex is difficult to get right without false positives. Ghostty recommends using OSC 8 hyperlinks instead.

**Workaround**: Use OSC 8 wrapper functions (`hgrep`, `hrg`, `flink`) to make specific output clickable.

## Design Decisions

### OSC 8 vs Regex Matching

**Chosen approach**: OSC 8 hyperlinks via shell wrappers

**Alternatives considered**:

- Regex-based link detection (not yet available in ghostty)
- tmux-thumbs/tmux-fingers (requires prefix key, not seamless)
- Hints mode like kitty (not yet available in ghostty [#2394](https://github.com/ghostty-org/ghostty/discussions/2394))

**Trade-offs**:

- ✅ Works immediately with current ghostty
- ✅ No false positives from regex matching
- ✅ Terminal-agnostic (OSC 8 is standard)
- ❌ Requires wrapping tools or using tools with native OSC 8 support
- ❌ Not automatic for arbitrary command output

**Why this decision**: Ghostty maintainers recommend OSC 8 as the correct approach. Tools are increasingly adding native OSC 8 support (ls, delta, etc.). Shell wrappers provide compatibility until tools catch up.

### Neovim Server Integration

**Decision**: Auto-start nvim server on first instance

**Location**: `home/dot_config/nvim/lua/config/options.lua:14-22`

**Why**:

- Clicking multiple hyperlinks opens files in same session
- Reduces overhead of spawning multiple nvim instances
- Maintains single editing context

**Alternative considered**: nvim-remote (nvr) package

- ❌ Requires Python dependency
- ❌ Additional package to maintain
- ✅ Native nvim --remote works equally well

## Keybinding Style

**Prefix**: `Ctrl+s` (inspired by tmux, avoids conflict with tmux's `Ctrl+b`)

**Philosophy**: Prefer sequences over chords, use vim-style movement keys

Examples:

- `Ctrl+s c` - New tab
- `Ctrl+s n/p` - Next/previous tab
- `Ctrl+s h/j/k/l` - Navigate splits
- `Ctrl+s z` - Zoom split

Full keybindings: `home/dot_config/ghostty/config-keybind`

## Related Documentation

- [Neovim Configuration](./neovim.md) - Nvim server setup
- [Tmux Configuration](./tmux.md) - Tmux integration
- [Ghostty Official Docs](https://ghostty.org/docs/)
