# Installation

With chezmoi installed:

```sh
chezmoi init --apply martinemde
```

Otherwise:

```sh
git clone https://github.com/martinemde/dotfiles.git
cd dotfiles
./install.sh
```

See [Linux bootstrap](linux-bootstrap.md) for Linux prerequisites and
[bootstrap security](bootstrap-security.md) for verification details.

## Installer options

The installer keeps existing tools unless forced to reinstall. It passes arguments
following `--` to `chezmoi init`:

```sh
REINSTALL_TOOLS=true ./install.sh
./install.sh -- --force
./install.sh -- --one-shot
```

- `BIN_DIR=/custom/path` changes the binary installation directory (default: `~/.local/bin`).
- `DEBUG=1` enables installer debug output.
- `VERIFY_SIGNATURES=false` skips signature verification, not archive checksums.
  Investigate verification failures rather than disabling checks.

Run `./install.sh --help` for all installer options.

## Non-interactive initialization

The chezmoi config skips prompts when stdin is not a TTY or
`CHEZMOI_NONINTERACTIVE=1` is set. `CHEZMOI_HOSTTYPE=home` or `work` selects the
host type in that mode; the default is `home`.

Git name and email are hardcoded in `home/.chezmoi.toml.tmpl`.
`GIT_USER_NAME` and `GIT_USER_EMAIL` do not override them.
