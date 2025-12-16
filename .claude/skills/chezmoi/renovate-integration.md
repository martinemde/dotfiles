# Renovate Integration for Chezmoi Externals

Automated dependency updates for chezmoi external definitions using Renovate's custom regex managers.

## Overview

Renovate can automatically detect and update:

- Git repository commit SHAs
- GitHub release versions and checksums
- File URLs with commit SHAs
- Archive URLs with commit SHAs

This document provides patterns and best practices for maintaining Renovate automation.

## Core Concept

For each external dependency, you need:

1. **Pinned reference** in external definition (commit SHA, version tag)
2. **Renovate rule** in `renovate.json5` to detect and update that reference
3. **Optional annotation** in external file to help Renovate identify the dependency

## Pattern Types

### 1. Git Repository with Revision (git-refs)

**Use case**: External using `type = "git-repo"` with `revision` field

**External format**:

```toml
# renovate: repo=marlonrichert/zsh-snap branch=main
[".zsh/znap/zsh-snap"]
type = "git-repo"
url = "https://github.com/marlonrichert/zsh-snap.git"
revision = "25754a45d9ceafe6d7d082c9ebe40a08cb85a4f0"
refreshPeriod = "168h"
```

**Renovate rule**:

```json5
{
  customType: 'regex',
  fileMatch: ['^home/\\.chezmoiexternals/.*\\.toml(\\.tmpl)?$'],
  matchStrings: [
    '# renovate: repo=(?<depName>.*?) branch=(?<currentValue>.*?)\\n.*?\\n.*?revision = "(?<currentDigest>[a-f0-9]{40})"',
  ],
  datasourceTemplate: 'git-refs',
}
```

**How it works**:

- `depName`: Repository path (e.g., `marlonrichert/zsh-snap`)
- `currentValue`: Branch name to track (e.g., `main`, `master`)
- `currentDigest`: Current commit SHA (40 hex chars)
- `datasource`: `git-refs` to fetch latest commit from branch

**Result**: Renovate will propose PRs updating the SHA when the branch advances.

### 2. GitHub Archive with Commit SHA (git-refs)

**Use case**: Archive URL containing commit SHA in path

**External format**:

```toml
# renovate: repo=ohmyzsh/ohmyzsh branch=master
[".oh-my-zsh"]
type = "archive"
url = "https://github.com/ohmyzsh/ohmyzsh/archive/abc123def456.tar.gz"
exact = true
stripComponents = 1
```

**Renovate rule**:

```json5
{
  customType: 'regex',
  fileMatch: ['^home/\\.chezmoiexternals/.*\\.toml(\\.tmpl)?$'],
  matchStrings: [
    '# renovate: repo=(?<depName>.*?) branch=(?<currentValue>.*?)\\n.*?url = "https://github\\.com/[^/]+/[^/]+/archive/(?<currentDigest>[a-f0-9]{40})\\.tar\\.gz"',
  ],
  datasourceTemplate: 'git-refs',
}
```

**Result**: Updates commit SHA in archive URL.

### 3. GitHub Raw File with Commit SHA (git-refs)

**Use case**: File URL with commit SHA in path

**External format**:

```toml
# renovate: repo=catppuccin/bat branch=main
[".config/bat/themes/Catppuccin-mocha.tmTheme"]
type = "file"
url = "https://github.com/catppuccin/bat/raw/6810349b28055dce54076712fc05fc68da4b8ec0/themes/Catppuccin%20Mocha.tmTheme"
```

**Renovate rule**:

```json5
{
  customType: 'regex',
  fileMatch: ['^home/\\.chezmoiexternals/.*\\.toml(\\.tmpl)?$'],
  matchStrings: [
    '# renovate: repo=(?<depName>.*?) branch=(?<currentValue>.*?)\\n.*?url = "https://github\\.com/[^/]+/[^/]+/raw/(?<currentDigest>[a-f0-9]{40})/',
  ],
  datasourceTemplate: 'git-refs',
}
```

**Result**: Updates commit SHA in raw file URL.

