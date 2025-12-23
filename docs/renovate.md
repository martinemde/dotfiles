# Renovate: How This Repo Manages Versions

This guide explains how Renovate is configured in this repository, how the custom version manifests work, and when/how to add or update pinned versions. It also includes handy `gh`/`gh api` commands to look up latest tags and resolve commit SHAs.

## TL;DR

- Renovate config lives at `renovate.json5` and runs weekly (before 9am Monday), opening labeled PRs (`deps`, `automated`) with low concurrency.
- We pin everything important to immutable versions or digests for reproducibility and supply‑chain safety.
- Standard managers are enabled (pip, mise, docker-compose, devcontainer, actions) and custom regex managers were added for Chezmoi externals and select version files.
- Renovate updates these pins automatically and groups safe updates for fast review/automerge.

---

## Configuration Overview

File: `renovate.json5`

- Extends: `config:recommended`, `:semanticCommits`, `:disableDependencyDashboard`
- Schedule: `before 9am on monday`
- Labels: `deps`, `automated`
- PR limits: `prHourlyLimit: 2`, `prConcurrentLimit: 5`

Enabled managers and file discovery:

- `pip_requirements`: `home/dot_config/dotfiles/requirements.txt`
- `npm`: `home/dot_config/dotfiles/package.json`
- `mise`: `.mise.toml`, `home/dot_config/mise/config.toml`
- `docker-compose`: `home/dot_config/docker-compose/*.yml`
- `devcontainer`: `.devcontainer/devcontainer.json`
- `github-actions`: `.github/workflows/*.yml` (with digest pinning)

Grouping and automerge rules:

- `github-actions`: group by manager, automerge minor/patch/digest
- `devcontainer`: group by manager, automerge minor/patch/digest
- `docker-compose`: group by manager, automerge digest updates
- `pip_requirements`: grouped as `python-tools` (no automerge)
- `npm`: grouped as `node-tools` (no automerge)
- `mise`: grouped as `mise-tools` (no automerge)

Why: high-signal, low-risk updates (actions/devcontainer/digests) are auto‑merged to keep things current; others require review.

---

## Custom Version Manifests

These files purposely centralize versions so Renovate can update them automatically:

- `home/dot_config/dotfiles/cli-versions.toml`
  - Holds pinned CLI versions used by the installer and scripts.
  - Currently: `cosign` (used for signature verification). Renovate updates via GitHub Releases.

- `.mise.toml` and `home/dot_config/mise/config.toml`
  - Define tool versions managed by [mise]. Pins explicit versions (no `latest`).
  - Both native mise tools (e.g., `python = "3.13.7"`) and Aqua‑sourced tools (`"aqua:owner/repo" = "vX.Y.Z"`).
  - Renovate updates native mise tools via the Mise manager, and Aqua‑prefixed tools via a custom regex manager (GitHub Releases datasource).

- `home/dot_config/dotfiles/requirements.txt`
  - Pinned versions for Python tools (installed via uv tool install). Updated by Renovate's pip manager.

- `home/dot_config/dotfiles/package.json`
  - Pinned versions for Node.js CLI tools (installed globally via npm). Updated by Renovate's npm manager.

- `.devcontainer/devcontainer.json`
  - Base image and all features pinned to immutable `@sha256:` digests. Updated by `devcontainer` manager.

- `home/dot_config/docker-compose/*.yml`
  - Service images pinned with tag+digest (e.g., `image: repo:tag@sha256:...`). Digest updates are auto‑merged.

- `home/.chezmoiexternal.toml.tmpl`
  - All externals pinned to commit SHAs for reproducibility.
  - Tarball archives pinned in the URL with commit SHA; git repo pinned via `revision = "<sha>"`.

---

## Custom Managers (Regex + Datasources)

Using Renovate’s `customManagers` to teach it how to parse and update versions in nonstandard files.

Defined in `renovate.json5`:

1. CLI versions (GitHub Releases)

- File: `home/dot_config/dotfiles/cli-versions.toml`
- Pattern: `^cosign\s*=\s*"(?<currentValue>v?[^\"]+)"`
- Datasource: `github-releases`, `depNameTemplate: sigstore/cosign`

2. Aqua‑prefixed tools in mise TOML (GitHub Releases)

- Files: `.mise.toml`, `home/dot_config/mise/config.toml`
- Pattern: `"aqua:(?<depName>[^/]+/[^\"]+)"\s*=\s*"(?<currentValue>v?[^\"]+)"`
- Datasource: `github-releases` (e.g., `aqua:mikefarah/yq` → `mikefarah/yq`)

3. Optional Go/Node tool manifests (present if we add these files later)

- Go tools file: `home/dot_config/go-tools/tools.txt`
  - Pattern: `^(?<depName>[^\s@]+)@(?<currentValue>v?[^\s#]+)`
  - Datasource: `go`

- Node tools file: `home/dot_config/node-tools/tools.txt`
  - Pattern: `^(?<depName>[^@\n]+)@(?<currentValue>[^\n#]+)`
  - Datasource: `npm`

4. Chezmoi externals pinned to SHAs (Git Refs)

- File: `home/.chezmoiexternal.toml.tmpl`
- Datasource: `git-refs` with `currentValueTemplate: "master"` (we track the upstream default branch and replace our pinned SHA when the branch moves).

Current rules:

- oh-my-zsh tarball: `ohmyzsh/ohmyzsh/archive/(?<currentDigest>[a-f0-9]{7,40})\.tar\.gz`
- zsh‑autosuggestions tarball: `zsh-users/zsh-autosuggestions/archive/(?<currentDigest>[a-f0-9]{7,40})\.tar\.gz`
- zsh‑syntax‑highlighting tarball: `zsh-users/zsh-syntax-highlighting/archive/(?<currentDigest>[a-f0-9]{7,40})\.tar\.gz`
- gpakosz/.tmux repo revision: `^\s*revision\s*=\s*"(?<currentDigest>[a-f0-9]{7,40})"`

Note: When adding new externals, add a matching regex rule so Renovate can keep their SHAs fresh automatically.

---

## End‑to‑End Flow (What Renovate Updates)

- Docker/Devcontainer: PRs updating only digests or minor/patch releases; digests grouped and auto‑merged.
- GitHub Actions: digest pinning and minor/patch updates grouped and auto‑merged.
- Python tools: PRs update `requirements.txt` pinned versions.
- Node.js tools: PRs update `package.json` pinned versions.
- Mise tools: PRs update `.mise.toml` and `home/dot_config/mise/config.toml` pins.
- CLI versions: PRs update `cli-versions.toml` (e.g., `cosign`).
- Chezmoi externals: PRs replace commit SHAs in tarball URLs or `revision = "..."`.

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
  - Add a matching `customManagers` rule using `git-refs` so Renovate can update it.

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
gh api repos/ohmyzsh/ohmyzsh/commits/master --jq .sha
gh api repos/zsh-users/zsh-autosuggestions/commits/master --jq .sha
gh api repos/zsh-users/zsh-syntax-highlighting/commits/master --jq .sha
gh api repos/gpakosz/.tmux/commits/master --jq .sha
```

---

## Maintenance Tips

- Prefer explicit versions over `latest`; let Renovate do the bumping.
- When adding a new external or bespoke versions file, add a matching `customManagers` rule.
- Keep tag+digest for images: readable tag for humans, digest for reproducibility.
- Use the gh commands above to sanity‑check SHAs/tags when reviewing Renovate PRs.
