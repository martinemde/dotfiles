---
name: managing-chezmoi-packages
description: Use this skill when managing packages, external dependencies, binaries, or CLI tools in a chezmoi dotfiles repository. Handles adding/updating/removing packages in .chezmoidata/packages.yaml, creating .chezmoiexternals/ organized files, pinning versions with Renovate automation, and selecting the correct package ecosystem (Homebrew, mise, Python, Docker, chezmoi externals).
---

# Managing Chezmoi Packages

This skill handles all aspects of package and dependency management in chezmoi dotfiles repositories, with emphasis on security, reproducibility, and automated updates.

## Core Principles

1. **Version Pinning**: Always pin to immutable references (commit SHAs, specific versions, digests)
2. **Renovate Automation**: Ensure all dependencies have corresponding Renovate rules
3. **Organization**: Group externals by primary program using `.chezmoiexternals/` directory
4. **Minimal Edits**: Make focused changes without unrelated modifications
5. **Preview First**: Show proposed changes before applying

## When to Use This Skill

Invoke this skill when the user requests:

- Adding/updating/removing packages or tools
- Managing chezmoi external dependencies
- Pinning versions or updating SHAs
- Organizing external files by program
- Setting up Renovate automation for dependencies
- Choosing between package ecosystems (Homebrew, mise, etc.)

## Workflow

### 1. Identify the Request

Determine what the user wants:

- **Add**: New package or external dependency
- **Update**: Change version/SHA of existing package
- **Remove**: Delete package or external
- **Organize**: Migrate externals to `.chezmoiexternals/` structure
- **Pin**: Add immutable version/SHA reference

### 2. Select the Ecosystem

Choose the appropriate package manager (see `./ecosystem-guide.md` for details):

| Use Case                  | Ecosystem         | Location                                                 |
| ------------------------- | ----------------- | -------------------------------------------------------- |
| macOS packages (Homebrew) | brew/cask/mas     | `home/.chezmoidata/packages.yaml`                        |
| CLI developer tools       | mise (Aqua)       | `.mise.toml` or `home/dot_config/mise/config.toml`       |
| Python tools              | pip               | `home/dot_config/dotfiles/requirements.txt`              |
| Docker/devcontainer       | docker            | `home/dot_config/docker-compose/*.yml`, `.devcontainer/` |
| External files/repos      | chezmoi externals | `home/.chezmoiexternals/*.toml[.tmpl]`                   |
| Install script CLIs       | cli-versions      | `home/dot_config/dotfiles/cli-versions.toml`             |

### 3. For Chezmoi Externals: Use .chezmoiexternals/ Directory

**IMPORTANT**: Organize externals by primary program using the `.chezmoiexternals/` directory structure.

#### Directory Structure

```
home/.chezmoiexternals/
├── zsh.externals.toml      # Zsh plugins and tools
├── bat.externals.toml      # Bat themes and syntaxes
├── tmux.externals.toml     # Tmux configurations
└── nvim.externals.toml     # Neovim plugins
```

#### How It Works

- Files in `home/.chezmoiexternals/` are treated as `.chezmoiexternal.<format>` files
- Each file defines externals for a specific program
- Use `.tmpl` suffix for templating support (OS conditionals, variables)
- Paths in each file are relative to the home directory

#### Example: zsh.externals.toml

```toml
{{ if lookPath "zsh" }}
# Zsh plugins and tools
[".zsh/znap/zsh-snap"]
type = "git-repo"
url = "https://github.com/marlonrichert/zsh-snap.git"
revision = "25754a45d9ceafe6d7d082c9ebe40a08cb85a4f0"
refreshPeriod = "168h"

[".zsh/plugins/zsh-autosuggestions"]

{{ end }}type = "git-repo"
url = "https://github.com/zsh-users/zsh-autosuggestions.git"
revision = "85919cd1ffa7d2d5412f6d3fe437ebdbeeec4fc5"
refreshPeriod = "168h"
```

### 4. External Types and Patterns

Chezmoi supports four external types (detailed in `./externals-reference.md`):

#### git-repo

