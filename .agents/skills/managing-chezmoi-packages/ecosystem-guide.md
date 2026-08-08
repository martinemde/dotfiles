# Package Ecosystem Selection Guide

Decision framework for choosing the right package management approach in a chezmoi dotfiles repository.

## Decision Tree

```
Is it a package/tool to install?
├─ YES → Does it need to be installed system-wide?
│   ├─ YES → Is this macOS?
│   │   ├─ YES → Use Homebrew (.chezmoidata/packages.yaml)
│   │   └─ NO → Is this Linux?
│   │       ├─ YES → Use system package manager (apt/dnf) or Homebrew
│   │       └─ NO → Use appropriate OS package manager
│   └─ NO → Is it a CLI developer tool (language version manager, etc.)?
│       ├─ YES → Use mise (.mise.toml)
│       ├─ NO → Is it a Python tool (uv tool install)?
│       │   ├─ YES → Use Python requirements (requirements.txt)
│       │   └─ NO → Is it for containers/development environments?
│       │       ├─ YES → Use Docker/devcontainer configs
│       │       └─ NO → Consider chezmoi externals
└─ NO → Is it a file/directory/repo to download?
    └─ YES → Use chezmoi externals (.chezmoiexternals/)
```

## Ecosystem Comparison

| Ecosystem             | Best For                         | Location                                  | Renovate Support | Notes                        |
| --------------------- | -------------------------------- | ----------------------------------------- | ---------------- | ---------------------------- |
| **Homebrew**          | macOS packages, Linux packages   | `.chezmoidata/packages.yaml`              | Built-in         | System-wide installation     |
| **mise**              | CLI dev tools, language runtimes | `.mise.toml`                              | Custom regex     | Per-project or global        |
| **Python/uv**         | Python CLI tools                 | `requirements.txt`                        | Built-in         | Isolated Python environments |
| **Docker**            | Container images                 | `docker-compose.yml`, `devcontainer.json` | Built-in         | Development environments     |
| **Chezmoi Externals** | Files, archives, Git repos       | `.chezmoiexternals/*.toml`                | Custom regex     | Dotfiles, configs, plugins   |
| **CLI Versions**      | Script-installed CLIs            | `cli-versions.toml`                       | Custom regex     | Install script dependencies  |

## Detailed Ecosystem Guides

### 1. Homebrew (brew/cask/mas)

**When to use**:

- macOS GUI applications (casks)
- macOS/Linux CLI tools available in Homebrew
- Mac App Store applications (mas)
- System-level packages

**Location**: `home/.chezmoidata/packages.yaml`

**Format**:

```yaml
packages:
  darwin:
    brews:
      - git
      - node
      - python
    casks:
      - google-chrome
      - visual-studio-code
      - docker
    mas:
      - 497799835 # Xcode (App Store ID)
```

**Installation**: Run script `run_onchange_darwin-install-packages.sh.tmpl`

**Renovate**: Built-in support via `homebrew` datasource

**Pros**:

- Extensive package catalog
- System-wide availability
- Automatic updates via Homebrew
- Well-maintained formulas

**Cons**:

- macOS/Linux only
- Requires admin permissions
- System-wide (can conflict)
- Slower than binary downloads

**Example**:

```yaml
packages:
  darwin:
    brews:
      - gh # GitHub CLI
      - jq # JSON processor
      - ripgrep # Fast grep
    casks:
      - cursor # AI code editor
      - wezterm # Terminal emulator
```

### 2. Mise (Aqua-based)

**When to use**:

- CLI developer tools (not in Homebrew)
- Language version managers
- Project-specific tool versions
- Tools from GitHub releases

**Location**: `.mise.toml` (global) or `home/dot_config/mise/config.toml` (managed)

**Format**:

```toml
[tools]
"aqua:mikefarah/yq" = "v4.47.1"
"aqua:cli/cli" = "v2.63.2"
node = "20.11.0"
python = "3.12.1"
```

