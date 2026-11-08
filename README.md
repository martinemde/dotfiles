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

## Reference

- [Tool and setup notes](docs/)
- [Download security](docs/download-security.md) and [updates](docs/renovate.md)
- [Tests](docs/testing.md)
- [Agent instructions](AGENTS.md)

## License

[ISC](LICENSE) — Ivy Evans, Martin Emde.