For complete Git repositories (plugins, frameworks):

```toml
[".zsh/plugins/plugin-name"]
type = "git-repo"
url = "https://github.com/user/repo.git"
revision = "<commit-sha>"                # MUST pin to SHA
refreshPeriod = "168h"
```

#### file

For single files (themes, configs):

```toml
[".config/tool/theme.tmTheme"]
type = "file"
url = "https://github.com/user/repo/raw/<commit-sha>/file.ext"
refreshPeriod = "168h"
```

#### archive-file

For extracting single binary from release archive:

```toml
[".local/bin/tool"]
type = "archive-file"
url = "https://github.com/user/repo/releases/download/v1.2.3/tool.tar.gz"
executable = true
path = "tool"
checksum = "sha256:abc123..."
```

#### archive

For extracting entire archive into directory:

```toml
[".config/tool"]
type = "archive"
url = "https://github.com/user/repo/archive/<commit-sha>.tar.gz"
exact = true
stripComponents = 1
refreshPeriod = "168h"
```

### 5. Version Pinning Requirements

**CRITICAL**: Always use immutable references:

| Type           | Pinning Method           | Example                              |
| -------------- | ------------------------ | ------------------------------------ |
| Git repo       | Commit SHA in `revision` | `revision = "abc123..."`             |
| GitHub file    | Commit SHA in URL path   | `raw/<sha>/file.ext`                 |
| Release binary | Version tag + checksum   | `v1.2.3` + `checksum = "sha256:..."` |
| Docker image   | Digest                   | `image:tag@sha256:...`               |

**NEVER use**:

- `latest` tags
- Mutable branch names without SHA pinning
- Version ranges or wildcards
- URLs without commit SHAs or checksums

### 6. Ensure Renovate Integration

For each external dependency, verify or add corresponding Renovate rule in `renovate.json5`.

See `./renovate-integration.md` for detailed patterns.

**Quick reference**:

```json5
{
  customType: 'regex',
  fileMatch: ['^home/\\.chezmoiexternals/.*\\.toml(\\.tmpl)?$'],
  matchStrings: [
    'revision = "(?<currentDigest>[a-f0-9]{40})".*?# renovate: repo=(?<depName>.*?) branch=(?<currentValue>.*?)\\n',
  ],
  datasourceTemplate: 'git-refs',
}
```

### 7. Apply Changes

#### For .chezmoiexternals/ files

1. **Create or update** the appropriate `.externals.toml` file
2. **Add comments** explaining each dependency
3. **Include Renovate annotations** for tracking:
   ```toml
   # renovate: repo=user/repo branch=main
   [".path/to/dependency"]
   type = "git-repo"
   url = "https://github.com/user/repo.git"
   revision = "<commit-sha>"
   ```

#### For packages.yaml

1. **Edit** `home/.chezmoidata/packages.yaml`
2. **Add to appropriate section** (darwin/linux, brews/casks/mas)
3. **Follow existing patterns**

### 8. Verification Commands

**Preview changes**:

```bash
chezmoi diff
```

**Check external URLs**:

```bash
# Verify latest commit SHA
gh api repos/USER/REPO/commits/BRANCH --jq .sha

# Check latest release tag
gh api repos/USER/REPO/releases/latest --jq .tag_name

# Verify file exists at SHA
curl -fsSL https://github.com/USER/REPO/raw/SHA/path/to/file
```

**Apply changes**:

```bash
chezmoi apply
```

**Test external updates**:

```bash
chezmoi update --force
```

## Common Workflows

### Adding a New Zsh Plugin

```bash
# 1. Get latest commit SHA
gh api repos/zsh-users/zsh-history-substring-search/commits/master --jq .sha

# 2. Add to home/.chezmoiexternals/zsh.externals.toml
# 3. Add Renovate rule to renovate.json5
# 4. Preview and apply
chezmoi diff
chezmoi apply
```

### Adding a Homebrew Package

```bash
# 1. Edit home/.chezmoidata/packages.yaml
# 2. Add to appropriate section (brews/casks)
# 3. Renovate will track automatically (homebrew datasource)
```

