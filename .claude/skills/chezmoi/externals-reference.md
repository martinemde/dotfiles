# Chezmoi External Format Reference

Complete specification for chezmoi external dependencies. Externals allow you to include files, archives, and Git repositories from external sources in your dotfiles.

## Overview

Externals are defined in:

- **Legacy**: `home/.chezmoiexternal.<format>` (single file for all externals)
- **Recommended**: `home/.chezmoiexternals/*.toml[.tmpl]` (organized by program)

Files in `.chezmoiexternals/` are automatically treated as external definitions relative to the source directory.

## External Types

### 1. git-repo

Clones or updates a Git repository to a target directory.

**Best for**: Plugin managers, frameworks, complete configurations

**Required fields**:

- `type = "git-repo"`
- `url` - Repository URL (HTTPS or SSH)

**Optional fields**:

- `revision` - Specific commit SHA, tag, or branch (CRITICAL: always use commit SHA)
- `clone.args` - Additional git clone arguments
- `pull.args` - Additional git pull arguments
- `refreshPeriod` - How often to check for updates (e.g., "168h")

**Example**:

```toml
[".zsh/plugins/zsh-autosuggestions"]
type = "git-repo"
url = "https://github.com/zsh-users/zsh-autosuggestions.git"
revision = "85919cd1ffa7d2d5412f6d3fe437ebdbeeec4fc5"        # Pin to SHA
refreshPeriod = "168h"                                       # Update weekly
```

**Security**: Always pin `revision` to a commit SHA for reproducibility.

### 2. file

Downloads a single file from a URL.

**Best for**: Configuration files, themes, single scripts

**Required fields**:

- `type = "file"`
- `url` or `urls` - Download location(s)

**Optional fields**:

- `executable` - Make file executable (boolean)
- `checksum` - SHA-256/384/512 hash for verification
- `refreshPeriod` - How often to re-download
- `encrypted` - Handle encrypted content (boolean)

**Example**:

```toml
[".config/bat/themes/Catppuccin-mocha.tmTheme"]
type = "file"
url = "https://github.com/catppuccin/bat/raw/6810349b28055dce54076712fc05fc68da4b8ec0/themes/Catppuccin%20Mocha.tmTheme"
refreshPeriod = "168h"
```

**With checksum**:

```toml
[".local/bin/tool"]
type = "file"
url = "https://example.com/releases/v1.0.0/tool"
executable = true
checksum = "sha256:abc123def456..."
```

**Security**: Use commit SHA in URL path for GitHub files.

### 3. archive-file

Extracts a specific file from an archive (tar.gz, zip, etc.).

**Best for**: Release binaries, single files within archives

**Required fields**:

- `type = "archive-file"`
- `url` or `urls` - Archive download location
- `path` - Path to file within archive

**Optional fields**:

- `executable` - Make extracted file executable
- `checksum` - Archive checksum verification
- `refreshPeriod` - Update frequency

**Example**:

```toml
[".local/bin/zellij"]
type = "archive-file"
url = "https://github.com/zellij-org/zellij/releases/download/v0.40.0/zellij-x86_64-apple-darwin.tar.gz"
executable = true
path = "zellij"
checksum = "sha256:1234567890abcdef..."
refreshPeriod = "168h"
```

**With platform detection**:

```toml
{{ $arch := .chezmoi.arch -}}
{{ if eq .chezmoi.os "darwin" }}
[".local/bin/tool"]

{{ end }}type = "archive-file"
url = "https://github.com/user/tool/releases/download/v1.0.0/tool-darwin-{{ $arch }}.tar.gz"
executable = true
path = "tool"
```

**Security**: Always include `checksum` for release binaries.

### 4. archive

Extracts an entire archive into a target directory.

**Best for**: Complete directory structures, multi-file configurations

**Required fields**:

- `type = "archive"`
- `url` or `urls` - Archive download location

**Optional fields**:

- `exact` - Remove files not in archive (boolean)
- `stripComponents` - Strip leading path components (integer)
- `include` - Only extract matching patterns (array)
- `exclude` - Skip matching patterns (array)
- `format` - Force specific archive format
- `checksum` - Archive verification
- `refreshPeriod` - Update frequency

**Example - Full directory**:

