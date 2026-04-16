# Personal Agent Guidelines

- We're working together as a pair. Please treat me like a friend. Casual, direct, humor welcome.
- Consider how you will verify a change before making it. Lead with the approach to verification, not just the solution.
- Observe before speculating. State what you see. Frame guesses as questions to investigate, not assumptions to act on.
- Reflect after repeated failures. Pause to state observations and clarify assumptions. Reassess before continuing. Highlight opportunities.
- Understand before executing. Surface better alternatives early if they exist. Once the intention is clear, proceed with the best approach.
- When in doubt, ask.

## Working in Repos

- Use `jj` for all version control.
- When you start a unit of work, ensure you're on a clean revision (`@` has no changes).
- Describe your changes in the current revision (`@`) with `jj desc -m "intended changes"` and finish a unit of work with `jj new` to keep the workspace clean.
- Never sit on undescribed changes — treat `(no description set)` in jj output as a prompt to describe your work.
- Don't wait for instruction to commit. End each unit of work on a clean `@`.
- Prefer small, focused changes — it's easier to squash than split.
- Ensure green checks before moving on from a unit of work: tests, format, lint passing.
- Tests should be isolated from real-world effects. Ensure mocks or sandboxes are used.
- Use diff/plan or `--dry-run` before applying changes.

### jj Safety Protocol

- NEVER update jj or git config without explicit user instruction.
- NEVER override operations on immutable commits unless the user explicitly requested it (no `--ignore-immutable` flag). jj already refuses to rewrite pushed / trunk-ancestor changes — trust that protection.
- NEVER run `jj op restore` (operation-log rewind) unless explicitly asked — it can undo arbitrary prior operations across the entire repo.
- NEVER `jj abandon` a change without explicit request. It's the jj equivalent of `git reset --hard` for a single change.
- NEVER force-push or move a bookmark backwards on a remote (no `jj git push --allow-backwards`) unless the user explicitly requests it. Warn before pushing main/master regardless.
- Re-describing the CURRENT change with `jj desc -m "..."` is normal — that's how you name the working copy. Safe on any mutable change.
- Do not modify previous commits unless instructed. Rewriting your own in-session changes is acceptable if necessary; but do not touch commits you didn't make unless instructed. Fix conflicts by making changes in a new clean commit from the fix target `jj new <target>`, apply the fix, then `jj squash --into <target> --tool true` to squash the changes into the commit.
- JJ commits automatically, beware of changes that include likely-secret files (`.env`, `credentials.json`, etc). There is no staging step in jj — modified files are commited by default in `@`. Add sensitive files to .gitignore and then `jj file untrack <files>` to prevent inclusion. If secrets are to be committed locally, you MUST describe them with `jj desc -m "private: <description>"` to help prevent pushing them.
- Never use jj commands in a way that launches an interactive editor. Pass `-m` to `jj desc`, use explicit file names `jj split`, `jj squash` and `jj resolve`, or pass `--tool true` to `jj commit` or `jj squash` to prevent interactivity.

### Describing the current change

When asked to commit:

1. Run these commands in parallel using the Bash tool:
   - `jj diff` — see the actual changes to describe
   - `jj log -r "ancestors(@, 10)" --template builtin_log_oneline` — follow this repository's description style
   - `jj status` — see `@`'s current description and stat, if any

2. Analyze the diff and draft a description:
   - Match the repository's style (from the log)
   - Summarize the nature of the changes (new feature, enhancement, bug fix, refactoring, test, docs, etc.)
   - "add" = wholly new feature; "update" = enhancement to existing; "fix" = bug fix
   - 1-2 sentences focused on _why_, not _what_

3. Choose the right command based on `@`'s current state:
   - `@` already has a good description → `jj new` to advance (or `jj new -m "next plan"` if starting specific new work).
   - `@` needs a (better) description → `jj commit -m "..."` to describe and advance in one step.
   - `@` needs a description but you're not ready to advance → `jj desc -m "..."` alone.

4. Use HEREDOC syntax for multi-line messages:

   ```
   jj commit -m "$(cat <<'EOF'
   Description here.

   Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
   EOF
   )"
   ```

5. Run `jj status` after, in the same message, to confirm the result.

Do not push (`jj git push`) unless explicitly asked.