**Installation**: mise automatically installs on tool use or via `mise install`

**Renovate**: Custom regex manager for aqua-prefixed tools

**Pros**:

- Fast binary installations
- Per-project versions
- No admin permissions needed
- Extensive tool support via Aqua registry

**Cons**:

- Requires mise installed
- Less familiar than Homebrew
- Some tools may not be available

**Example**:

```toml
[tools]
"aqua:junegunn/fzf" = "v0.57.0"
"aqua:sharkdp/bat" = "v0.24.0"
"aqua:BurntSushi/ripgrep" = "v14.1.1"
terraform = "1.7.0"
kubectl = "1.29.1"
```

### 3. Python Requirements (uv tool install)

**When to use**:

- Python CLI tools (uv tool install)
- Python libraries and dependencies
- Tools best installed via pip

**Location**: `home/dot_config/dotfiles/requirements.txt`

**Format**:

```txt
black==24.1.1
ruff==0.2.0
poetry==1.7.1
```

**Installation**: Run script installing via uv tool install

**Renovate**: Built-in support via `pypi` datasource

**Pros**:

- Isolated Python environments (uv)
- Fast installation (Rust-based)
- Cross-platform
- Built-in Renovate support

**Cons**:

- Python-specific
- May require Python version management

**Example**:

```txt
# Code formatters
black==24.1.1
isort==5.13.2

# Linters
ruff==0.2.0
mypy==1.8.0

# CLI tools
claude-code-transcripts==0.5
gitingest==0.3.1
```

### 4. Docker / Devcontainer

**When to use**:

- Container images for development
- Devcontainer features
- Docker Compose services
- Isolated development environments

**Location**:

- `home/dot_config/docker-compose/*.yml`
- `.devcontainer/devcontainer.json`

**Format**:

```yaml
# docker-compose.yml
services:
  postgres:
    image: postgres:16-alpine@sha256:abc123...
    ports:
      - '5432:5432'
```

```json
// devcontainer.json
{
  "image": "mcr.microsoft.com/devcontainers/base:ubuntu@sha256:abc123...",
  "features": {
    "ghcr.io/devcontainers/features/node:1": {
      "version": "20"
    }
  }
}
```

**Renovate**: Built-in support for Docker images and devcontainer features

**Pros**:

- Complete isolation
- Reproducible environments
- Cross-platform
- Built-in Renovate support

**Cons**:

- Requires Docker
- Can be resource-intensive
- Slower startup times

**Example**:

```yaml
services:
  redis:
    image: redis:7-alpine@sha256:abc123...

  postgres:
    image: postgres:16-alpine@sha256:def456...
    environment:
      POSTGRES_PASSWORD: dev
```

### 5. Chezmoi Externals

**When to use**:

- Shell/editor plugins
- Configuration frameworks
- Theme files
- Binaries from GitHub releases
- Any file/directory to download

**Location**: `home/.chezmoiexternals/*.toml.tmpl`

**Format**:

```toml
# zsh.externals.toml
[".zsh/plugins/zsh-autosuggestions"]
type = "git-repo"
url = "https://github.com/zsh-users/zsh-autosuggestions.git"
revision = "abc123..."
refreshPeriod = "168h"

[".local/bin/tool"]
type = "archive-file"
url = "https://github.com/user/tool/releases/download/v1.0.0/tool.tar.gz"
executable = true
path = "tool"
```

**Installation**: Automatic via `chezmoi apply`

**Renovate**: Custom regex managers for each pattern

**Pros**:

- No package manager dependencies
- Flexible (files, archives, repos)
- Fast downloads with caching
- Works across all platforms

**Cons**:

- Manual Renovate setup
- No dependency resolution
- Requires careful version pinning

**Example**:

```toml
{{ if lookPath "zsh" }}
# zsh.externals.toml
[".zsh/znap/zsh-snap"]

{{ end }}type = "git-repo"
url = "https://github.com/marlonrichert/zsh-snap.git"
revision = "25754a45d9ceafe6d7d082c9ebe40a08cb85a4f0"
refreshPeriod = "168h"
```

