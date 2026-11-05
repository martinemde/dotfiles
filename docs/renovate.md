# Renovate: How This Repo Manages Versions

This guide explains how Renovate is configured in this repository, how the custom version manifests work, and when/how to add or update pinned versions. It also includes handy `gh`/`gh api` commands to look up latest tags and resolve commit SHAs.

## TL;DR

- Renovate config lives at `renovate.json5` and runs every 30 minutes, opening labeled PRs (`deps`, `automated`) with low concurrency.
- We pin everything important to immutable versions or digests for reproducibility and supply‑chain safety.
- Standard managers are enabled (pip, mise, docker-compose, devcontainer, actions) and custom regex managers cover Chezmoi externals, Pi extensions, and select version files.
- Renovate automerges minor, patch, and digest updates after CI; majors and security alerts require review.

---

## Configuration Overview

File: `renovate.json5`

- Extends: `config:recommended`, `:semanticCommits`; Dependency Dashboard enabled
- Run interval: every 30 minutes; no update-time window
- Labels: `deps`, `automated`
- PR limits: `prHourlyLimit: 2`, `prConcurrentLimit: 5`

Enabled managers and file discovery:

- `pip_requirements`: `home/dot_config/dotfiles/requirements.txt`
- `npm`: `package.json`, `home/dot_config/dotfiles/package.json`
- `mise`: `.mise.toml`; custom Aqua regex covers `home/dot_config/mise/config.toml.tmpl`
- `docker-compose`: `home/dot_config/docker-compose/*.yml`
- `devcontainer`: `.devcontainer/devcontainer.json`
- `github-actions`: `.github/workflows/*.yml` (with digest pinning)
- `custom.regex`: bespoke pins including `home/dot_pi/private_agent/settings.json`

Grouping and automerge rules:

- `github-actions`: group minor/patch/digest updates; minor/patch/digest automerge
- `devcontainer`: group minor/patch/digest updates; minor/patch/digest automerge
- `docker-compose`: group digest updates; minor/patch/digest automerge
- `pip_requirements`: grouped as `python-tools` (minor/patch/digest automerge)
- `npm`: grouped as `node-tools` (minor/patch/digest automerge)
- `mise`: grouped as `mise-tools` (minor/patch/digest automerge)
- Pi extensions: grouped as `pi-extensions` (minor/patch/digest automerge)

Minor, patch, and digest updates use Renovate-managed squash merges after the
`download-integrity`, `shellcheck`, and `test` checks pass. Platform automerge is
disabled: Renovate checks and merges on its next run. Majors, initial pin updates,
and vulnerability-alert updates remain review-only. This is not branch protection;
humans and other writers can still merge directly.
A matching hash proves byte integrity, not that upstream code is benign.

---

## Self-hosted activation and visible evidence

The **Renovate** Actions workflow is the intended writer. It runs at minutes 7 and 37 of every hour
UTC, with no separate update-time window so dashboard requests and passing CI
can be processed on the next run. The hosted Mend App is not required;
do not enable both writers. The seven-day age rule, low PR limits, and manual
major/security review policy remain in `renovate.json5`.

Live runs need a dedicated GitHub App installed only on `martinemde/dotfiles`.
The account owner must create and install it through GitHub's authenticated web
settings; the current CLI OAuth token cannot create an App or its private key.
Do not copy the CLI's broad personal OAuth token into an Actions secret.

