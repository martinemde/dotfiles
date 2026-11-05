# Mise

Prefer mise for cross-platform CLI tools when its backend supports the tool and
our verification policy. GitHub CLI and stable Neovim use explicit Aqua backends
on macOS and Linux, with the existing seven-day release delay and verification
settings. Homebrew remains for apps and tools where it is the better fit. Do not
add a second Homebrew declaration for these mise-managed tools.

Use mise for versioned tools and runtimes; Homebrew still owns system libraries
and macOS applications. Most global requests stay `latest` so routine updates do
not depend on maintaining dozens of hand-written pins. Behaviour-dependent pins
need a `# Pinned:` reason and Renovate coverage.

## Homebrew audit

CMake and Pandoc join GitHub CLI and Neovim on explicit Aqua backends.
The Aqua registry has macOS/Linux release mappings for both. A trial migration
of eza failed on macOS: its Aqua recipe requires the unsupported Cargo package
type there. Keep macOS eza on Homebrew rather than add a source-build backend.
These tools inherit the same verification settings;
this does not promise signed provenance where upstream does not publish it.

Keep Homebrew libraries, image/media toolchains, login shell, and Redis services.
Keep Colima and Docker together for now: moving just their executables would lose
Homebrew dependency and CLI-plugin wiring (including Lima). Keep mosh and its SSH
integration there too. Do not migrate the remaining tools merely because a generic
npm, pip, Conda, or GitHub backend can download them. Several have no registry entry
or need a separate packaging/verification review: cloc, dotslash, overmind, rbspy,
yamllint, ccusage, mermaid-cli, ruby-build, and ruby-install. Existing nvm setup
also needs a separate shell-configuration migration, not just a Brewfile deletion.

Removing Brewfile declarations does not uninstall existing packages. Homebrew may
still need a formula as another package's dependency; do not force-remove it.

## Download policy

Both configs require mise 2026.10.25, the installed version used to check these
settings. This is a compatibility floor, not a moving dependency pin.

- Resolve floating requests with a seven-day release delay by default.
- Require precompiled CPython and its GitHub artifact attestation. Disable source
  compilation so unavailable precompiled builds fail instead of bypassing that
  check. Python alone opts out of the delay (`minimum_release_age = "0s"`).
- Keep Aqua Cosign, Minisign, SLSA and GitHub attestation checks enabled, along
  with Node verification and Go checksums. These checks depend on what the
  backend and upstream publish; they do not require provenance from every tool.
  In particular, uv stays on Aqua with the delay: enabling attestations does
  not make missing attestations an error there, or on the GitHub backend.
- Fail on provenance API errors rather than silently skipping verification.
- Recheck published provenance at installation even when a lock records it
  (`locked_verify_provenance = true`). This costs extra network requests.

The delay is not a complete quarantine. Exact pins and existing lock entries
bypass it; backends without release timestamps can only warn. Review those cases
rather than assuming the age filter verified them. Installed tools are not
reverified merely because the setting changed.

Python's check authenticates the downloaded artifact as published by
`astral-sh/python-build-standalone`; it accepts any workflow in that repository
and does not require a SLSA build predicate. This is not proof of a trusted build
process. No external custom attestation gate is added.

Native `mise self-update` has its own zero-delay setting. Its signed archives
and required release manifest provide publisher continuity, not a build-provenance
gate. This does not enable self-updates or replace Homebrew/OS package updates;
those keep their own update and verification policy.

## Implicit installation

Keep mise shims on PATH, but require an explicit install. `auto_install = false`
is the master switch for shim/not-found, exec, and task auto-installation in this
mise version; separate per-command switches would duplicate it. Both configs
set the default. Managed `.zshenv` also exports `MISE_AUTO_INSTALL=0` so a project
cannot enable it again for zsh or its descendants. Other launchers need the same
environment setting if project overrides must be blocked. This is a default and
shell policy, not a sandbox: an explicit `mise install`, `mise use`, or an install
command inside a task can still install tools.

`not_found_system_fallback = false` makes a configured shim fail when its version
is missing rather than run an unrelated system executable. It governs shim
resolution, not every PATH lookup: `mise exec` can still use a system executable
when the requested version is absent. It does not disable ordinary system tools.

The offline CLI fixtures use isolated config, cache, state, and a fake old install
to check stale-shim, exec, and task failures without downloading or installing.
They also check that the environment setting wins over project settings.

## Lock scope and updates

The project `mise.lock` covers chezmoi, shfmt, and Bun on Linux x64/arm64 and macOS
x64/arm64. Bun runs the Renovate extraction tests in CI; it is not a global install
side effect. It records release URLs and SHA-256 checksums; chezmoi also records
Cosign verification. The initial shfmt digests were compared with upstream
`sha256sums.txt`, not accepted solely from the mise-versions cache.

Refresh with the no-install command next to `[tools]` in `.mise.toml`. Review the
config and lock together, including after Renovate changes an exact version.
The explicit environment age setting matters because safe mode ignores project
settings. Exact pins still require release-date review. Do not remove a checksum
or provenance field to resolve a refresh failure: establish why upstream bytes
or verification changed first.

Global locks are deliberately deferred. The global source is a Chezmoi Go
template, not parseable mise TOML. Its OS-specific tools also need render-aware
refreshes; npm/PyPI dependency sidecars and Go's version-only lock coverage need
review. Locking every global tool across platforms can download release
artifacts for provenance checks. A partial, unmaintained global lock would hide
stale versions behind `latest` rather than provide a dependable update path.

No `locked = true` or `--locked` enforcement yet. A complete global lock and its
verified refresh path must exist first. The global install script runs from
`$HOME` so this checkout's project lock does not shadow global tools. It uses the
global config's release-age policy rather than a CLI override, which would mask
Python's per-tool exception.

Renovate handles project declarations and the template's explicit Aqua pin.
Native lock refresh needs self-hosted approval for mise execution; this repo
does not enable unsafe execution or assume hosted Renovate can refresh locks.
Project lock refresh is an explicit review step until that is configured.

## Sources

- [mise 2026.10.25 settings](https://github.com/jdx/mise/blob/v2026.10.25/settings.toml)
- [mise 2026.10.25 precompiled Python verification](https://github.com/jdx/mise/blob/v2026.10.25/src/plugins/core/python.rs)
- [mise 2026.10.25 native self-update verification](https://github.com/jdx/mise/blob/v2026.10.25/src/cli/self_update.rs)
- [mise 2026.10.25 lock and provenance behaviour](https://github.com/jdx/mise/blob/v2026.10.25/docs/dev-tools/mise-lock.md)
- [Renovate's mise lock trust model](https://docs.renovatebot.com/modules/manager/mise/#trust-model-for-lock-file-updates)
