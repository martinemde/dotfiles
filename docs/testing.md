# Testing decisions

Run the Bats suite without applying personal dotfiles. CI installs only the
project tools and distribution test dependencies; it must not provision the
runner's home or install global Node packages just to obtain Bats.

On Thria, run with `PATH="/usr/bin:$PATH" bats test/`
to use the distribution Python dependencies and the native mise multicall binary.
The broker wrapper cannot stand in for a native shim in the offline mise fixture.

Configuration checks use real parsers. Template tests supply their source tree
and fixture data explicitly instead of relying on a configured Chezmoi home.
Optional local tools may skip, but CI installs Zsh so shell behavior is exercised.
Run the suite with a fresh HOME when changing test setup: the old full-install
step hid missing fixture data and tmux index assumptions.

Removed checks that only searched for strings, checked file existence, ignored
parser errors, or checked installed package state. Those checks could pass broken
configurations. Behavioral installer tests replace implementation-string checks.
Tmux navigation uses an isolated server; Neovim syntax checks compile Lua without
loading plugins or fetching anything.

The Renovate policy integration uses Docker or Podman and the pinned workflow image.
Its preset resolver reads the shared public preset; run it separately before the
suite and pass `RENOVATE_RESOLVED_CONFIG` to reuse that result without repeating
the external read. No GitHub token is needed for an anonymous public-preset check.

Keep live artifact verification separate from offline tests. Network or upstream
asset failures should be visible without making every configuration test depend
on GitHub availability. Bootstrap tampering and checksum failures use local
fixtures, not real installations.

Deliberately left out: full desktop provisioning, interactive editor integration,
and pretend validation for formats without an available parser. These need manual
checks or a focused test with a meaningful failure condition, not a green badge.