1. In [personal developer settings](https://github.com/settings/apps), create a new
   GitHub App owned by `martinemde`, not an organization. Give it a distinct name
   and this repository's URL as its homepage. Disable the webhook; no callback
   or user authorization is needed for installation tokens.
2. Allow installation only on this account. Grant these repository permissions:

- Contents, pull requests, issues, and workflows: read and write.
- Administration, checks, commit statuses, and Dependabot alerts: read. Metadata read is automatic.

These narrow [Renovate's GitHub App permissions](https://docs.renovatebot.com/modules/platform/github/#running-as-a-github-app)
to this review-only setup: CI owns checks and statuses, and organization membership
and merge queues are not used here.

3. Install the App on `martinemde`, select **Only select repositories**, and
   select **dotfiles**. Disable or deselect this repository in the hosted Mend
   Renovate App installation before enabling this writer.
4. In the new App's settings, generate and download a private key. In the
   repository's **Settings → Secrets and variables → Actions**, add secret
   `RENOVATE_APP_PRIVATE_KEY` containing the complete PEM file. Add repository
   variable `RENOVATE_APP_ID` containing the App ID (not its installation ID).
   Set the ID last: scheduled runs are skipped while it is absent, avoiding
   repeated credential failures. Keep the private key out of the repository and
   logs; remove any unneeded local copy after storing it securely.

The token action limits each installation token to the current repository,
requests only the listed permissions, and revokes it after
the job. The workflow's own `GITHUB_TOKEN` stays read-only. An App token lets
Renovate PRs trigger CI, unlike writes made with `GITHUB_TOKEN`.

Manual dispatch defaults to `dry_run: true`: it validates config and runs the
engine with a read-only token, without needing App credentials. To activate,
run once with `dry_run: false` after configuring the App. A missing ID or key
fails that live run with an explicit setup error. A successful live job and an
App-authored Dependency Dashboard or PR are activation evidence; a green dry
run is not. The dashboard exposes pending updates, release-age waits, and
failures even when no PR is ready.

Until those credentials exist and a live run succeeds, updating remains blocked.
Setup is not evidence that Renovate has actually written to GitHub.

### Almanac pilot

[`martinemde/almanac`](https://github.com/martinemde/almanac) complements Renovate;
it does not discover dependency updates. Start with its standalone `report` verb,
not the repair daemon. This verb cannot write or call a model and needs no database,
broker, webhook ingress, or sandbox. Full deployment is deliberately deferred.

The report needs `ALMANAC_OWNER=martinemde`, `ALMANAC_READ_ONLY=1`, and
`ALMANAC_RENOVATE_AUTHOR` matching the new Renovate App's actual bot login.
Authentication accepts either `GITHUB_TOKEN` or the App ID, installation ID, and
private key through `GITHUB_APP_*`. Keep credentials out of this repository.
Do not copy the personal CLI OAuth token into automation.

The report scans accessible owner repositories; it does not support a repository
filter. App authentication installed on one selected repository is the cleanest
one-repository pilot. Actions' repository `GITHUB_TOKEN` is not a drop-in: token
authentication uses the user repositories endpoint. Verify the report with actual
PRs before scheduling it; an empty result does not prove PR evaluation works.

No Almanac binary or reporting service is deployed here yet. After Renovate's App
and bot login are established, build the report binary from reviewed, pinned source
and choose its execution host. Use only the report verb; no repair, merge, or live
mode is authorized by this pilot. Broader vulnerability inventory and advisory
matching remain on Almanac's roadmap, so this is not a replacement security scanner.

## Update Security Decisions

New releases wait seven days before Renovate proposes them. Missing timestamps are
not accepted (`minimumReleaseAgeBehaviour: timestamp-required`), and strict internal
checks suppress pending versions. Existing update grouping remains restricted to the
same update types; minor, patch, and digest updates can automerge after CI. A delay is not a signature
or a vulnerability scan.

Known vulnerability fixes bypass the release delay, normal schedule, and normal
PR limits using Renovate's built-in vulnerability-alert defaults. They keep manual
review and gain a `security` label. This was already Renovate's default exception;
we make the release-age exception explicit rather than claim a new fast path.
Enable the GitHub dependency graph and Dependabot alerts, and grant Renovate read
access to those alerts. Repository config alone cannot enable those settings.
OSV alerts supplement GitHub alerts for direct npm, PyPI, Go, and other supported
ecosystem dependencies. OSV support is experimental; it does not scan Homebrew,
GitHub release binaries, Docker images, or arbitrary plugin commits. Alerts appear
on the next Renovate run, not as a guaranteed real-time response.

Sources: [vulnerability alerts](https://docs.renovatebot.com/configuration-options/#vulnerabilityalerts),
[OSV coverage](https://docs.renovatebot.com/configuration-options/#osvvulnerabilityalerts).

The GitHub SHA managers use `github-digest`, not `git-refs`, because only the former
provides commit timestamps. This uses the commit date, not when a branch first
pointed at that commit. It is not proof that a commit is safe. The root npm manifest
and templated Aqua pins are explicitly discovered; neither was reliably covered
before these changes.

Zellij release URLs and adjacent `checksum.sha256` fields are extracted together
using `github-release-attachments`. Renovate identifies the old asset by its hash
and computes the next release asset hash, including releases without a GitHub API
digest. Minor, patch, and digest updates automerge after CI. CI downloads the exact URLs and verifies
their pinned SHA256 values. Upstream can return the old digest if it cannot map the
old asset; CI rejects a resulting URL/hash mismatch. Keep URL and checksum adjacent.
Review both fields and upstream release changes before merging. These are integrity
checks, not signed provenance; a compromised upstream can publish malicious bytes
and a matching hash.

Project `mise.lock` refresh is explicit: use the command in `docs/mise.md` with the
seven-day delay after changing `.mise.toml`. Native Renovate lockfile refresh exists,
but requires operator authorization for unsafe execution. It is not enabled here:
the hosted runner's authorization and delay propagation have not been verified.
Renovate's release-age check does not cover `lockFileMaintenance`, so ordinary
Renovate age settings would not secure that refresh command. Do not enable
`allowedUnsafeExecutions` or arbitrary post-upgrade commands merely to bypass
that boundary. The user Go template has no committed lock yet; `latest`
there is not a reproducible pin.

Sources: [release age](https://docs.renovatebot.com/configuration-options/#minimumreleaseage),
[GitHub digest](https://docs.renovatebot.com/modules/datasource/github-digest/),
[attachment digest implementation](https://github.com/renovatebot/renovate/blob/main/lib/modules/datasource/github-release-attachments/index.ts),
[mise lock trust model](https://docs.renovatebot.com/modules/manager/mise/#trust-model-for-lock-file-updates).

---

## Custom Version Manifests

These files purposely centralize versions so Renovate can update them automatically:

- `home/dot_config/dotfiles/cli-versions.toml`
  - Holds pinned CLI versions used by the installer and scripts.
  - Currently: `cosign` (used for signature verification). Renovate updates via GitHub Releases.

- `.mise.toml` and `home/dot_config/mise/config.toml.tmpl`
  - Define tool versions managed by [mise]. Most user tools intentionally track `latest`; behavior-sensitive tools are pinned.
  - Supports native mise tools (e.g., `python = "3.13.7"`) and the explicit Aqua backend (`"aqua:owner/repo"`).
  - Renovate updates native project tools via the Mise manager and Aqua-prefixed template pins via a custom regex manager (GitHub Releases datasource). The native manager cannot parse the Go template.

- `home/dot_config/dotfiles/requirements.txt`
  - Pinned versions for Python tools (installed via uv tool install). Updated by Renovate's pip manager.

- `home/dot_config/dotfiles/package.json`
  - Pinned versions for Node.js CLI tools (installed globally via Bun). Updated by Renovate's npm manager.

- `home/dot_pi/private_agent/settings.json`
  - Pins Pi extension packages as `npm:<package>@<version>`.
  - Pi's extension updater skips exact npm pins, so Renovate is the intentional upgrade path.

- `.devcontainer/devcontainer.json`
  - Base image and all features pinned to immutable `@sha256:` digests. Updated by `devcontainer` manager.

- `home/dot_config/docker-compose/*.yml`
  - Service images pinned with tag+digest (e.g., `image: repo:tag@sha256:...`). Digest updates require review.

- `home/.chezmoiexternals/*.externals.toml`
  - All externals pinned to commit SHAs (archive or raw URLs) or release tags for reproducibility.

---

## Custom Managers (Regex + Datasources)

Using Renovate’s `customManagers` to teach it how to parse and update versions in nonstandard files.

Defined in `renovate.json5`:

1. CLI versions (GitHub Releases)

- File: `home/dot_config/dotfiles/cli-versions.toml`
- Pattern: `(?:^|\n)cosign\s*=\s*"(?<currentValue>v?[^\"]+)"`
- Datasource: `github-releases`, `depNameTemplate: sigstore/cosign`
- Note: line-anchored via `(?:^|\n)`, not an inline `(?m)` flag. `renovate-config-validator` (and Renovate itself when the native `re2` binding is unavailable) falls back to JS `RegExp`, which rejects inline flags like `(?m)`. Avoid `(?m)`/`(?s)`/`(?i)` in `matchStrings` so managers validate under both engines.

2. Aqua-prefixed tools in mise TOML (GitHub Releases)

- Files: `.mise.toml`, `home/dot_config/mise/config.toml.tmpl`
- Pattern: `"aqua:(?<depName>[^/]+/[^\"]+)"\s*=\s*"(?<currentValue>v?[^\"]+)"`
- Datasource: `github-releases` (e.g., `aqua:mikefarah/yq` → `mikefarah/yq`)

3. Optional Go/Node tool manifests (present if we add these files later)

- Go tools file: `home/dot_config/go-tools/tools.txt`
  - Pattern: `^(?<depName>[^\s@]+)@(?<currentValue>v?[^\s#]+)`
  - Datasource: `go`

- Node tools file: `home/dot_config/node-tools/tools.txt`
  - Pattern: `^(?<depName>[^@\n]+)@(?<currentValue>[^\n#]+)`
  - Datasource: `npm`

4. Pi extension packages (npm)

- File: `home/dot_pi/private_agent/settings.json`
- Pattern: `"npm:(?<depName>...)@(?<currentValue>...)"`
- Datasource: `npm`
- Package rule: group as `pi-extensions`; automerge minor, patch, and digest updates after CI

5. Chezmoi externals pinned to SHAs (GitHub Digest)

- Files: `home/.chezmoiexternals/*.externals.toml`, one custom manager per dependency
- Datasource: `github-digest` with `currentValueTemplate: "master"` or `"main"`. This preserves commit timestamps for the release-age check; `git-refs` has no timestamps.

6. Zellij release assets (GitHub Release Attachments)

- File: `home/.chezmoiexternals/zellij.externals.toml`
- Match the release URL and its adjacent SHA256 as one dependency.
- Datasource: `github-release-attachments`; versioning: `loose`.
- Package rule: group as `zellij-plugins`; automerge minor, patch, and digest updates after CI.
- Verify proposed pairs with `python3 bin/check-zellij-plugins` (also run in CI).

Each external has its own `customManagers` entry in `renovate.json5`, keyed to the file and URL it pins.

Note: When adding new externals, add a matching regex rule so Renovate can keep their SHAs fresh automatically.

---

## End‑to‑End Flow (What Renovate Updates)

- Docker/Devcontainer: reviewed PRs updating digests or minor/patch releases.
- GitHub Actions: digest pinning and minor/patch updates grouped for review.
- Python tools: PRs update `requirements.txt` pinned versions.
- Node.js tools: PRs update `package.json` pinned versions.
- Mise tools: PRs update `.mise.toml` and `home/dot_config/mise/config.toml.tmpl` pins.
- CLI versions: PRs update `cli-versions.toml` (e.g., `cosign`).
- Chezmoi externals: PRs replace commit SHAs in tarball URLs or `revision = "..."`.
- Pi extensions: PRs update exact npm pins in `home/dot_pi/private_agent/settings.json`.

---

## How to Add or Change Pins

- Add a new mise tool:
  - Native: add to `[tools]` with an exact version (e.g., `shfmt = "v3.12.0"`).
  - Aqua‑sourced: use `"aqua:owner/repo" = "vX.Y.Z"` to source releases from GitHub.
  - Renovate will propose version bumps automatically.

- Add a new CLI pin managed by scripts:
  - Add an entry to `home/dot_config/dotfiles/cli-versions.toml`.
  - Add code to read it where needed (e.g., `install.sh` reads `cosign`).
  - Add a `customManagers` regex rule if it’s not a standard ecosystem.

- Add a new Chezmoi external:
  - Pin to a specific commit SHA (tarball URL or `revision = "<sha>"`).
  - Add a matching `customManagers` rule using `github-digest` and an `owner/repo` package name so Renovate can update it with commit timestamps.

- Docker/Devcontainer:
  - Keep tag+digest pattern for images and features.
  - Renovate will update digests; human‑readable tag remains for clarity.

---

## Handy gh / gh api Commands

Latest release tag for a repo:

```bash
gh release view -R owner/repo --json tagName,url,publishedAt
# or
gh api repos/owner/repo/releases/latest --jq .tag_name
```

List recent tags:

```bash
gh api repos/owner/repo/tags?per_page=10 --jq '.[].name'
```

Resolve a tag to a commit SHA (works for most tags):

```bash
# 1) Direct ref resolution via commits endpoint
gh api repos/owner/repo/commits/v1.2.3 --jq .sha

# 2) For annotated tags, dereference the tag object to the commit:
tag_obj_sha=$(gh api repos/owner/repo/git/ref/tags/v1.2.3 --jq .object.sha)
gh api repos/owner/repo/git/tags/$tag_obj_sha --jq .object.sha
```

Get the latest commit on a branch (e.g., master/main):

```bash
gh api repos/owner/repo/commits/master --jq .sha
# or
gh api repos/owner/repo/commits/main --jq .sha
```

Show the latest 5 commits on a branch:

```bash
gh api repos/owner/repo/commits --method GET -F sha=master -F per_page=5 --jq '.[].sha'
```

Inspect release assets (e.g., to locate binary names/checksums):

```bash
gh api repos/owner/repo/releases/latest --jq '.assets[].name'
```

Examples (from this repo’s usage):

```bash
# Cosign release tag
gh api repos/sigstore/cosign/releases/latest --jq .tag_name

# Chezmoi externals (current master SHA to pin)
gh api repos/zsh-users/zsh-autosuggestions/commits/master --jq .sha
gh api repos/zsh-users/zsh-syntax-highlighting/commits/master --jq .sha
```

---

## Maintenance Tips

- Keep behavior-sensitive versions pinned. `latest` in the user mise template is intentional and is not controlled by Renovate.
- When adding a new external or bespoke versions file, add a matching `customManagers` rule.
- Keep tag+digest for images: readable tag for humans, digest for reproducibility.
- Use the gh commands above to sanity‑check SHAs/tags when reviewing Renovate PRs.