### 6. CLI Versions (Install Script)

**When to use**:

- Tools installed by custom script
- Tools requiring special installation logic
- Cross-platform CLI tools
- Tools with signature verification

**Location**: `home/dot_config/dotfiles/cli-versions.toml`

**Format**:

```toml
cosign = "v2.5.3"
chezmoi = "v2.56.0"
mise = "v2024.1.0"
```

**Installation**: Install script reads versions and downloads/installs

**Renovate**: Custom regex manager

**Pros**:

- Custom installation logic
- Signature verification support
- Cross-platform consistency
- Centralized version management

**Cons**:

- Requires custom install script
- Manual Renovate setup
- More complex than other approaches

**Example**:

```toml
# CLI tools installed by script
cosign = "v2.5.3"
glab = "v1.37.0"
chezmoi = "v2.56.0"
```

## Selection Criteria

### By Tool Type

| Tool Type                             | Recommended Ecosystem | Alternative            |
| ------------------------------------- | --------------------- | ---------------------- |
| **System utility** (git, curl)        | Homebrew              | mise                   |
| **GUI application** (VS Code, Chrome) | Homebrew (cask)       | Manual install         |
| **CLI dev tool** (gh, jq, yq)         | mise                  | Homebrew               |
| **Language runtime** (Node, Python)   | mise                  | Homebrew               |
| **Python tool** (black, poetry)       | uv tool install       | mise                   |
| **Shell plugin**                      | Chezmoi externals     | Manual                 |
| **Editor plugin**                     | Chezmoi externals     | Editor package manager |
| **Config framework** (oh-my-zsh)      | Chezmoi externals     | Manual                 |
| **Theme file**                        | Chezmoi externals     | Manual                 |
| **Container image**                   | Docker                | N/A                    |

### By Platform

| Platform           | Primary         | Secondary                   | Notes                    |
| ------------------ | --------------- | --------------------------- | ------------------------ |
| **macOS**          | Homebrew + mise | Chezmoi externals           | Use casks for GUI apps   |
| **Linux**          | mise + apt/dnf  | Homebrew, Chezmoi externals | System packages for deps |
| **Containers**     | Docker + mise   | Chezmoi externals           | Minimal base image       |
| **Cross-platform** | mise            | Chezmoi externals           | Use mise for consistency |

### By Use Case

**System-wide tools** (git, ssh, bash):

- **Primary**: Homebrew (macOS), apt/dnf (Linux)
- **Why**: System integration, dependency management

**Development tools** (language runtimes, CLI utilities):

- **Primary**: mise
- **Why**: Version management, per-project control

**GUI applications** (browsers, editors, terminals):

- **Primary**: Homebrew casks (macOS)
- **Why**: Easy updates, standard installation

**Shell plugins** (zsh plugins, themes):

- **Primary**: Chezmoi externals
- **Why**: Dotfiles integration, version pinning

**Editor plugins** (vim, nvim plugins):

- **Primary**: Editor package manager (lazy.nvim, vim-plug)
- **Secondary**: Chezmoi externals (for manual installs)
- **Why**: Editor integration, dependency management

**Configuration frameworks** (oh-my-zsh, tmux configs):

- **Primary**: Chezmoi externals
- **Why**: Complete control, version pinning

**Binary releases** (GitHub release binaries):

- **Primary**: Chezmoi externals (archive-file)
- **Secondary**: mise (if in Aqua registry)
- **Why**: Direct download, checksum verification

## Migration Strategies

### From Homebrew to mise

**When**: Tool needs per-project versions or faster updates

1. Check if tool available in mise: `mise ls-remote <tool>`
2. Add to `.mise.toml`: `mise use <tool>@<version>`
3. Remove from `packages.yaml`
4. Test: `mise install`

### From Manual Install to Chezmoi Externals

**When**: Manually downloading files/repos regularly

