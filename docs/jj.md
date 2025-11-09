# Jujutsu (jj) Configuration

This repository is configured to work with [Jujutsu](https://jj-vcs.github.io/) (jj), a Git-compatible version control system that provides a more intuitive interface for managing changes.

## Overview

- **Global Config**: `home/dot_config/jj/config.toml` - User settings, aliases, and UI preferences
- **Repo Config**: `.jjconfig.toml` - Repository-specific settings (automatic formatting)
- **Colocated with Git**: This repo uses `jj` alongside `git` (colocated mode)

## Automatic Code Formatting with `jj fix`

The repository is configured to automatically format code using `jj fix`. This ensures consistent code style without manual intervention.

### Configured Formatters

| File Type | Tool | Pattern |
|-----------|------|---------|
| Shell scripts | shfmt | `**/*.sh`, `**/*.bash` |
| TOML files | prettier | `**/*.toml` |
| Markdown | prettier | `**/*.md` |
| JSON | prettier | `**/*.json` |
| Lua | stylua | `**/*.lua` |

### Usage

```bash
# Format all files in the current change
jj fix

# Format specific files
jj fix path/to/file.sh

# Format files matching a pattern
jj fix -s 'glob:**/*.md'
```

### How It Works

When you run `jj fix`, Jujutsu:
1. Identifies files matching the configured patterns
2. Runs the appropriate formatter for each file type
3. Updates files in place if changes are needed
4. Does NOT create conflicts (safe to run on any revision)

**Note**: Unlike git hooks, `jj fix` must be run manually. It's not automatic on commit. This gives you control over when formatting happens.

### Configuration

Formatter configuration is in `.jjconfig.toml`:

```toml
[fix.tools.shfmt]
command = ["shfmt", "-i", "2", "-bn", "-ci", "-sr", "-s"]
patterns = ["glob:'**/*.sh'", "glob:'**/*.bash'"]

[fix.tools.prettier-toml]
command = ["bun", "run", "prettier", "--write", "--parser", "toml", "$path"]
patterns = ["glob:'**/*.toml'"]
```

The `$path` variable is replaced with the file path, allowing formatters to use the filename for context.

## Global jj Configuration

The global jj config (`home/dot_config/jj/config.toml`) includes:

### Custom Aliases

- `jj s` - Status (same as `jj status`)
- `jj d` - Diff
- `jj l` - Log of current stack
- `jj stack` - Show current stack of changes
- `jj push` - Tug bookmark, push, and track
- `jj pull` - Fetch and rebase onto latest
- `jj pr` - Create GitHub PR for current bookmark

### Useful Revsets

- `stack()` - Current stack of mutable commits
- `open()` - All open work (not in trunk)
- `ready()` - Open work ready to push (not WIP/private)
- `closest_bookmark(@)` - Nearest bookmark to current change
- `closest_pushable(@)` - Nearest pushable change

### Integration Features

- **Git Colocated Mode**: Works alongside git seamlessly
- **Delta Integration**: Uses delta for diff paging
- **Neovim**: Configured as default editor
- **GitHub CLI**: Aliases for creating PRs with `gh`

## Why jj Instead of git?

Jujutsu provides several advantages:

1. **Better Mental Model**: Changes are first-class, not just commits
2. **No Staging Area**: Every change is tracked automatically
3. **Safe History Editing**: Built-in support for rewriting history without footguns
4. **Conflict-Free Operations**: Most operations never create conflicts
5. **Git Compatible**: Works with existing Git workflows and remotes

However, git is still available and both can be used interchangeably in colocated mode.

## Common Workflows

### Starting Work

```bash
# Create new change on trunk
jj new trunk()

# Create new change on a bookmark
jj co main
```

### Before Pushing

```bash
# Format all code
jj fix

# Create a commit message and push
jj describe
jj push
```

### Working with Stacks

```bash
# Show current stack
jj stack

# Rebase entire stack onto trunk
jj reheat

# Show all open work
jj open
```

## Tool Installation

All formatters are managed by mise and defined in `.mise.toml`:

```toml
[tools]
"cargo:stylua" = "0.20.0"
shfmt = "v3.12.0"
```

Prettier is managed via `package.json` and bun.

Install all tools with:

```bash
mise install
bun install
```

## Design Decisions

### Why Manual Formatting?

Unlike git pre-commit hooks, `jj fix` is manual. This is intentional:

- **Explicit Control**: You choose when to format
- **Review Changes**: See formatting changes before they're applied
- **No Hook Bypassing**: No need for `--no-verify` flags
- **Works Everywhere**: Format any revision, not just current

### Why Repository-Specific Config?

The `.jjconfig.toml` ensures:

- **Consistency**: Everyone using jj formats the same way
- **Project Standards**: Each repo can have different formatting rules
- **Versioned**: Config is committed and tracked like code

### Why Multiple Prettier Commands?

Each file type uses a separate `[fix.tools.*]` entry with explicit parsers:

- **Clarity**: Obvious which formatter handles which files
- **Reliability**: No parser auto-detection issues
- **Performance**: Prettier runs once per file type, not globally

This approach prioritizes correctness over brevity.
