---
name: pr
description: Prepare, push, and open a GitHub pull request for a Jujutsu (jj) revision. Use only when asked to create or open a PR; do not use for ordinary review or local commits.
---

# Create Pull Request

Publish an already-completed change as a GitHub pull request. Default to a draft PR unless the user explicitly asks for ready-for-review.

Use the requested revision when one is supplied. Otherwise use `@-` when the working copy is empty and `@` when it contains the completed change.

## Review Before Publishing

Read the active repository instructions and any pull-request template. Inspect the complete proposed stack and diff before making an external change:

- `jj status`
- `jj log -r "trunk()..<revision>"`
- `jj diff --from trunk() --to <revision> --stat`
- `jj diff --from trunk() --to <revision>`
- `jj bookmark list --revisions <revision>`

Confirm that the target is conflict-free, every included commit has an accurate description, the diff contains only intended work, and the relevant tests and checks passed. Review the diff for correctness, regressions, missing coverage, security issues, and accidental secrets. Fix issues owned by the current task before publishing; report blockers instead of pushing a knowingly broken stack.

Do not reorganize or rewrite existing history merely to improve presentation. Never push `main`, `master`, or another trunk bookmark as the PR head.

## Push the Exact Target

Prefer a suitable local bookmark that already points to the target.

- Existing bookmark: first run `gh pr list --head <bookmark> --state all`. Do not update or duplicate an existing PR as a side effect of creating one. If none exists, preview with `jj git push --bookmark <bookmark> --dry-run`, then repeat without `--dry-run`.
- No bookmark: preview with `jj git push --change <revision> --dry-run`, then repeat without `--dry-run`; use the generated bookmark reported by jj.

Do not use `--allow-backwards`. If jj reports a stale or conflicted remote bookmark, fetch and report the conflict rather than overriding it.

Return an existing open PR without pushing. For a closed or merged PR, report it and ask before choosing a new head.

## Draft the Pull Request

Derive the title from the whole stack. Follow the repository template when present. Otherwise keep the body concise and cover:

- why the change is needed and its user-facing impact;
- important decisions or tradeoffs that are not obvious from the diff;
- verification performed, including anything not run;
- related issue links or closing keywords when supported by the available context.

Do not add assistant branding or attribution unless requested or required by repository policy. Do not invoke unavailable writing or memory tools, and do not transition Jira or mutate other external systems as a side effect.

## Create and Verify

Create the PR non-interactively with `gh pr create --head <bookmark> --title <title> --body-file <file>`, adding `--draft` unless ready-for-review was requested. Then verify the returned URL with `gh pr view <url> --json url,title,isDraft,baseRefName,headRefName`.

Return the PR URL, draft state, head/base, and verification summary.
