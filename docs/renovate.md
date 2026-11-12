# Renovate: How This Repo Manages Versions

This guide explains how Renovate is configured in this repository, how the custom version manifests work, and when/how to add or update pinned versions. It also includes handy `gh`/`gh api` commands to look up latest tags and resolve commit SHAs.

## TL;DR

- Renovate config lives at `renovate.json5` and runs every 30 minutes, opening labeled PRs (`deps`, `automated`) with low concurrency.
- We pin everything important to immutable versions or digests for reproducibility and supply‑chain safety.
- Standard managers are enabled (pip, mise, docker-compose, devcontainer, actions) and custom regex managers cover Chezmoi externals, Pi extensions, and select version files.
- Renovate automerges major, minor, patch, and digest updates after CI. Shared-policy and security-alert updates require review.

---

## Configuration Overview

File: `renovate.json5`

- Extends: `github>martinemde/renovate-config#v1.0.0`; shared policy is versioned and preset updates require review
- Run interval: every 30 minutes; no update-time window
- Labels: `deps`, `automated`
- PR limits: `prHourlyLimit: 2`, `prConcurrentLimit: 5`

Enabled managers and file discovery:

- `pip_requirements`: `home/dot_config/dotfiles/requirements.txt`
- `npm`: `package.json`, `home/dot_config/dotfiles/package.json`
- `mise`: `.mise.toml` and plain `home/dot_config/mise/config.toml`; native extraction covers all tool declarations
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
- Pi extensions: grouped as `pi-extensions`, eligible for automerge
- `custom.jsonata`: tmux plugin repository/branch/commit data in `home/.chezmoidata/tmux-plugins.yaml`
- `renovate-config`: reviewed shared-preset updates; never automatic policy adoption

Minor, patch, and digest updates use Renovate-managed squash merges after required
integrity, ShellCheck, unit, plugin and four tool-integration checks pass. The stable
`test` aggregate also requires all those jobs. Platform automerge is
disabled: Renovate checks and merges on its next run. Initial pin updates, shared-policy
and vulnerability-alert updates remain review-only. The active GitHub ruleset requires each of these checks on `main`; administrators
can still bypass it for direct maintenance.
A matching hash proves byte integrity, not that upstream code is benign.

---

## Shared policy and lock scope

The shared preset separates account-wide policy from dotfiles-specific managers
and compatibility exceptions. Its `v*` tags reject updates/deletion via a no-bypass
ruleset; administrators can still change rules. Consumers track reviewed releases
with Renovate's own config manager, explicitly review-only. Required GitHub checks
and App installation remain per repository, not properties of the preset.

Mise is pinned to 2026.11.1 for CI and Renovate lock generation. Project lock
maintenance is enabled in safe mode. Global lock maintenance stays disabled:
several current tool versions lack desktop-platform assets, and the current
Ansible dependency graph lacks a Python 3.15 wheel. Exact global declarations
are still reviewed updates; they are not a complete transitive lock. See `mise.md`.
The shell template was split into plain tool declarations and a Mac-only environment
fragment so native Renovate can parse and update tools without executing templates.

Branch dependencies continue using `github-digest`, which can retrieve commit
timestamps. Do not assume every datasource publishes timestamps: strict missing-time
handling holds updates pending. A weekly batch is a scheduling choice, not a
substitute for the seven-day quarantine, so we retain the current commit-age policy.

## Self-hosted activation and visible evidence

The **Renovate** Actions workflow is the intended writer. It runs at minutes 7 and 37 of every hour
UTC, with no separate update-time window so dashboard requests and passing CI
can be processed on the next run. The hosted Mend App is not required;
do not enable both writers. Local overrides permit major updates and shorten core-tool
aging; the shared preset retains conservative defaults for other consumers.

The same workflow also runs against `martinemde/martinemde.com`, using the blog's
own Renovate config rather than the dotfiles-specific managers. Separate matrix
jobs keep a blog failure from stopping dotfiles updates. Each job gets a token
scoped to its target repository; the existing App credentials stay in dotfiles.

The existing GitHub App installation has account-wide repository access. The
workflow deliberately targets only `martinemde/dotfiles` and
`martinemde/martinemde.com`, and requests a single-repository token per job.
The account owner must create and install it through GitHub's authenticated web
settings; the current CLI OAuth token cannot create an App or its private key.
Do not copy the CLI's broad personal OAuth token into an Actions secret.

