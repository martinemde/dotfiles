---
name: use-jj-not-git
description: Guidance for using Jujutsu (jj) for version control. Use this skill when you would use git in order to make and edit commits properly, or for help to understand jj commands or concepts (working copy, changes, conflicts, operation log, bookmarks, revsets), troubleshoot jj issues, configure jj settings, understand jj workflows, translate Git commands to jj, or work with jj repositories. Also trigger when users mention "jujutsu", version control, or commits.
---

# Jujutsu (jj) Commit Guide

Use `jj` instead of `git` for all version control operations.

## Making Commits

**No staging area** - Files are automatically tracked. Just edit files and commit.

```bash
# Describe current change (like writing a commit message)
jj describe -m "Add feature X"

# Finalize current change and start a new empty one
jj commit -m "Add feature X"

# Start new change on top of current (like git commit without -a)
jj new -m "Next task"

# Start new change on main
jj new main -m "Start feature"
```

## Key Differences from Git

- `@` = working copy (current change)
- `@-` = parent of working copy
- Changes auto-amend - editing files updates the current change
- Use `jj squash` to move changes into parent (like `git commit --amend`)
- Use `jj squash -i` for interactive selection

## Quick Reference

| Task                  | Command                    |
| --------------------- | -------------------------- |
| Set commit message    | `jj describe -m "message"` |
| Finalize and continue | `jj commit -m "message"`   |
| Start new change      | `jj new` or `jj new main`  |
| Amend into parent     | `jj squash`                |
| View status           | `jj st`                    |
| View log              | `jj log`                   |
| Push to remote        | `jj git push --change @`   |
| Undo last operation   | `jj undo`                  |

## References

For detailed guidance, read `references/` files:

- **`git-to-jj-commands.md`** - Comprehensive Git → jj command mapping
- **`git-comparison.md`** - Conceptual differences from Git
- **`working-copy.md`** - How automatic commits work
- **`bookmarks.md`** - Managing bookmarks (branches)
- **`github.md`** - Fork workflows and PRs
- **`conflicts.md`** - Conflict resolution
- **`operation-log.md`** - Undo and operation history
- **`revsets.md`** - Query syntax (`@`, `@-`, `main..@`, etc.)
- **`config.md`** - Configuration options
- **`tutorial.md`** - Step-by-step introduction
- **`divergence.md`** - Handling divergent changes
- **`multiple-remotes.md`** - Multi-remote setups
- **`git-compatibility.md`** - Colocated repos and Git interop