### Migrating Existing Externals to .chezmoiexternals/

1. **Identify program groupings** in `home/.chezmoiexternal.toml`
2. **Search for references** to the old file before migration:
   ```bash
   grep -r "\.chezmoiexternal\.toml\.tmpl" home/
   ```
   Common references to fix:
   - Scripts using `{{ include ".chezmoiexternal.toml" }}` for hashing
   - Documentation or comments mentioning the file
3. **Create program-specific files** in `home/.chezmoiexternals/`
4. **Move related externals** to appropriate file
5. **Update any references** found in step 2 to point to new files (e.g., `.chezmoiexternals/bat.externals.toml`)
6. **Keep conditionals** (e.g., `{{ if lookPath "zsh" }}`)
7. **Verify with** `chezmoi diff` (will error if references are broken)
8. **Remove old file** only after all references are updated and `chezmoi diff` succeeds

### Updating External to Latest SHA

```bash
# 1. Fetch current SHA
gh api repos/USER/REPO/commits/BRANCH --jq .sha

# 2. Update revision in .chezmoiexternals/*.toml
# 3. Apply
chezmoi apply
```

## Output Format

When making changes, provide:

```
Decision:
- Ecosystem: <brew|mise|python|docker|chezmoi-external|cli-versions>
- Rationale: <1-2 sentences>
- Organization: <which .chezmoiexternals/ file or other manifest>

Files To Edit:
- <path1>
- <path2>

Proposed Changes:
<concise diff-like hunks showing additions/modifications>

Renovate Integration:
- Rule Status: <exists|needs-addition|needs-update>
- Pattern: <brief description of regex or datasource>

Verification Commands:
- chezmoi diff
- <optional gh api commands to verify versions>

Next Steps:
- [ ] Review proposed changes
- [ ] Preview with chezmoi diff
- [ ] Apply with chezmoi apply
```

## Important Constraints

- **Never execute** package managers without explicit permission
- **Always preview** with `chezmoi diff` before applying
- **Use minimal edits**: Change only what's necessary
- **Maintain comments**: Explain why each dependency exists
- **Follow patterns**: Match existing style and structure
- **Version pinning**: No mutable references

## Platform-Specific Handling

Use Go templates for platform-specific externals:

```toml
{{ if eq .chezmoi.os "darwin" }}
[".local/bin/tool-mac"]

{{ else if eq .chezmoi.os "linux" }}
type = "archive-file"
url = "https://github.com/user/tool/releases/download/v1.0.0/tool-darwin-{{ .chezmoi.arch }}.tar.gz"
executable = true
[".local/bin/tool-linux"]

{{ end }}type = "archive-file"
url = "https://github.com/user/tool/releases/download/v1.0.0/tool-linux-{{ .chezmoi.arch }}.tar.gz"
executable = true
```

## Troubleshooting

**External fails to download**:

- Verify URL accessibility: `curl -fsSL <url>`
- Check commit SHA exists: `gh api repos/USER/REPO/commits/SHA`
- Review chezmoi logs: `chezmoi apply -v`

**Renovate not detecting dependency**:

- Verify regex pattern matches your format
- Check fileMatch glob is correct
- Test regex: use online regex tester with actual file content
- Ensure annotations are present if required

**Checksum mismatch**:

- Download file and compute SHA: `curl -fsSL <url> | shasum -a 256`
- Update checksum in external definition
- Verify URL points to correct version

## Best Practices

1. **Group by program**: Use `.chezmoiexternals/PROGRAM.externals.toml`
2. **Document dependencies**: Add comments explaining purpose
3. **Annotate for Renovate**: Include `# renovate:` comments
4. **Use templates**: Leverage `{{ if }}` for conditional installs
5. **Set refreshPeriod**: Balance freshness vs. performance (168h = weekly)
6. **Test on clean machine**: Verify externals work from scratch
7. **Pin everything**: No mutable references, ever

## Reference Documentation

- `./externals-reference.md` - Complete external type specifications
- `./renovate-integration.md` - Renovate automation patterns
- `./ecosystem-guide.md` - Package manager selection guide