1. Identify current version/SHA
2. Create appropriate `.chezmoiexternals/*.toml` file
3. Add external definition with pinned version
4. Add Renovate rule
5. Test: `chezmoi apply`
6. Remove manual install instructions

### From System Package to Homebrew

**When**: Need newer versions than system packages provide

1. Add to `packages.yaml` (brews section)
2. Create/update run script to install
3. Test on clean machine
4. Document in README

### From Python Global to uv

**When**: Want isolated Python tool environments

1. Add tool to `requirements.txt`
2. Update install script to use uv tool install
3. Test isolation: `uv tool list`
4. Remove global pip install

## Best Practices

1. **Minimize ecosystems**: Fewer systems = easier maintenance
2. **Prefer mise for CLI**: Fast, flexible, per-project versions
3. **Use Homebrew for GUI**: macOS applications via casks
4. **Externals for dotfiles**: Plugins, themes, configs
5. **Pin everything**: No mutable references anywhere
6. **Document choices**: Comment why each tool uses its ecosystem
7. **Test cross-platform**: Verify on macOS, Linux, containers
8. **Centralize versions**: Use ecosystem-specific manifests
9. **Automate updates**: Configure Renovate for all ecosystems
10. **Isolate environments**: Avoid global installations when possible

## Troubleshooting

### Tool in Multiple Ecosystems

**Problem**: Same tool available in Homebrew, mise, and externals

**Solution**: Choose based on use case:

- Need system integration? → Homebrew
- Need version management? → mise
- Just need binary? → Chezmoi externals

### Version Conflicts

**Problem**: System version conflicts with mise version

**Solution**:

1. Check PATH order: `echo $PATH`
2. Ensure mise shims come first
3. Use `mise which <tool>` to verify active version
4. Consider removing system version

### Installation Fails

**Problem**: Package manager can't install tool

**Solution**:

1. Check platform compatibility
2. Try alternative ecosystem
3. Fall back to manual install
4. Document workaround in README

### Slow Updates

**Problem**: Homebrew updates take too long

**Solution**:

1. Migrate CLI tools to mise
2. Keep only GUI apps in Homebrew
3. Use Homebrew bundle for batch updates
4. Consider Chezmoi externals for binaries

## Examples from Repository

### Current Setup

```yaml
# Homebrew (macOS GUI + system tools)
packages:
  darwin:
    brews: [git, gh, jq]
    casks: [cursor, wezterm, docker]
```

```toml
# mise (CLI developer tools)
[tools]
"aqua:mikefarah/yq" = "v4.47.1"
"aqua:junegunn/fzf" = "v0.57.0"
node = "20.11.0"
```

```toml
# Chezmoi externals (zsh plugins)
[".zsh/plugins/zsh-autosuggestions"]
type = "git-repo"
url = "https://github.com/zsh-users/zsh-autosuggestions.git"
revision = "85919cd1ffa7d2d5412f6d3fe437ebdbeeec4fc5"
```

This setup:

- Uses Homebrew for macOS-specific needs
- Uses mise for cross-platform CLI tools
- Uses chezmoi externals for shell plugins
- Minimizes overlap between ecosystems
- Enables Renovate automation across all

## Quick Reference

| Need            | Use              | Command                                               |
| --------------- | ---------------- | ----------------------------------------------------- |
| Add macOS app   | Homebrew cask    | Edit `packages.yaml`                                  |
| Add CLI tool    | mise             | `mise use <tool>@<version>`                           |
| Add zsh plugin  | Chezmoi external | Create in `.chezmoiexternals/zsh.externals.toml.tmpl` |
| Add Python tool | uv tool install  | Add to `requirements.txt`                             |
| Add binary      | Chezmoi external | Create in `.chezmoiexternals/` with type=archive-file |
| Update versions | Renovate         | Wait for PR or update manually                        |
| Preview changes | Chezmoi          | `chezmoi diff`                                        |
| Apply changes   | Chezmoi          | `chezmoi apply`                                       |
