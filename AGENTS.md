# CLAUDE.md

Guidance for Claude Code when working with this dotfiles repository.

## Overview

Personal dotfiles managed by Chezmoi across macOS, Linux, and containers. Prioritizes stability, portability, and reliability.

## Installation and Setup

### Initial Installation

```bash
# Clone and install dotfiles
git clone https://github.com/ivy/dotfiles.git && cd dotfiles && ./install.sh

# Force reinstall tools if needed
REINSTALL_TOOLS=true ./install.sh

# Pass arguments to chezmoi init
./install.sh -- --force          # Force overwrite existing files
./install.sh -- --one-shot       # Use chezmoi one-shot mode
```

### Environment Variables

- `REINSTALL_TOOLS=true` - Force tool reinstallation
- `BIN_DIR=/custom/path` - Binary install dir (default: `~/.local/bin`)
- `DEBUG=1` - Debug output
- `VERIFY_SIGNATURES=false` - Disable signature verification

## Subagent Routing: Packages, Images, Versions

**Invoke Package Manager subagent before editing:**

- Docker Compose (image tags/digests)
- Devcontainer images/features
- Mise tool declarations (.mise.toml, home/dot_config/mise/config.toml)
- Homebrew/cask/mas packages
- Python requirements (home/dot_config/dotfiles/requirements.txt)
- Chezmoi externals (home/.chezmoiexternal.toml.tmpl)
- Version manifests (home/dot_config/dotfiles/\*.toml)
- GitHub Actions versions/digests

Why: Enforces immutable pins (versions/digests/SHAs) and maintains Renovate automation. Direct edits risk drift, broken automation, or security issues. See doc/renovate.md.

## Architecture

### Chezmoi Structure

- **Source**: Repository root (`sourceDir = "{{ .chezmoi.workingTree }}"`)
- **Templates**: `.tmpl` files processed by template engine
- **Scripts**: `run_onchange_*` execute on content change
- **Dotfiles**: `dot_` prefix becomes `.` (e.g., `dot_zshrc` → `.zshrc`)

### Key Directories

- `home/` - Managed dotfiles/config
- `home/dot_config/` - XDG config
- `home/dot_config/zsh/functions/` - Zsh autoload functions (one function per file)
- `home/dot_local/bin/` - User binaries
- `home/private_Library/` - Private macOS files (Cursor, etc.)
- `test/` - BATS tests
- `bin/` - Utility scripts

### Templates

Go text/template syntax. Key variables: `.chezmoi.os`, `.chezmoi.workingTree`, `.packages.darwin.*`

## CRITICAL: Edit Source Files Only

**ALWAYS edit `home/` source files, NEVER `~/` installed target files.**

- **DO**: `home/dot_config/nvim/...`
- **DON'T**: `~/.config/nvim/...`

Chezmoi copies `home/` to `~/`. Edits to `~/` are overwritten on next apply.

Apply changes: `chezmoi diff` (preview), `chezmoi apply [target_path]` (apply)

## Testing

Run tests: `bats test/` (all), `bats test/file.bats` (specific), `bats -t test/` (verbose)

Uses BATS with `test_helper.bash` utilities. Validates templates and script syntax. Helpers: `assert_valid_shell()`, `assert_script_structure()`

## Development Workflow

1. Edit `home/` files (`.tmpl` processed by Chezmoi)
2. For packages/images/versions: consult Package Manager subagent first
3. Preview: `chezmoi diff`, apply: `chezmoi apply`
4. Commit with Conventional Commits: `feat:`, `fix:`, `chore:`

### Adding Dotfiles

- Place in `home/` with `dot_` prefix
- Use `dot_config/` for XDG dirs
- Use `private_` for secrets

### Script Guidelines

- Idempotent with error handling (`set -o errexit -o nounset`)
- Support DEBUG variable
- Check tool availability first

### Node.js Package Management

- **ALWAYS use `bun` for package operations** (install, add, remove, run)
- Never use `npm` or `yarn` commands
- Examples: `bun install`, `bun add <package>`, `bun run <script>`

### Formatting

- **Prettier** is managed via root `package.json` (not mise) to enable plugin support
- Run `bun run format` to format all files
- Run `bun run format:check` to verify formatting
- Configuration in `.prettierrc.json`
- Exclusions in `.prettierignore` (especially `.tmpl` files)

## Security

**Signature Verification**: Installer uses cosign by default. Verifies GitHub releases; fallback to checksums. Disable with `VERIFY_SIGNATURES=false` (not recommended).

**Private Files**: `private_` prefix excluded from public tracking. Chezmoi encrypts in source state. Contains API keys, personal data.

## Troubleshooting

**Common Issues**:

- Tools not in PATH: Add `~/.local/bin` to PATH
- Template errors: Check syntax/variables
- Permissions: Run installer with proper permissions
- Signature failures: Check connectivity or disable verification

**Debug**: `DEBUG=1 ./install.sh` or `DEBUG=1 chezmoi apply -v`

## Documentation Guidelines

Documentation in `docs/` captures **why** decisions were made, not **what** the code does. Amend documentation on changes when solving a problem.

### What to Include

- **Problem being solved**: What issue prompted the change?
- **Design decisions**: Why this approach over alternatives?
- **Sources**: What influenced the design? (links, references)
- **Trade-offs**: What was explicitly excluded or avoided?

### What to Exclude

- Feature documentation (that belongs in code comments or READMEs)
- Implementation details (code is self-documenting)
- Promotional language (this is just for me)
- Basic usage instructions (unless design-relevant)
- Redundant information available elsewhere (these aren't tool docs)

### Style

- Concise, technical markdown
- Get straight to the point
- Use lists and short paragraphs
- Code examples only when illustrating design choices
