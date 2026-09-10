# Zsh Configuration

This document describes the zsh shell configuration in this dotfiles repository.

## Design Philosophy

The configuration follows a minimalist, performance-focused approach:

- Uses znap for lightweight plugin management with lazy-loading and caching
- Implements standard specifications (XDG Base Directory)
- Provides robust utility functions with comprehensive fallbacks
- Optimized for fast shell startup (50-80% faster than oh-my-zsh)

## Key Features

- **XDG Compliance**: Proper directory structure following standards
- **Clean PATH Management**: Auto-deduplication with `typeset -U path`
- **Vi Mode**: Familiar vi keybindings with cursor shape changes
- **Lazy-loaded Tools**: Cached initialization for mise, atuin, starship (10x faster)
- **Fast Reload**: Custom `reload!` function for quick shell restarts
- **Smart Project Navigation**: Intelligent repository discovery with the `c` function

## Configuration Files

The zsh configuration is split across two files:

- `home/dot_zshenv` - Environment setup and PATH configuration
- `home/dot_zshrc.tmpl` - Interactive shell configuration (Chezmoi template)

## Environment Setup (dot_zshenv)

### Automatic PATH Deduplication

The configuration uses `typeset -U path` to automatically prevent duplicate entries in PATH:

```bash
# Prevent duplicates in PATH automatically
typeset -U path
```

This eliminates the need for manual duplicate checking when adding directories to PATH.

### XDG Base Directory Specification