```toml
[".oh-my-zsh"]
type = "archive"
url = "https://github.com/ohmyzsh/ohmyzsh/archive/abc123def456.tar.gz"
exact = true
stripComponents = 1
refreshPeriod = "168h"
```

**Example - With filtering**:

```toml
[".config/tool"]
type = "archive"
url = "https://github.com/user/tool/archive/commit-sha.tar.gz"
stripComponents = 1
include = ["config/**", "themes/**"]
exclude = ["**/*.md", "docs/**"]
```

**Security**: Use commit SHA in URL for GitHub archives.

## Common Fields

### url vs urls

- **url**: Single download location (string)
- **urls**: Multiple locations with fallback (array)

```toml
# Single URL
url = "https://github.com/user/repo/archive/sha.tar.gz"

# Multiple URLs (tries in order)
urls = [
  "https://cdn.example.com/file.tar.gz",
  "https://github.com/user/repo/releases/download/v1.0.0/file.tar.gz",
]
```

### checksum

Verify download integrity with SHA hash:

```toml
checksum = "sha256:abc123def456..."
checksum = "sha384:abc123def456..."
checksum = "sha512:abc123def456..."
```

**Generate checksum**:

```bash
curl -fsSL <url> | shasum -a 256
```

### refreshPeriod

Control how often chezmoi checks for updates:

```toml
refreshPeriod = "24h"  # Daily
refreshPeriod = "168h" # Weekly (recommended for most externals)
refreshPeriod = "720h" # Monthly
```

Format: Duration string (h=hours, m=minutes, s=seconds)

### executable

Make file executable after download:

```toml
executable = true  # chmod +x
executable = false # default, no change
```

### exact

For `archive` type, remove files not present in archive:

```toml
exact = true  # Keep directory in sync with archive
exact = false # default, preserve existing files
```

## Templating

Use Go templates for dynamic configuration:

### OS Detection

```toml
{{ if eq .chezmoi.os "darwin" }}
[".config/tool-mac"]

{{ else if eq .chezmoi.os "linux" }}
type = "file"
url = "https://example.com/tool-mac"
[".config/tool-linux"]

{{ end }}type = "file"
url = "https://example.com/tool-linux"
```

### Conditional Installation

```toml
{{ if lookPath "zsh" }}
[".zsh/plugins/plugin"]

{{ end }}type = "git-repo"
url = "https://github.com/user/plugin.git"
```

### Architecture Detection

```toml
{{ $arch := .chezmoi.arch -}}
[".local/bin/tool"]
type = "archive-file"
url = "https://github.com/user/tool/releases/download/v1.0.0/tool-{{ .chezmoi.os }}-{{ $arch }}.tar.gz"
executable = true
path = "tool"
```

### Variables from .chezmoidata

```toml
{{ $packages := .packages.externals -}}
{{ range $packages }}
[".local/bin/{{ .name }}"]

{{ end }}type = "archive-file"
url = "{{ .url }}"
executable = true
```

## Version Pinning Strategies

### Git Repositories

**ALWAYS use commit SHA** in `revision`:

```toml
# CORRECT
[".zsh/plugins/plugin"]
type = "git-repo"
url = "https://github.com/user/plugin.git"
revision = "abc123def456..."               # 40-character SHA

# WRONG - mutable reference
[".zsh/plugins/plugin"]
type = "git-repo"
url = "https://github.com/user/plugin.git"
revision = "main"                          # Branch can change!
```

### GitHub Raw Files

**Include commit SHA in URL path**:

```toml
# CORRECT
url = "https://github.com/user/repo/raw/abc123def456.../file.ext"

# WRONG - uses mutable branch
url = "https://github.com/user/repo/raw/main/file.ext"
```

### GitHub Archives

**Use commit SHA in archive URL**:

```toml
# CORRECT
url = "https://github.com/user/repo/archive/abc123def456....tar.gz"

# WRONG - uses mutable branch
url = "https://github.com/user/repo/archive/main.tar.gz"
```

### Release Binaries

**Pin version tag AND include checksum**:

```toml
# CORRECT - version + checksum
url = "https://github.com/user/tool/releases/download/v1.2.3/tool.tar.gz"
checksum = "sha256:abc123..."

# WRONG - no checksum
url = "https://github.com/user/tool/releases/download/latest/tool.tar.gz"
```