1. In [personal developer settings](https://github.com/settings/apps), create a new
   GitHub App owned by `martinemde`, not an organization. Give it a distinct name
   and this repository's URL as its homepage. Disable the webhook; no callback
   or user authorization is needed for installation tokens.
2. Allow installation only on this account. Grant these repository permissions:

- Contents, pull requests, issues, workflows, and commit statuses: read and write.
- Administration, checks, and Dependabot alerts: read. Metadata read is automatic.

These narrow [Renovate's GitHub App permissions](https://docs.renovatebot.com/modules/platform/github/#running-as-a-github-app)
to this review-only setup: CI owns checks; Renovate publishes release-age commit statuses. Organization membership
and merge queues are not used here.

3. Install the App on `martinemde`. It currently has access to all repositories,
   so adding the blog needs no installation or credential changes. For a new,
   narrower installation, select only **dotfiles** and **martinemde.com**.
   Disable or deselect both repositories in the hosted Mend Renovate App
   installation before enabling this writer.
4. In the new App's settings, generate and download a private key. In the
   repository's **Settings → Secrets and variables → Actions**, add secret
   `RENOVATE_APP_PRIVATE_KEY` containing the complete PEM file. Add repository
   variable `RENOVATE_APP_ID` containing the App ID (not its installation ID).
   Set the ID last: scheduled runs are skipped while it is absent, avoiding
   repeated credential failures. Keep the private key out of the repository and
   logs; remove any unneeded local copy after storing it securely.

The token action limits each installation token to the matrix target repository,
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

Mise, chezmoi, uv, and Bun use a 12-hour delay; other releases retain seven days.
This explicit core-tool list trades quicker fixes for less observation time. It is
not a claim that core tools are immune to compromise. Missing timestamps are
not accepted (`minimumReleaseAgeBehaviour: timestamp-required`), and strict internal
checks suppress pending versions. Existing update grouping remains restricted to the
same update types; major, minor, patch, and digest updates can automerge after CI. A delay is not a signature
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

Project `mise.lock` refresh uses Renovate's supported `MISE_SAFE=1` path with
mise 2026.11.1; arbitrary unsafe execution is not enabled. Renovate does not pass
`MISE_MINIMUM_RELEASE_AGE` to its safe-mode artifact command, and safe mode ignores
project settings. Lock maintenance therefore has no independent seven-day age
guarantee. Current project declarations are all exact pins; declaration updates
still use Renovate's quarantine. Review generated checksum/provenance changes,
and do not introduce floating project constraints without resolving this gap.
Global locks remain deferred for the concrete platform/graph gaps in `mise.md`.

Sources: [release age](https://docs.renovatebot.com/configuration-options/#minimumreleaseage),
[GitHub digest](https://docs.renovatebot.com/modules/datasource/github-digest/),
[attachment digest implementation](https://github.com/renovatebot/renovate/blob/main/lib/modules/datasource/github-release-attachments/index.ts),
[mise lock trust model](https://docs.renovatebot.com/modules/manager/mise/#trust-model-for-lock-file-updates).

---

## Functional merge checks

The required `test` check aggregates the unit suite, download integrity,
ShellCheck, tool integrations, and the zsh-snap integration. Failed, cancelled,
or skipped dependencies block it. New tools need their own behavior checks;
a green suite does not establish compatibility for dependencies it never runs.

Tool checks install from the PR checkout into temporary directories. They exercise
Prettier with the project and user plugins (JS, TOML, Tailwind HTML), Bun execution,
shfmt formatting, transcript JSONL-to-HTML conversion, and authenticated Cosign
release downloads followed by local signing, verification, and tamper rejection.
The zsh-snap check renders the actual tools config, runs cached initialization
across shells, and verifies regeneration after removing a cache. Tool-init output
is a fixture; the cache implementation is real. Renovate config is validated by
the same container image used for live updates, with semantic extraction/policy
tests that also accept its config migration.

Linux GHA is the required target. Local tests passed for current tool versions,
proposed formatter/transcript/Cosign versions, and zsh-snap; Linux outcomes must
be checked after deployment. Runtime Node keeps seven days; uv uses 12 hours. Downloads require the network; test workloads use local fixtures,
not model accounts, cloud signing, or GitHub writes. Checkout and mise-action
updates exercise themselves in CI. Claude authentication and live Renovate writes
still require observing those workflows, not merely this suite.

Pi and Zellij updates are eligible for automerge despite incomplete runtime coverage.
For these personal dotfiles, normal use detects failures that CI cannot, and exact
pins allow rollback. Manual version review would not prove compatibility. Stock Pi 0.79.7 lacks lifecycle events required by the terminal-title
extension; its existing optional integration tests expose that incompatibility.
Zellij status rendering was observed, but the autolock transition test remains
unvalidated. Those draft tests are not required gates. Major updates can automerge;
security alerts and shared-policy changes still require review. PR limits are unchanged.
A green run is compatibility evidence, not a security audit or a Mac visual check.

## Custom Version Manifests

These files purposely centralize versions so Renovate can update them automatically:

- `home/dot_config/dotfiles/cli-versions.toml`
  - Holds pinned CLI versions used by the installer and scripts.
  - Currently: `cosign` (used for signature verification). Renovate updates via GitHub Releases.

- `.mise.toml` and `home/dot_config/mise/config.toml`
  - Exact tool versions, discovered by the native mise manager.
  - The initial pins preserve installed versions; Linux eza uses the observed Mac Homebrew version 0.23.5.

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

2. Mise runtime version coordination (GitHub Releases)

- CI mise-action inputs and Renovate's mise constraint update together from `jdx/mise`.
- Native mise extraction replaces the old Aqua-specific regex; each tool is discovered once.

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
- Mise tools: PRs update `.mise.toml` and `home/dot_config/mise/config.toml` pins.
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

- Keep managed tool declarations exact and Renovate-discoverable; review preset and unsupported-runtime changes manually.
- When adding a new external or bespoke versions file, add a matching `customManagers` rule.
- Keep tag+digest for images: readable tag for humans, digest for reproducibility.
- Use the gh commands above to sanity‑check SHAs/tags when reviewing Renovate PRs.
