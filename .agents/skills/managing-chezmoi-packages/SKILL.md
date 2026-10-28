---
name: managing-chezmoi-packages
description: Use when adding, updating, pinning, or removing a package, tool, image, GitHub Action, or chezmoi external in this dotfiles repo. Picks the right manifest, pins an immutable version/digest/SHA, and keeps the matching Renovate rule in sync.
---

# Managing packages in this repo

Pin to an immutable reference (version, `tag@sha256:` digest, or commit SHA) and make sure
Renovate can update it. Read the target manifest and `renovate.json5` before editing, and
match the neighbouring entries.

| What                                      | Manifest                                                    | Renovate                                    |
| ----------------------------------------- | ----------------------------------------------------------- | ------------------------------------------- |
| macOS brew/cask (unversioned)             | `home/dot_Brewfile`                                         | none                                        |
| Mac App Store (unversioned)               | `home/dot_Brewfile.mas`                                     | none                                        |
| CLI tools (user)                          | `home/dot_config/mise/config.toml.tmpl` (`aqua:owner/repo`) | custom regex for `aqua:` lines (see below)  |
| CLI tools (this repo)                     | `.mise.toml`                                                | same                                        |
| Python tools                              | `home/dot_config/dotfiles/requirements.txt`                 | pip_requirements                            |
| Docker / devcontainer images              | `home/dot_config/docker-compose/*.yml`, `.devcontainer/`    | built-in; keep `tag@sha256:`                |
| GitHub Actions                            | `.github/workflows/*.yml`                                   | built-in; pin to SHA with a version comment |
| Installer-managed CLIs                    | `home/dot_config/dotfiles/cli-versions.toml`                | one custom regex per tool                   |
| Files, archives, repos fetched by chezmoi | `home/.chezmoiexternals/<program>.externals.toml`           | one custom regex per dependency             |

The user mise config tracks `latest` by default; a tool is pinned only when something depends
on its behaviour, with a `# Pinned:` comment saying what. The `aqua:` Renovate regex's
`fileMatch` lists `config.toml`, not `config.toml.tmpl`, so it does not see those pins yet.

## Chezmoi externals

Group by program in `home/.chezmoiexternals/<program>.externals.toml`. Existing entries pin a
GitHub archive or raw URL to a 40-char commit SHA, or a release download URL to a tag, with a
comment block (purpose, `# renovate: repo=… branch=…`). The comment is documentation only;
what Renovate reads is a `customManagers` entry in `renovate.json5` whose `fileMatch` names that
file and whose regex captures the SHA (`git-refs`, `currentValueTemplate` = tracked branch) or
the tag (`github-releases`). Add that entry with every new external.

A script that hashes an externals file (`{{ include … }}`) re-runs when it changes; grep for
references before moving or renaming one.

## Verify

- Resolve the pin from the source (`gh api repos/O/R/commits/BRANCH --jq .sha`,
  `gh api repos/O/R/releases/latest --jq .tag_name`, `docker buildx imagetools inspect`).
- `chezmoi diff <target>` renders the change; `bats test/` covers templates and scripts.
- Check the Renovate regex actually matches the new line (test it against the file contents).
- Don't run `brew`, `mise install`, or `chezmoi apply` without permission.