## Archive Formats

Chezmoi automatically detects and extracts:

- `.tar.gz`, `.tgz` - gzip compressed tar
- `.tar.bz2`, `.tbz2` - bzip2 compressed tar
- `.tar.xz`, `.txz` - xz compressed tar
- `.tar.zst` - zstd compressed tar
- `.zip` - ZIP archives

Force specific format:

```toml
format = "tar.gz"
format = "zip"
```

## stripComponents

Remove leading directory components from archive paths:

```toml
# Archive structure:
# repo-abc123/
#   config/
#     file.conf

[".config/tool"]
type = "archive"
url = "https://github.com/user/repo/archive/abc123.tar.gz"
stripComponents = 1                                        # Removes "repo-abc123/" prefix
# Result: .config/tool/config/file.conf
```

## include/exclude Patterns

Filter archive extraction:

```toml
[".config/tool"]
type = "archive"
url = "..."
include = [
  "config/**",     # Include all files in config/
  "themes/*.json", # Include JSON themes
]
exclude = [
  "**/*.md",    # Skip markdown files
  "**/test/**", # Skip test directories
  "docs/**",    # Skip documentation
]
```

Patterns use glob syntax:

- `*` - matches anything except /
- `**` - matches anything including /
- `?` - matches single character
- `[abc]` - matches a, b, or c

## Best Practices

1. **Always pin versions**: Use commit SHAs for git repos, include checksums for files
2. **Use .chezmoiexternals/**: Organize by program (zsh, bat, tmux, nvim, etc.)
3. **Set refreshPeriod**: Balance between freshness and performance (168h recommended)
4. **Add comments**: Explain what each external is and why it's included
5. **Template conditionally**: Use `{{ if lookPath "tool" }}` to skip on missing dependencies
6. **Verify checksums**: Always include for release binaries and archives
7. **Test extraction**: Run `chezmoi apply --dry-run` before committing
8. **Document sources**: Add comments with upstream repo and purpose

## Troubleshooting

### External not downloading

```bash
# Check URL accessibility
curl -fsSL <url> -o /tmp/test-download

# Verify commit SHA exists
gh api repos/USER/REPO/commits/SHA

# Check chezmoi logs
chezmoi apply -v
```

### Checksum mismatch

```bash
# Calculate correct checksum
curl -fsSL <url> | shasum -a 256

# Update in external definition
checksum = "sha256:<new-hash>"
```

### Archive extraction fails

```bash
# Test archive manually
curl -fsSL <url> | tar -tzf -  # List contents
curl -fsSL <url> | tar -xzf - -C /tmp  # Extract to temp

# Check stripComponents value
# Count directory levels in archive paths
```

### Template errors

```bash
# Preview template output
chezmoi cat home/.chezmoiexternals/program.externals.toml

# Check data variables
chezmoi data
```

## Examples from Repository

### Zsh Plugin (git-repo)

```toml
[".zsh/plugins/zsh-autosuggestions"]
type = "git-repo"
url = "https://github.com/zsh-users/zsh-autosuggestions.git"
revision = "85919cd1ffa7d2d5412f6d3fe437ebdbeeec4fc5"
refreshPeriod = "168h"
```

### Bat Theme (file)

```toml
[".config/bat/themes/Catppuccin Mocha.tmTheme"]
type = "file"
url = "https://github.com/catppuccin/bat/raw/6810349b28055dce54076712fc05fc68da4b8ec0/themes/Catppuccin%20Mocha.tmTheme"
refreshPeriod = "168h"
```

### Tmux Config (git-repo)

```toml
[".config/tmux/.tmux"]
type = "git-repo"
url = "https://github.com/gpakosz/.tmux.git"
revision = "23f6e11e65657406be2b2557148d831c631778d7"
refreshPeriod = "24h"
```

### Binary from Release (archive-file)

```toml
[".local/bin/zellij"]
type = "archive-file"
url = "https://github.com/zellij-org/zellij/releases/download/v0.40.0/zellij-x86_64-apple-darwin.tar.gz"
executable = true
path = "zellij"
checksum = "sha256:..."
refreshPeriod = "168h"
```
