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

## License

This project is open source under the [ISC License](LICENSE.md), credited to Ivy Evans.
