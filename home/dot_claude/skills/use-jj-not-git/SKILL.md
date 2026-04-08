---
name: use-jj-not-git
description: >-
  Use `jj commit` to commit without loading this skill. This skill should
  be used when doing more with Jujutsu (jj) than just committing (working
  copy, changes, conflicts, operation log, bookmarks, revsets, pushing),
  troubleshooting jj issues, resolving "Refusing to create new remote
  bookmark" errors, configuring jj settings, understanding jj workflows,
  translating Git commands to jj, or working with jj repositories. Also
  triggers when users mention "jujutsu", version control, or commits.
---

# Jujutsu (jj) Version Control

Use `jj` instead of `git` for all version control operations.

Run `jj --help` for the authoritative command reference and
`jj <command> --help` for current flags and options. Never rely on this
skill as authoritative — verify behavior with `--help`.

## Making Commits

**No staging area** — files are automatically tracked. Edit files and commit.

```bash
# Describe current change
jj describe -m "Add feature X"

# Finalize current change and start a new empty one
jj commit -m "Add feature X"

# Start new change on top of current
jj new -m "Next task"

# Start new change on main
jj new main -m "Start feature"
```

## Key Differences from Git

- `@` = working copy (current change)
- `@-` = parent of working copy
- Changes auto-amend — editing files updates the current change
- `jj squash` moves changes into parent (like `git commit --amend`)
- `jj squash -i` for interactive selection

## Showing Diffs

`jj show` does not accept path arguments. Use `jj diff` instead:

```bash
jj diff -r @-                                     # all changes in parent
jj diff -r @- path/to/file                        # specific file
jj diff -- 'glob:"bin/*" ~ glob:"bin/,special"'   # fileset expression
```

## Advancing Bookmarks

After `jj commit`, advance the nearest ancestor bookmark forward:

```bash
jj bookmark advance                  # advance closest bookmark(s) to @
```

Run `jj bookmark advance --help` for `--to` and other options.

## Quick Reference

| Task                  | Command                    |
| --------------------- | -------------------------- |
| Set commit message    | `jj describe -m "message"` |
| Finalize and continue | `jj commit -m "message"`   |
| Start new change      | `jj new` or `jj new main`  |
| Amend into parent     | `jj squash`                |
| View status           | `jj st`                    |
| View log              | `jj log`                   |
| View diff             | `jj diff -r <rev>`         |
| Advance bookmark      | `jj bookmark advance`      |
| Push to remote        | `jj git push --change @`   |
| Undo last operation   | `jj undo`                  |

## References

For detailed guidance, read `references/` files:

- **`git-to-jj-commands.md`** — Comprehensive Git → jj command mapping
- **`git-comparison.md`** — Conceptual differences from Git
- **`working-copy.md`** — How automatic commits work
- **`bookmarks.md`** — Managing bookmarks (branches)
- **`github.md`** — Fork workflows and PRs
- **`conflicts.md`** — Conflict resolution
- **`operation-log.md`** — Undo and operation history
- **`revsets.md`** — Query syntax (`@`, `@-`, `main..@`, etc.)
- **`config.md`** — Configuration options
- **`tutorial.md`** — Step-by-step introduction
- **`divergence.md`** — Handling divergent changes
- **`multiple-remotes.md`** — Multi-remote setups
- **`git-compatibility.md`** — Colocated repos and Git interop
