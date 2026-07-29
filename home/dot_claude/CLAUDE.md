# Personal Agent Guidelines

We're working together as a pair. Casual, direct, humor welcome — treat me like a friend.

Lead with how you'll verify a change, not just what the change is. After repeated failures,
stop and reassess out loud instead of trying a fourth variation.

Prefer `mise use TOOL@VERSION` for tool installs and `bun` for JavaScript/TypeScript, scoped
to the project by default.

## Working in Repos

Use `jj` for version control, never `git`.

The working copy `@` is always a real change being edited — there's no staging step, and file
edits amend `@` in place. So the unit of work is: start on a clean `@`, describe what you
intend with `jj desc -m "..."`, do the work, then `jj new` to leave a clean `@` behind.
`(no description set)` in jj output means work is sitting undescribed; describe it. Don't wait
to be asked to commit.

Prefer small focused changes — squashing is easier than splitting. Get tests, format, and lint
green before moving off a unit of work, and keep tests isolated from real-world effects with
mocks or sandboxes. Preview with diff, plan, or `--dry-run` before applying.

Never let a jj command open an editor — it hangs the session. Pass `-m` to `jj desc`, name
files explicitly for `jj split`, `jj squash`, and `jj resolve`, and pass `--tool true` where a
diff editor would otherwise open.

The `commit` skill covers describing a change; `advanced-jj` covers conflicts, revsets,
bookmarks, the operation log, and multi-remote setups.

## jj Safety Protocol

jj commits continuously and rewrites history freely, so the usual "it's still just local"
safety net doesn't exist. These need an explicit request from me before you do them:

- Rewriting or abandoning changes you didn't create — `jj abandon` is `git reset --hard` for a
  single change. Re-describing your own work doesn't count; that's fine on any mutable change.
- `jj op restore`, which rewinds the operation log and can undo unrelated prior operations
  across the whole repo.
- Overriding immutability with `--ignore-immutable`. jj already refuses to rewrite pushed or
  trunk-ancestor changes; that refusal is correct, so treat it as a stop rather than an
  obstacle.
- Force-pushing or moving a remote bookmark backwards (`--allow-backwards`). Warn me before
  pushing main or master even when it's a normal fast-forward.
- Changing jj or git config.
- `jj git push` at all, unless I asked for it.

**Secrets get committed by default.** Modified files land in `@` with no staging step to catch
them. When you notice something that smells like credentials (`.env`, `credentials.json`, key
files), add it to `.gitignore` and `jj file untrack <file>`. If something sensitive has to be
committed locally, describe it as `private: <description>` so it's visible before any push.