### 4. GitHub Release with Version Tag (github-releases)

**Use case**: Release binary with version tag in URL

**External format**:

```toml
[".local/bin/zellij"]
type = "archive-file"
url = "https://github.com/zellij-org/zellij/releases/download/v0.40.0/zellij-x86_64-apple-darwin.tar.gz"
executable = true
path = "zellij"
checksum = "sha256:abc123..."
```

**Renovate rule**:

```json5
{
  customType: 'regex',
  fileMatch: ['^home/\\.chezmoiexternals/.*\\.toml(\\.tmpl)?$'],
  matchStrings: [
    'url = "https://github\\.com/(?<depName>[^/]+/[^/]+)/releases/download/(?<currentValue>v?[0-9.]+)/',
  ],
  datasourceTemplate: 'github-releases',
}
```

**How it works**:

- `depName`: Repository (e.g., `zellij-org/zellij`)
- `currentValue`: Version tag (e.g., `v0.40.0`)
- Renovate extracts repo from URL

**Result**: Updates version in URL when new releases are published.

**Note**: Checksums require additional handling (see below).

### 5. Release with Version and Checksum (github-releases)

**Use case**: Release binary needing both version and checksum updates

**External format**:

```toml
# renovate: depName=zellij-org/zellij
[".local/bin/zellij"]
type = "archive-file"
url = "https://github.com/zellij-org/zellij/releases/download/v0.40.0/zellij-x86_64-apple-darwin.tar.gz"
executable = true
path = "zellij"
checksum = "sha256:abc123def456..."
```

**Renovate rule**:

```json5
{
  customType: 'regex',
  fileMatch: ['^home/\\.chezmoiexternals/.*\\.toml(\\.tmpl)?$'],
  matchStrings: [
    '# renovate: depName=(?<depName>.*?)\\n.*?url = "https://github\\.com/[^/]+/[^/]+/releases/download/(?<currentValue>v?[0-9.]+)/(?<currentFileName>.*?)".*?\\n.*?checksum = "(?<currentDigest>sha256:[a-f0-9]{64})"',
  ],
  datasourceTemplate: 'github-releases',
  autoReplaceStringTemplate: '# renovate: depName={{{depName}}}\n{{{indentation}}}type = "archive-file"\n{{{indentation}}}url = "https://github.com/{{{depName}}}/releases/download/{{{newValue}}}/{{{currentFileName}}}"\n{{{indentation}}}executable = true\n{{{indentation}}}path = "{{{path}}}"\n{{{indentation}}}checksum = "{{{newDigest}}}"',
}
```

**Challenge**: Renovate can't automatically compute checksums. Solutions:

1. Use `autoReplaceStringTemplate` to preserve structure (manual checksum update needed)
2. Run post-update script to compute and update checksums
3. Accept manual checksum updates in PRs

### 6. Multiple Files from Same Repo (shared pattern)

**Use case**: Several files from the same repository

**External format**:

```toml
# renovate: repo=catppuccin/bat branch=main sha=6810349b28055dce54076712fc05fc68da4b8ec0
[".config/bat/themes/Catppuccin Latte.tmTheme"]
type = "file"
url = "https://github.com/catppuccin/bat/raw/6810349b28055dce54076712fc05fc68da4b8ec0/themes/Catppuccin%20Latte.tmTheme"

[".config/bat/themes/Catppuccin Mocha.tmTheme"]
type = "file"
url = "https://github.com/catppuccin/bat/raw/6810349b28055dce54076712fc05fc68da4b8ec0/themes/Catppuccin%20Mocha.tmTheme"
```

**Renovate rule**:

```json5
{
  customType: 'regex',
  fileMatch: ['^home/\\.chezmoiexternals/bat\\.externals\\.toml(\\.tmpl)?$'],
  matchStrings: [
    '# renovate: repo=(?<depName>catppuccin/bat) branch=(?<currentValue>main) sha=(?<currentDigest>[a-f0-9]{40})',
    'url = "https://github\\.com/catppuccin/bat/raw/(?<currentDigest>[a-f0-9]{40})/',
  ],
  datasourceTemplate: 'git-refs',
}
```

