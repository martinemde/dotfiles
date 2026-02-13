# Linux Bootstrap

How and why the dotfiles work on Linux (tested on Raspberry Pi, Debian trixie arm64).

## Problem

These dotfiles were built for macOS. First-time `chezmoi init` on Linux hit hard failures:

- `onepasswordRead` called without 1Password CLI (`op`) installed
- Brew bundle scripts ran unconditionally
- macOS `defaults` commands executed on Linux (already handled via `_darwin_` naming)
- Homebrew env vars (openssl paths) polluted the shell on Linux

## What Changed

- **`onepasswordRead` gated by `lookPath "op"`** -- when `op` is absent, git signing key defaults to empty string and AWS profile prompt is skipped
- **Git commit signing conditional** -- `gpgsign = true`, `signingkey`, and `[gpg]` sections only render when a signing key is configured
- **Brew scripts renamed with `_darwin_`** -- chezmoi's OS filename convention skips them on Linux automatically
- **Homebrew env vars wrapped in OS check** -- `PKG_CONFIG_PATH`, `LDFLAGS`, `CPPFLAGS` for `/opt/homebrew` only set on macOS
- **`.chezmoiignore` expanded** -- `dot_Brewfile`, `dot_Brewfile.mas`, and `private_Library/` ignored on non-darwin

## Prerequisites

Packages needed before `install.sh`:

```bash
sudo apt install zsh git curl
```

`install.sh` handles installing mise and chezmoi. Mise installs tools declared in `.mise.toml`.

## What's Skipped on Linux

- 1Password integration (SSH agent, git signing, `op` CLI)
- Homebrew and Mac App Store packages
- macOS `defaults` settings
- Cursor IDE config (`private_Library/`)
- Homebrew openssl compiler flags

## Known Limitations

- No 1Password CLI on Linux ARM -- git commits are unsigned
- No Homebrew -- tools come from mise or apt
- Some mise tools may not have Linux ARM builds
