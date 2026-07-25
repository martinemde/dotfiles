# `/checkout` — Start a New Change for an Issue

Start work on an issue or feature by creating a new jj change on top of the up-to-date default branch, with an optional named bookmark for pushing.

```
/checkout #123
/checkout feat/my-feature
```

## Why this exists

Three things go wrong when starting work without a structured workflow:

**Stale base.** Starting a change on top of a local `main` that hasn't been fetched recently means your work starts behind. The eventual PR will have a larger diff than necessary, and rebasing is more likely.

**Untracked naming.** A change with no bookmark or description has no connection to the work it represents. A bookmark named `feat/123-add-dark-mode` is immediately traceable to its issue, and `jj log` is readable.

**Lost work.** Starting a new change while the current working copy has meaningful uncommitted work risks forgetting about it. [`/checkout`](../checkout/README.md) surfaces this and asks what to do before creating anything new.

## How to use it

**From an issue reference** — the agent fetches the issue title and derives a conventional bookmark name:

```
/checkout #123
→ creates a new change on main with bookmark feat/123-add-dark-mode
```

**With an explicit name** — used directly when you already know the bookmark name:

```
/checkout refactor/auth-middleware
```

**If the working copy has changes**, the agent will surface what's there and suggest either committing or describing the work before starting fresh. It won't silently abandon work.

## How it works with jj

Unlike git, jj doesn't have a "checkout" concept. Instead:

1. `jj git fetch` to get the latest remote state
2. `jj new main` to create a new empty change on top of main
3. `jj bookmark create <name> -r @` to attach a named bookmark for later pushing

The bookmark is created upfront so that the eventual `jj git push --bookmark <name>` and `gh pr create` work smoothly. If you prefer jj's auto-generated bookmark names (`push-*`), you can skip the explicit bookmark and use `jj git push -c @-` when ready.

## In the [`/work-on`](../work-on/README.md) workflow

[`/checkout`](../checkout/README.md) is Phase 1, Step 1. It runs first, before any investigation or planning, so all subsequent work happens on a clean change from the start. The bookmark name ties the eventual PR back to the issue.
