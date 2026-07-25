---
name: advanced-jj
description: >-
  Reference for deeper Jujutsu (jj) topics beyond the everyday
  describe/advance workflow. Load when working with conflicts, the
  operation log, bookmarks, revsets, fork/PR workflows, colocated Git
  repos, multi-remote setups, divergent changes, or jj config. Also the
  place to look up fileset glob syntax, non-interactive `jj split`, and
  bookmark advancement.
---

# Advanced Jujutsu (jj)

The everyday flow and safety rules live in CLAUDE.md; describing and
splitting changes lives in the `commit` skill. This is the deeper
reference for what neither of those covers.

jj's CLI moves faster than these notes, so verify against `jj --help` and
`jj <command> --help` before acting. Treat this skill as orientation, not
ground truth.

## Mental Model

- `@` — the working copy (current change)
- `@-` — parent of `@`
- Changes auto-amend: editing files updates `@` in place, no staging
- `jj squash` folds `@` into its parent (`--into <rev>` targets any ancestor)

## Diffs with Filesets

`jj show` does not accept path arguments — use `jj diff`. Filesets
support glob and set operations:

```bash
jj diff -r @-                                     # full parent diff
jj diff -r @- path/to/file                        # one file
jj diff -- 'glob:"bin/*" ~ glob:"bin/,special"'   # glob minus exclusion
```

## Non-interactive Split

`jj split -i` needs an editor. For scripted splits, use `--tool true`
— the `true` command exits 0, accepting the file list as given:

```bash
jj split --tool true -m "Extract feature" -- \
  'glob:"path/to/file1"' 'glob:"path/to/file2"'
```

Remaining changes stay in a follow-up working copy change.

## Advancing Bookmarks

After finalizing work, move the nearest ancestor bookmark forward:

```bash
jj bookmark advance                  # closest bookmark(s) → @
```

See `jj bookmark advance --help` for `--to` and other targeting.

## Reference Files

Load from `references/` as needed:

- **`git-to-jj-commands.md`** — Git → jj command translation table
- **`git-comparison.md`** — Conceptual differences from Git
- **`git-compatibility.md`** — Colocated repos, Git interop
- **`working-copy.md`** — How automatic commits work
- **`bookmarks.md`** — Managing bookmarks (branches)
- **`revsets.md`** — Query syntax (`@`, `@-`, `main..@`, etc.)
- **`conflicts.md`** — Conflict resolution
- **`operation-log.md`** — `jj op log`, undo, restore
- **`divergence.md`** — Handling divergent changes
- **`github.md`** — Fork workflows and PRs
- **`multiple-remotes.md`** — Multi-remote setups
- **`config.md`** — Configuration options
- **`tutorial.md`** — Step-by-step introduction (for humans)
