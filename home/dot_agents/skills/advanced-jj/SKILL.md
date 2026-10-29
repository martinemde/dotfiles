---
name: advanced-jj
description: >-
  Reference for deeper Jujutsu (jj) topics beyond the everyday
  describe/advance workflow covered in the active agent instructions. Load when working with
  conflicts, the operation log, bookmarks, revsets, fork/PR workflows,
  colocated Git repos, multi-remote setups, divergent changes, or jj
  config. Also the place to look up fileset glob syntax, non-interactive
  `jj split`, rebase/squash recipes, and moving bookmarks.
---

# Advanced Jujutsu (jj)

Everyday commit flow (describe, new, safety rules) lives in the active
`AGENTS.md` or equivalent harness instructions.
This skill is the deeper reference — load it when you hit something the
system prompt doesn't cover.

Recipes here were verified against **jj 0.45.1** (check `jj --version`).
Consult `jj <command> --help` when a command actually fails, or when your
version differs — not by default before acting.

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

## Rebase, Squash, Push

`jj rebase` takes `-o/--onto` — **not** `-d/--destination`, which older jj
used and models reach for from memory.

```bash
jj rebase -r <rev> -o <dest>         # one revision onto a destination
jj rebase -s <rev> -o <dest>         # revision plus its descendants
jj rebase -b <rev> -o <dest>         # whole branch containing <rev>
jj rebase -r <rev> -B <target>       # insert before — reorders a stack
jj rebase -r <rev> -A <target>       # insert after

jj squash                            # fold @ into its parent
jj squash --into <rev>               # fold @ into any ancestor
jj squash --from <a> --into <b>      # move changes between revisions
jj squash --into <rev> --tool true   # non-interactive

jj git push -b <bookmark>            # one bookmark; new ones push by default
jj git push -c <rev>                 # push a change, auto-naming its bookmark
jj git push --all --dry-run          # preview every push
```

`jj git push` has no `--allow-new` (new bookmarks push by default) and no
`--allow-backwards`. `jj git push --tag <tag>` pushes a tag.

## Moving Bookmarks Forward

```bash
jj bookmark advance --to @-          # nearest ancestor bookmarks up to @-
jj bookmark set <name> -r <rev>      # create, or move an existing one
jj bookmark move <name> --to <rev>   # move only; never creates
```

## Deeper reference

The jj manual ships with the binary and matches the installed version:
`jj help -k bookmarks|config|filesets|glossary|revsets|templates|tutorial`, and
`jj help <command>` for any command. Other topics are on the docs site
(`https://jj-vcs.github.io/jj/latest/<page>/`): `conflicts`, `operation-log`,
`working-copy`, `git-compatibility`, `git-comparison`, `git-command-table`, `github`,
`guides/divergence`, `guides/multiple-remotes`.