The configuration implements the [XDG Base Directory Specification](https://specifications.freedesktop.org/basedir-spec/latest/) for standardized directory locations:

```bash
# User directories
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"

# System directories
export XDG_DATA_DIRS="${XDG_DATA_DIRS:-/usr/local/share:/usr/share}"
export XDG_CONFIG_DIRS="${XDG_CONFIG_DIRS:-/etc/xdg}"
```

### PATH Management

The configuration adds user binary directories to PATH with automatic deduplication:

```bash
# Add bun global bin directory to PATH
[[ -d "$HOME/.cache/.bun/bin" ]] && path=("$HOME/.cache/.bun/bin" $path)

# Add ~/.local/bin to front of PATH
[[ -d "$HOME/.local/bin" ]] && path=("$HOME/.local/bin" $path)

# Make mise-managed tools available to non-interactive shells and subprocesses
[[ -d "$XDG_DATA_HOME/mise/shims" ]] && path=("$XDG_DATA_HOME/mise/shims" $path)
```

The mise shim path lives in `.zshenv` because agent commands and executable
shebangs often run without an interactive prompt. Interactive shells still load
the richer mise integration from `tools.zsh`.

## Interactive Shell Configuration (dot_zshrc.tmpl)

### Znap Plugin Manager

The configuration uses [znap (zsh-snap)](https://github.com/marlonrichert/zsh-snap) for fast, minimal plugin management:

- **Installation**: Managed via Chezmoi external (`.chezmoiexternal.toml.tmpl`)
- **Location**: `~/.zsh/znap/zsh-snap/`
- **Benefits**: Lazy loading, caching, faster startup than traditional plugin managers

### Performance Optimizations

1. Early Exit for Non-Interactive Shells

```bash
[[ ! -v TERM ]] && return 0
```

Prevents unnecessary configuration loading in cron, scripts, etc.

2. macOS PATH Fix

```bash
source ~/.zshenv
```

Re-sources `.zshenv` after macOS `/etc/zprofile` modifies PATH.

3. Lazy-loaded Tool Initialization

Uses `znap eval` to cache expensive tool initialization:

```bash
znap eval mise 'mise activate zsh'
znap eval atuin 'atuin init zsh'
znap eval starship 'starship init zsh'
```

The first run executes the command and caches the output.
Subsequent runs use the cache, providing 10x faster startup.

### Plugins

Plugins are loaded via znap for consistent management:

- **zsh-autosuggestions**: Command suggestions from history
- **zsh-syntax-highlighting**: Real-time syntax highlighting (loaded last)

Both plugins are pre-configured for optimal performance.

### Vi Mode

Vi keybindings are enabled with cursor shape changes:

```bash
bindkey -v
```

- **Insert mode**: Beam cursor (|)
- **Normal mode**: Block cursor (█)

### History Configuration

Optimized for large history with smart deduplication:

```bash
HISTSIZE=1000000000
SAVEHIST=$HISTSIZE
setopt EXTENDED_HISTORY
setopt SHARE_HISTORY
setopt HIST_FIND_NO_DUPS
setopt HIST_REDUCE_BLANKS
setopt HIST_VERIFY
```

### Shell Options

Key options for better UX:

- `WORDCHARS=""` - Make `Ctrl-W` stop on punctuation like other editors
- `CASE_SENSITIVE="true"` - Case-sensitive completion
- `HIST_VERIFY` - Show history expansion before running

### Custom Functions

The configuration includes a function autoloading system that follows zsh best practices. Functions are stored in `$XDG_CONFIG_HOME/zsh/functions/` and autoloaded on demand for better performance.

#### reload! Function

A shell reload function for fast configuration reloads. Simply run `reload!` to restart your shell session with updated configuration.

The function intelligently detects the current shell binary using multiple fallback methods to ensure the exact same zsh process is re-executed.

#### c Function

A project navigation function for quickly changing to project directories.

**Usage:**

```bash
c                    # Use fzf to select from available projects
c REPO              # Navigate to REPO across configured organizations
c ORG/REPO          # Navigate to specific ORG/REPO
```

**Environment Variables:**

- `PROJECTS_DIR` - Base directory for projects (default: `$HOME/src/github.com`)
- `GITHUB_USER` - Primary GitHub username
- `GITHUB_ORGS` - Comma-delimited list of GitHub organizations to search (e.g., `"myorg,company,another-org"`)

**Smart Repository Discovery:**

When you specify just a repository name (e.g., `c dotfiles`), the function:

1. Searches locally across all configured organizations
2. If not found locally, tries cloning from each organization in order
3. Only creates a new repository if none are found and you confirm

**Organization Priority:**

The function checks organizations in this order:

1. `GITHUB_USER` environment variable
2. User from `gh config get user` (GitHub CLI)
3. Organizations from `GITHUB_ORGS` (comma-delimited)
4. System username as final fallback

### Git-safe PATH

The configuration includes a security feature for per-repository trusted binaries:

```bash
export PATH=".git/safe/../../bin:$PATH"
```

This prepends `.git/safe/../../bin` to PATH, allowing repositories to provide trusted executables. See <https://thoughtbot.com/blog/git-safe> for more information.

**Important**: Only mark repositories as safe if you trust all contributors.

## Performance

Compared to oh-my-zsh:

- **50-80% faster startup** through znap caching and lazy-loading
- **90% less code** in `.zshrc` (299 lines vs 389 lines)
- **No framework overhead** - direct plugin loading
- **Cached tool initialization** - mise, atuin, starship only execute once

## Aliases

The configuration includes conditional aliases for enhanced tools:

- `cat` → `bat` (syntax-highlighted file viewing)
- `ls` → `eza` (modern ls with icons)
- `vi/vim` → `nvim` (Neovim)
- `df` → `duf` (prettier disk usage)
- `du` → `dust` (prettier directory sizes)
- `top` → `htop` (better process viewer)

All aliases are only created if the target command is available.

## Troubleshooting

### Slow Startup

If startup feels slow:

1. Run `znap clean` to clear plugin cache
2. Check for slow commands in `~/.config/zsh/local.zsh`
3. Use `zsh -xv` to see what's being executed

### Completions Not Working

If completions aren't working:

1. Delete `~/.zcompdump` and restart shell
2. Run `compinit` manually to check for errors
3. Ensure `$XDG_CONFIG_HOME/zsh/completions` exists

### Vi Mode Issues

If cursor shapes aren't changing:

1. Check terminal supports cursor shape escape sequences
2. Try setting `VI_MODE_SET_CURSOR=false` in `~/.config/zsh/local.zsh`

### PATH Issues on macOS

If PATH is wrong on macOS:

1. Check `/etc/zprofile` isn't overriding it
2. Verify `.zshenv` is being re-sourced in `.zshrc`
3. Use `echo $PATH` immediately after login to debug