**Strategy**: Single annotation at top, Renovate updates all matching SHAs in file.

## File Matching Patterns

### Match .chezmoiexternals/ Directory

```json5
fileMatch: ["^home/\\.chezmoiexternals/.*\\.toml(\\.tmpl)?$"]
```

Matches:

- `home/.chezmoiexternals/zsh.externals.toml`
- `home/.chezmoiexternals/bat.externals.toml`
- Any `.toml` or `.toml.tmpl` in directory

### Match Specific Program

```json5
fileMatch: ["^home/\\.chezmoiexternals/zsh\\.externals\\.toml(\\.tmpl)?$"]
```

Use for program-specific rules.

### Match Legacy Format

```json5
fileMatch: ["^home/\\.chezmoiexternal\\.toml(\\.tmpl)?$"]
```

For old single-file format.

## Annotation Patterns

### Inline Annotation (Recommended)

Place comment immediately before external definition:

```toml
# renovate: repo=user/repo branch=main
[".path/to/file"]
type = "git-repo"
url = "https://github.com/user/repo.git"
revision = "abc123..."
```

### Shared Annotation (Multiple Externals)

Place at top of file for dependencies sharing same repo:

```toml
# renovate: repo=catppuccin/bat branch=main sha=6810349b28055dce54076712fc05fc68da4b8ec0

[".config/bat/themes/theme1.tmTheme"]
type = "file"
url = "https://github.com/catppuccin/bat/raw/6810349b28055dce54076712fc05fc68da4b8ec0/themes/theme1.tmTheme"

[".config/bat/themes/theme2.tmTheme"]
type = "file"
url = "https://github.com/catppuccin/bat/raw/6810349b28055dce54076712fc05fc68da4b8ec0/themes/theme2.tmTheme"
```

### No Annotation (URL Extraction)

If external format is consistent, Renovate can extract info from URL:

```toml
[".local/bin/tool"]
type = "archive-file"
url = "https://github.com/user/tool/releases/download/v1.0.0/tool.tar.gz"
executable = true
```

Requires smart regex extracting `depName` and `currentValue` from URL.

## Datasource Types

### git-refs

Tracks commit SHAs from Git refs (branches, tags).

**Best for**:

- Git repository `revision` fields
- Archive URLs with commit SHAs
- Raw file URLs with commit SHAs

**Fields**:

- `depName`: Repository path (e.g., `user/repo`)
- `currentValue`: Ref to track (branch or tag name)
- `currentDigest`: Current commit SHA

**Example**:

```json5
datasourceTemplate: "git-refs"
```

### github-releases

Tracks GitHub release tags.

**Best for**:

- Release binary URLs with version tags
- Archive downloads from releases

**Fields**:

- `depName`: Repository path (e.g., `user/repo`)
- `currentValue`: Release tag (e.g., `v1.0.0`)

**Example**:

```json5
datasourceTemplate: "github-releases"
```

### github-tags

Tracks Git tags (alternative to github-releases).

**Best for**:

- Repositories using tags without releases
- Lightweight tags

**Example**:

```json5
datasourceTemplate: "github-tags"
```

## Testing Renovate Rules

### Validate Regex Pattern

Use online regex tester (regex101.com):

1. Copy external file content as test string
2. Enter your `matchStrings` pattern
3. Verify named capture groups match correctly

### Test Locally

```bash
# Dry-run Renovate
LOG_LEVEL=debug renovate --dry-run --require-config=false

# Check specific file
LOG_LEVEL=debug renovate --dry-run \
  --renovate-config=renovate.json5 \
  home/.chezmoiexternals/zsh.externals.toml
```

### Validate in PR

Create test PR with intentionally outdated SHA:

1. Modify external to use old SHA
2. Commit and push
3. Wait for Renovate to propose update
4. Verify PR updates correct fields

## Common Issues

### Renovate Not Detecting Dependency

**Symptoms**: No PRs for known-outdated dependencies

**Debugging**:

