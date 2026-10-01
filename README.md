# Dotfiles Redux

This repository contains my personal dotfiles for setting up a productive developer environment on macOS, Linux, and containerized setups using [Devcontainers](https://containers.dev/). The goal is to provide a stable and maintainable environment that prioritizes pragmatic defaults over heavy customization.

## Philosophy

- **Pragmatic Minimalism**: I prefer focused, single-purpose tools over complex frameworks. Instead of importing bulky plugins or features I don't use, I choose excellent, well-maintained tools that do one thing well with minimal configuration. Examples include znap for fast plugin loading, starship for cross-shell prompts, and mise for reproducible tool management.
- **Portability**: These dotfiles should work across macOS and Linux machines, as well as within containers. They are designed to be reliable whether installed system-wide or through a Devcontainer configuration.
- **Consistency**: The configuration aims to make pairing with others easy by sticking to intuitive shortcuts and well-known conventions. While these dotfiles improve my workflow, I can still work effectively without them if necessary.
- **Performance with Reliability**: Fast startup matters—this setup achieves 50-80% faster shell startup through caching and lazy-loading—but not at the cost of stability. I avoid risky optimizations and instead gain speed through minimalism and focused tooling. Runtime performance should not be significantly degraded by these configurations.

## Goals

1. **Stable setup** that rarely fails and is simple to maintain.
2. **Easy installation** on a fresh Mac or Linux system, with support for Devcontainers for containerized development.
3. **Shared tools** that follow common standards, enabling me to collaborate with others without friction.
4. **Documentation** that clearly explains the rationale behind each configuration choice.

## Installation

### Quick Start

```bash
chezmoi init --apply $GITHUB_USERNAME
```

### Advanced Usage

The installer supports various options and can pass arguments directly to `chezmoi init`:

```bash
# Force reinstall tools (if already installed)
REINSTALL_TOOLS=true ./install.sh

# Pass arguments to chezmoi init
./install.sh -- --force          # Force chezmoi to overwrite existing files
./install.sh -- --one-shot       # Use chezmoi's one-shot mode

# Combine options
REINSTALL_TOOLS=true ./install.sh -- --force
```

### Environment Variables

You can customize the installation behavior with these environment variables:

- `REINSTALL_TOOLS=true` - Force reinstallation of tools even if already present
- `BIN_DIR=/custom/path` - Install binaries to a custom directory (default: `~/.local/bin`)
- `DEBUG=1` - Enable debug output during installation
- `VERIFY_SIGNATURES=false` - Disable signature verification (not recommended)

#### Non-Interactive Installation

For CI/CD or automated environments where no TTY is available, set these variables to bypass interactive prompts:

- `GIT_USER_NAME="Your Name"` - Git user name for commits
- `GIT_USER_EMAIL="your.email@example.com"` - Git user email for commits

Example for CI environments:

```bash
GIT_USER_NAME="CI User" GIT_USER_EMAIL="ci@example.com" ./install.sh
```

For a complete list of options, run `./install.sh --help`.

## Pi terminal title

The personal extension in `home/dot_pi/private_agent/extensions/terminal-title.ts`
shows `π ⠏ working | 42% | model xhigh | session name` (or `π ready` when
settled). The working spinner uses Pi's default frames and 80 ms cadence. Reasoning
models show their current effort level, which updates when you cycle it.
Blocking extension questions and confirmations alternate `[.]` / `[!]` until
answered or cancelled. Plain-text questions are not guessed from assistant prose.
Context is percent used; `?%` means unknown, such as immediately after compaction.
Unnamed sessions use the directory name. Run `/reload` in Pi after applying it.

The sandboxed TUI integration test runs with `bats test/pi-terminal-title.bats`
and requires an installed Pi and Python 3; it never calls a real model provider.

## Pi PR session names

[pi-pr-session-title](https://github.com/lepht/pi-pr-session-title) detects PR
references in prompts (`PR 123`, `pull request 123`, `#123`, or GitHub PR URLs)
and looks up the title with `gh`. `home/.chezmoiexternals/pi.externals.toml` pins
its unmodified source and MIT license to a commit; Renovate updates both pins.
The local `pr-session-title/index.ts` wrapper formats native session names as
`pinwheel#123 — fix login race conditions`, which the terminal title displays too.
It lowercases the PR subject and keeps at most five words, without another model
request. Short subjects stay short; conventional-commit scopes are removed.

Manual names win, including names set while a lookup is pending. Failed lookups
leave the session unnamed. Detection uses prompt references, not the current
branch's PR. Bare numbers need a GitHub checkout; URL references work anywhere.

Apply `~/.pi/agent/extensions/pr-session-title` and run `/reload` in Pi. After
applying, `bats test/pi-pr-session-title.bats test/pi-terminal-title.bats` exercises
real Pi sessions and titles with a fake `gh` and an offline model provider. To test
without installing the external, set `PI_PR_SESSION_TITLE_UPSTREAM` to a local copy
of the pinned source. Tests themselves never download dependencies or call GitHub.

## License

This project is open source under the [ISC License](LICENSE.md), credited to Ivy Evans, Martin Emde.
