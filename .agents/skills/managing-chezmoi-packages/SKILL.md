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
| CLI tools (user)                          | `home/dot_config/mise/config.toml` (`aqua:owner/repo`) | native mise (explicit source discovery)  |
| CLI tools (this repo)                     | `.mise.toml`                                                | native mise                                 |
| Python tools                              | `home/dot_config/dotfiles/requirements.txt`                 | pip_requirements                            |
| Docker / devcontainer images              | `home/dot_config/docker-compose/*.yml`, `.devcontainer/`    | built-in; keep `tag@sha256:`                |
| GitHub Actions                            | `.github/workflows/*.yml`                                   | built-in; pin to SHA with a version comment |
| Installer-managed CLIs                    | `home/dot_config/dotfiles/cli-versions.toml`                | one custom regex per tool                   |
| Files, archives, repos fetched by chezmoi | `home/.chezmoiexternals/<program>.externals.toml`           | one custom regex per dependency             |

User and project mise declarations use exact versions; Renovate owns updates. Keep
existing active installed versions when converting a declaration, resolving global inventory
outside project directories. Retain `# Pinned:` comments for behaviour dependencies. The
seven-day delay still guards explicitly floating resolutions, while exact pins bypass it;
review their release dates through Renovate's policy. Attested precompiled Python and
signed mise self-updates retain scoped zero-delay exceptions; do not extend those to
optional-attestation backends. See `docs/mise.md` for verification limits.

The native mise manager explicitly discovers `home/dot_config/mise/config.toml`.
Keep tool declarations plain TOML; macOS trust-bundle values live in the separate
`conf.d/10-homebrew.toml.tmpl`, and eza uses `os = ["linux"]`. Do not add a competing
Aqua regex updater. Validate raw tool TOML and both OS env renders after editing.
Project tools have a cross-platform `mise.lock`; global tools do not yet have a
reviewed complete lockfile and native dependency sidecars. Refresh project locks
without installing or upgrading tools:
`MISE_SAFE=1 MISE_MINIMUM_RELEASE_AGE=7d mise lock --platform linux-x64,linux-arm64,macos-x64,macos-arm64`.
Keep verification fields. Global lock generation must be isolated, with platform and
backend coverage checked: a successful command may retain version-only entries after
warnings. Do not enable unsafe Renovate execution or commit a partial result.

During read-only checks set `MISE_AUTO_INSTALL=0` and use already installed executables
directly. A mise shim can otherwise install a newly locked version automatically.

## Chezmoi externals

Group by program in `home/.chezmoiexternals/<program>.externals.toml`. Existing entries pin a
GitHub archive or raw URL to a 40-char commit SHA, or a release download URL to a tag, with a
comment block (purpose, `# renovate: repo=… branch=…`). The comment is documentation only;
what Renovate reads is a `customManagers` entry in `renovate.json5` whose `fileMatch` names that
file and whose regex captures the SHA (`github-digest`, `currentValueTemplate` = tracked branch).
Release binaries need an adjacent `checksum.sha256` pin. Match the URL version and
`currentDigest` together with `github-release-attachments` so Renovate replaces both.
CI verifies the Zellij artifacts with `python3 bin/check-zellij-plugins`. Add the matching
manager and artifact verification with every new executable external. Never fix a mismatch
by accepting new bytes without reviewing the upstream change.

A script that hashes an externals file (`{{ include … }}`) re-runs when it changes; grep for
references before moving or renaming one.

## Verify

- Resolve the pin from the source (`gh api repos/O/R/commits/BRANCH --jq .sha`,
  `gh api repos/O/R/releases/latest --jq .tag_name`, `docker buildx imagetools inspect`).
- `chezmoi diff <target>` renders the change; `bats test/` covers templates and scripts.
- Check the Renovate regex actually matches the new line (test it against the file contents).
- Don't run `brew`, `mise install`, or `chezmoi apply` without permission.
