---
name: managing-chezmoi-packages
description: Use this skill when managing packages, external dependencies, binaries, or CLI tools in a chezmoi dotfiles repository. Handles adding/updating/removing packages in .chezmoidata/packages.yaml, creating .chezmoiexternals/ organized files, pinning versions with Renovate automation, and selecting the correct package ecosystem (Homebrew, mise, Python, Docker, chezmoi externals).
---

# Managing Chezmoi Packages

Adding a dependency here means three things, not one: picking the right ecosystem, pinning it
to something immutable, and making sure Renovate can see the pin. Skip the third and the pin
quietly rots — which is worse than no pin, because it looks maintained.

## Pick the ecosystem first

The wrong manifest usually works on the machine you're sitting at and diverges elsewhere, so
resolve this before editing anything. `./ecosystem-guide.md` covers the trade-offs; the short
version:

| Use case                  | Ecosystem         | Location                                                 |
| ------------------------- | ----------------- | -------------------------------------------------------- |
| macOS packages (Homebrew) | brew/cask/mas     | `home/.chezmoidata/packages.yaml`                        |
| CLI developer tools       | mise (Aqua)       | `.mise.toml` or `home/dot_config/mise/config.toml`       |
| Python tools              | pip               | `home/dot_config/dotfiles/requirements.txt`              |
| Docker/devcontainer       | docker            | `home/dot_config/docker-compose/*.yml`, `.devcontainer/` |
| External files/repos      | chezmoi externals | `home/.chezmoiexternals/*.toml[.tmpl]`                   |
| Install script CLIs       | cli-versions      | `home/dot_config/dotfiles/cli-versions.toml`             |

## Pin immutably

| Type           | Pinning method           | Example                              |
| -------------- | ------------------------ | ------------------------------------ |
| Git repo       | Commit SHA in `revision` | `revision = "abc123..."`             |
| GitHub file    | Commit SHA in URL path   | `raw/<sha>/file.ext`                 |
| Release binary | Version tag + checksum   | `v1.2.3` + `checksum = "sha256:..."` |
| Docker image   | Digest                   | `image:tag@sha256:...`               |

`latest` tags, bare branch names, version ranges, and URLs without a SHA or checksum all
resolve to something different tomorrow. `./externals-reference.md` has the full type
specifications and field semantics.

## Externals live in `.chezmoiexternals/`, grouped by program

Files in `home/.chezmoiexternals/` are each treated as a `.chezmoiexternal.<format>` file, so
one file per program keeps a zsh plugin bump from touching the neovim entries:

```
home/.chezmoiexternals/
├── zsh.externals.toml
├── bat.externals.toml
├── tmux.externals.toml
└── nvim.externals.toml
```

Paths inside each file are relative to home. Add `.tmpl` when the file needs OS conditionals
or template variables. Wrap program-specific groups in a `{{ if lookPath "zsh" }}` guard so a
machine without the tool doesn't download its plugins.

Add a `# renovate:` annotation above each entry that needs one — it's what the custom manager
matches against:

```toml
# renovate: repo=marlonrichert/zsh-snap branch=main
[".zsh/znap/zsh-snap"]
type = "git-repo"
url = "https://github.com/marlonrichert/zsh-snap.git"
revision = "25754a45d9ceafe6d7d082c9ebe40a08cb85a4f0"
refreshPeriod = "168h"
```

`refreshPeriod` trades freshness against startup cost; 168h (weekly) is the default here.

## Wire up Renovate

Check `renovate.json5` for a manager whose `fileMatch` and `matchStrings` already cover the
file and format you used. Homebrew and Docker have built-in datasources and need nothing.
Externals and the version manifests need a custom manager:

```json5
{
  customType: 'regex',
  fileMatch: ['^home/\\.chezmoiexternals/.*\\.toml(\\.tmpl)?$'],
  matchStrings: [
    'revision = "(?<currentDigest>[a-f0-9]{40})".*?# renovate: repo=(?<depName>.*?) branch=(?<currentValue>.*?)\\n',
  ],
  datasourceTemplate: 'git-refs',
}
```

`./renovate-integration.md` has the patterns per ecosystem and how to debug a manager that
isn't matching.

## Verify

```bash
chezmoi diff                                          # preview before applying
gh api repos/USER/REPO/commits/BRANCH --jq .sha       # current SHA for a branch
gh api repos/USER/REPO/releases/latest --jq .tag_name # latest release tag
curl -fsSL https://github.com/USER/REPO/raw/SHA/path  # file exists at that SHA
chezmoi update --force                                # force externals to re-download
```

Preview with `chezmoi diff` before applying, and don't run a package manager's install or
upgrade without the user asking for it.

## Migrating from a single `.chezmoiexternal.toml`

The trap is that other files reference the old path — `run_onchange_` scripts commonly
`{{ include ".chezmoiexternal.toml" }}` to hash it and trigger on change. Search before
moving anything:

```bash
grep -r "\.chezmoiexternal\.toml" home/
```

Then create the per-program files, move entries across keeping their conditionals, update
every reference found above, and confirm `chezmoi diff` succeeds — it errors on a broken
`include`. Delete the old file last.

## Troubleshooting

**External won't download** — check the URL with `curl -fsSL`, confirm the SHA exists with
`gh api repos/USER/REPO/commits/SHA`, then `chezmoi apply -v` for chezmoi's own reasoning.

**Renovate isn't detecting it** — the usual causes are a `fileMatch` glob that misses the
file, a `matchStrings` regex written against a slightly different format than what's in the
file, or a missing `# renovate:` annotation.

**Checksum mismatch** — recompute with `curl -fsSL <url> | shasum -a 256` and confirm the URL
points at the version you think it does.

## Reference files

- `./ecosystem-guide.md` — which ecosystem to use and why, with the trade-offs of each
- `./externals-reference.md` — the four external types, every field, and pinning per type
- `./renovate-integration.md` — custom manager patterns and debugging non-matching managers
