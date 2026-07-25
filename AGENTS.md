# AGENTS.md

Personal dotfiles managed by Chezmoi across macOS, Linux, and containers. Installation and
per-tool notes live in `README.md` and `docs/`.

## Edit source files, not installed files

Chezmoi copies `home/` to `~/`. Edits to `~/` are overwritten on the next `chezmoi apply`,
so always work in `home/dot_config/nvim/...`, never `~/.config/nvim/...`. This applies to
anything under `home/`, including the Claude config in `home/dot_claude/`.

Preview with `chezmoi diff`, apply with `chezmoi apply [target_path]`.

## Gotchas

- `sourceDir = "{{ .chezmoi.workingTree }}"` — the source state is the repo root itself, not
  a copy under `~/.local/share/chezmoi`. `chezmoi edit` and `chezmoi apply` operate on the
  checkout you're already in.
- Prettier is managed through the root `package.json` rather than mise, so that its plugins
  can be installed alongside it. `bun run format` / `bun run format:check`.
- `.prettierignore` excludes `.tmpl` files — Go template syntax isn't valid in most target
  languages, so formatting them corrupts them.
- Use `bun` for Node package operations, never `npm` or `yarn`.
- `run_onchange_*` scripts re-execute when their rendered content changes, so a script that
  interpolates a version string reruns on version bumps. That's the mechanism for triggering
  reinstalls; incidental whitespace edits trigger it too.
- `home/dot_config/zsh/functions/` holds autoloaded zsh functions, one function per file
  named after the function.
- `private_` prefixed files are encrypted in the source state and hold credentials.
- The installer verifies GitHub release signatures with cosign by default and falls back to
  checksums; `VERIFY_SIGNATURES=false` skips both. Downloads added to `install.sh` are
  expected to go through that path rather than a bare `curl`.

## Packages, images, and versions

Anything that pins a version, digest, or SHA goes through the Package Manager agent or the
`chezmoi` skill: Homebrew/cask/mas packages, mise tool declarations, Python requirements,
Docker and devcontainer images, chezmoi externals, GitHub Actions, and the installer's
version manifests. They enforce immutable pins and keep the matching Renovate rules in
sync. See `docs/renovate.md`.

## Testing

`bats test/` for everything, `bats test/file.bats` for one file, `-t` for verbose. Tests
validate template rendering and script syntax via `test_helper.bash` helpers such as
`assert_valid_shell()` and `assert_script_structure()`.

## Conventions

- Conventional Commits: `feat:`, `fix:`, `chore:`.
- Scripts are idempotent, start with `set -o errexit -o nounset`, honor `DEBUG`, and check
  for a tool before using it.
- Debugging: `DEBUG=1 ./install.sh`, `DEBUG=1 chezmoi apply -v`.

## Documentation

`docs/` records why a decision was made — the problem it solved, the alternatives rejected,
the sources that influenced it, and what was deliberately left out. Amend it when a change
alters one of those. Feature descriptions, usage instructions, and implementation detail
belong in the code or `README.md` instead. These are notes to self, so keep them terse and
skip the promotional register.
