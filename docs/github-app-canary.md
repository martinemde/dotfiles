# Thria GitHub App cutover

Thria now uses the local GitHub App user-token broker for ordinary gh/Git/jj/mise.
This keeps martinemde attribution without relying on the broad GitHub CLI OAuth grant.
Only hosts with the installed `/usr/local/lib/gh-app-broker` marker use this routing;
hostnames do not select authentication. Hosts without that marker keep their existing
routing. Selection happens when Chezmoi renders: install the broker, then apply the
managed targets. Socket presence and service health never select a fallback.

Wrappers must outrank mise shims after both .zshenv and interactive activation. Inside the
mise wrapper/broker installer only, /usr/bin comes first so native mise writes tool shims
pointing at /usr/bin/mise, not the wrapper. Otherwise jj probing recursively re-enters the
broker wrapper and tool basenames are lost. MISE_BIN_PATH does not override PATH-based
shim selection in 2026.11.5. This does not reorder the caller's interactive PATH; child
helpers may prefer distro tools until mise builds a managed environment. The op gh
alias is removed with the installed broker, but other op integrations remain. The
managed mise installer
calls app-run directly instead of discovering a personal token or allowing anonymous mode.
Its tool versions/security settings are not changed by the cutover.

Native Git needs its own helper policy: it does not run through app-run. The root app
helper returns quit=true on broker failure, preventing later helpers and prompts. A
broker-only shell adapter also returns quit=true when that helper executable is missing;
missing gh/mise clients fail at their absolute paths. This covers absent clients and a
stopped broker, not every damaged installation or explicit credential override. Gist
HTTPS is intentionally unsupported/fail-closed. Only the three exact GitHub SSH prefixes
rewrite to HTTPS; other SSH hosts are unchanged. Explicit per-repo overrides/native binary
paths are cooperative-routing exceptions, not a security sandbox.

The rollout began as a Thria-only canary (#10). Live evidence includes genuine token
expiry and unattended renewal, private Git/jj operations, and a checksum-verified
private mise download (#7). The dotfiles integration was published and applied only
on Thria (#12), with scripts excluded. Installer fixtures do not establish that the
managed installer ran live.

On 2026-11-26, native `gh` logout removed the old local GitHub CLI OAuth credential
on Thria (#8). After logout, a fresh login verified App-backed gh, Git, jj, and mise;
all four failed closed without askpass while the broker was stopped and recovered
after restart. No other hosts were changed. The upstream OAuth grant has not been
revoked; identifying and revoking that exact grant is separate work (#9).

For recovery, reauthorize the App. The nonsecret rollback snapshot only restores the
old configuration files, not the removed login. Historical canary evidence and
rollback details are in the broker checkout's `docs/canary-cutover.md` and Skift #10.
A fresh login is required to pick up `gh-app-clients` membership: restart long-running
terminal or agent processes from that login rather than just restarting zsh.