1. Check `fileMatch` pattern includes your file
2. Verify regex pattern matches file format
3. Ensure datasource is appropriate
4. Check Renovate logs for parse errors
5. Validate named capture groups exist

**Fix**: Adjust regex, add annotations, or use different datasource.

### Updates Break Checksums

**Symptoms**: Renovate updates version but checksum becomes invalid

**Solutions**:

1. **Accept manual updates**: Renovate updates version, you update checksum in PR
2. **Post-update script**: Run script to compute and update checksums
3. **Remove checksums**: Use only for non-security-critical files (not recommended)
4. **Template checksums**: Use external checksum files Renovate can update separately

### Multiple Matches for Same Dependency

**Symptoms**: Renovate creates multiple PRs for same repo

**Cause**: Multiple regex patterns match same external

**Fix**: Make patterns more specific or consolidate into single pattern.

### Branch Not Found

**Symptoms**: Renovate error "branch not found"

**Cause**: Annotation specifies non-existent branch

**Fix**: Verify branch name matches repository default branch (main vs master).

## Best Practices

1. **Use annotations**: Add `# renovate:` comments for clarity and maintainability
2. **Group by program**: Organize externals in `.chezmoiexternals/PROGRAM.externals.toml`
3. **Consistent formatting**: Use same pattern across similar externals
4. **Document patterns**: Add comments in `renovate.json5` explaining each rule
5. **Test thoroughly**: Validate rules before relying on automation
6. **Monitor PRs**: Review Renovate PRs regularly to catch issues
7. **Pin everything**: Always use immutable references
8. **Separate rules**: Use different rules for different external types

## Example: Complete Renovate Configuration

```json5
{
  extends: ['config:base'],
  customManagers: [
    // Git repos with revision field
    {
      customType: 'regex',
      fileMatch: ['^home/\\.chezmoiexternals/.*\\.toml(\\.tmpl)?$'],
      matchStrings: [
        '# renovate: repo=(?<depName>.*?) branch=(?<currentValue>.*?)\\n.*?\\n.*?revision = "(?<currentDigest>[a-f0-9]{40})"',
      ],
      datasourceTemplate: 'git-refs',
    },
    // GitHub archives with commit SHA
    {
      customType: 'regex',
      fileMatch: ['^home/\\.chezmoiexternals/.*\\.toml(\\.tmpl)?$'],
      matchStrings: [
        '# renovate: repo=(?<depName>.*?) branch=(?<currentValue>.*?)\\n.*?url = "https://github\\.com/[^/]+/[^/]+/archive/(?<currentDigest>[a-f0-9]{40})\\.tar\\.gz"',
      ],
      datasourceTemplate: 'git-refs',
    },
    // GitHub raw files with commit SHA
    {
      customType: 'regex',
      fileMatch: ['^home/\\.chezmoiexternals/.*\\.toml(\\.tmpl)?$'],
      matchStrings: [
        '# renovate: repo=(?<depName>.*?) branch=(?<currentValue>.*?)\\n.*?url = "https://github\\.com/[^/]+/[^/]+/raw/(?<currentDigest>[a-f0-9]{40})/',
      ],
      datasourceTemplate: 'git-refs',
    },
    // GitHub releases
    {
      customType: 'regex',
      fileMatch: ['^home/\\.chezmoiexternals/.*\\.toml(\\.tmpl)?$'],
      matchStrings: [
        'url = "https://github\\.com/(?<depName>[^/]+/[^/]+)/releases/download/(?<currentValue>v?[0-9.]+)/',
      ],
      datasourceTemplate: 'github-releases',
    },
  ],
}
```

## Reference Commands

### Get Latest Commit SHA

```bash
gh api repos/USER/REPO/commits/BRANCH --jq .sha
```

### Get Latest Release

```bash
gh api repos/USER/REPO/releases/latest --jq .tag_name
```

### Compute Checksum

```bash
curl -fsSL <url> | shasum -a 256
```

### Test External Update

```bash
# Force update externals
chezmoi update --force

# Preview changes
chezmoi diff

# Apply
chezmoi apply
```
