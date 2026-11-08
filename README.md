# Dotfiles

Personal dotfiles for macOS, Linux, and containers, managed with [chezmoi](https://www.chezmoi.io/).

## Install

With chezmoi installed:

```sh
chezmoi init --apply martinemde
```

Otherwise, clone this repo and run `./install.sh`.
See [installation](docs/installation.md) for prerequisites and options.

## Make changes

Edit source files in `home/`, not the installed copies in `~/`.

```sh
chezmoi diff
chezmoi apply
```

## Zellij

The status bar uses the same Nerd Font OS icons as Starship, including Raspberry Pi OS.
On narrow terminals, tabs take priority: branch/clock hide first, then OS/mode/session.
The clock shows hours and minutes. zjstatus hides whole sections, not individual tab
names; many tabs or a very long tab name can still exceed the screen width.

Layout changes take effect in new sessions or tabs; existing status bars keep their
loaded configuration.

## Reference

- [Tool and setup notes](docs/)
- [Download security](docs/download-security.md) and [updates](docs/renovate.md)
- [Tests](docs/testing.md)
- [Agent instructions](AGENTS.md)

## License

[ISC](LICENSE) — Ivy Evans, Martin Emde.
