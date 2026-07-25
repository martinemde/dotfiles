---
name: commit
description: Describe and finalize work with jj-vcs — drafting a description for the current change, splitting mixed work into focused commits, and advancing to a clean working copy. Use when asked to commit, when finishing a unit of work, or when starting new work on top of undescribed changes.
---

# Commit

Produce a clean atomic history ending on a fully clean working copy. In jj the working copy is
already a commit, so "committing" is really two questions: is this change described well, and
should `@` advance.

## Look first

Run these together — the description depends on all three:

```bash
jj diff                                                      # what actually changed
jj log -r "ancestors(@, 10)" --template builtin_log_oneline   # this repo's style
jj status                                                    # @'s current description
```

## Split before describing

If `@` holds unrelated changes, separate them rather than writing a description that lists two
things:

```bash
jj split -m "message" <files>                # peel off part of @
jj squash --use-destination-message <files>  # fold files into the parent
```

## Write the description

It should complete the phrase "This commit will…", and explain _why_ in the body — the diff
already shows what. One or two sentences.

Match the style you saw in the log. Where that log uses conventional commits, follow it; where
it doesn't, don't introduce it. The verb carries meaning worth keeping consistent: "add" for
something wholly new, "update" for an enhancement to what exists, "fix" for a bug. Add
`Fixes #NN` when an issue closes.

For multi-line messages, use a heredoc so quoting doesn't mangle the body:

```bash
jj commit -m "$(cat <<'EOF'
Description here.

Co-Authored-By: Claude <noreply@anthropic.com>
EOF
)"
```

## Pick the command from `@`'s state

| `@` right now                         | Command                                       |
| ------------------------------------- | --------------------------------------------- |
| Already well described                | `jj new` — or `jj new -m "next plan"`         |
| Needs a description, ready to move on | `jj commit -m "..."` — describes and advances |
| Needs a description, more work coming | `jj desc -m "..."`                            |

Then run `jj status` in the same message to confirm where you landed. When this is a handoff
into new work, `jj new -m "<goal of the new work>"` starts it named.

Don't `jj git push` unless asked.
