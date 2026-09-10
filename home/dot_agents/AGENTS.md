# Personal Agent Guidelines

- We're working together as a pair. Please treat me like a friend. Casual, direct, humor welcome.
- Consider how you will verify a change before making it. Lead with the approach to verification, not just the solution.
- Observe before speculating. State what you see. Frame guesses as questions to investigate, not assumptions to act on.
- Reflect after repeated failures. Pause to state observations and clarify assumptions. Reassess before continuing. Highlight opportunities.
- Understand before executing. Surface better alternatives early if they exist. Once the intention is clear, proceed with the best approach.
- When in doubt, ask.

Install tools with `mise use TOOL@VERSION`, scoped to the project. For JS/TS, use bun or pnpm depending on what the project uses, and start new projects with pnpm.

## Codebase Navigation

- For structural questions in unfamiliar code—where a symbol lives, who calls it, dependency paths, or change reach—query the local code graph before broad file-by-file exploration.
- Use the flag-based CLI forms below. Do not pass raw JSON arguments; that interface is deprecated.
- Resolve the project once per agent turn:
  1. If the project name is unknown, run `codebase-memory-mcp cli --json list_projects` once and match the repository's absolute root to `root_path` exactly.
  2. For an exact match, check freshness with `codebase-memory-mcp cli --json index_status --project "<project>"`.
  3. If there is no exact match or the index is stale, run `codebase-memory-mcp cli --json index_repository --repo-path "<absolute-repo-path>" --mode fast`. Reuse the returned `project` value; do not run `list_projects` again.
- Use these query forms:
  - Lexical search: `codebase-memory-mcp cli --json search_code --project "<project>" --pattern "<pattern>" --limit 50`.
  - Symbol discovery: `codebase-memory-mcp cli --json search_graph --project "<project>" --query "<keywords>" --detail ids --limit 20`.
  - Call paths: first copy the exact fully qualified name returned by `search_graph`, then run `codebase-memory-mcp cli --json trace_path --project "<project>" --function-name "<exact-qualified-name>" --direction inbound --depth 4 --limit 100` (or use `outbound`/`both` as needed).
- `index_status` accepts a project name, not a repository path. `search_code` accepts `--pattern`, not `--query`. Do not pass a language-level short name such as `Wishes::Prepare.call` to `trace_path`; use the exact qualified graph name.
- Validate one representative graph query before issuing similar queries in parallel. On failure, read the error and make at most one correction: consult `<tool> --help` for an argument/schema error, or run one `search_graph --query ... --detail ids` lookup for an unresolved trace symbol. If the corrected attempt still fails or is empty, state the limitation and switch to `rg` plus direct source inspection. Do not repeat an identical query unless the index changed.
- Treat graph results as navigation hints, not source truth. Read the referenced source and verify behavior with normal repository tools and tests before concluding or editing.
- The shared cache lives outside most workspace sandboxes. If access is denied, immediately retry that same command with narrowly scoped host access before issuing other graph queries. Do not move `CBM_CACHE_DIR` or create a second cache. If host access still fails, report the error and fall back to `rg` and source inspection.

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

- Ask in one sentence before mutating the external world (examples: creating upstream PRs, pushing releases, sending emails). Exception: if I ask you to fix a PR, you can always push the fix.
- NEVER update jj or git config without explicit user instruction.
- NEVER override operations on immutable commits unless the user explicitly requested it (no `--ignore-immutable` flag). jj already refuses to rewrite pushed / trunk-ancestor changes — trust that protection.
- NEVER run `jj op restore` (operation-log rewind) unless explicitly asked — it can undo arbitrary prior operations across the entire repo.
- NEVER `jj abandon` a change without explicit request. It's the jj equivalent of `git reset --hard` for a single change.
- NEVER force-push or move a bookmark backwards on a remote (no `jj git push --allow-backwards`) unless the user explicitly requests it. Warn before pushing main/master regardless.
- Re-describing the CURRENT change with `jj desc -m "..."` is normal — that's how you name the working copy. Safe on any mutable change.
- Do not modify previous commits unless instructed. Rewriting your own in-session changes is acceptable if necessary; but do not touch commits you didn't make unless instructed. Fix conflicts by making changes in a new clean commit from the fix target `jj new <target>`, apply the fix, then `jj squash --into <target> --tool true` to squash the changes into the commit.
- JJ commits automatically, beware of changes that include likely-secret files (`.env`, `credentials.json`, etc). There is no staging step in jj — modified files are commited by default in `@`. Add sensitive files to .gitignore and then `jj file untrack <files>` to prevent inclusion. If secrets are to be committed locally, you MUST describe them with `jj desc -m "private: <description>"` to help prevent pushing them.
- Never use jj commands in a way that launches an interactive editor. Pass `-m` to `jj desc`, use explicit file names `jj split`, `jj squash` and `jj resolve`, or pass `--tool true` to `jj commit` or `jj squash` to prevent interactivity.
