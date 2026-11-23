# Thria GitHub App canary

Thria now routes ordinary gh/Git/jj/mise through the local user-token broker. This keeps
martinemde attribution without making the broad personal OAuth grant the default. Only
Linux hostname thria changes; other-host rendered behavior remains unchanged.

Wrappers must outrank mise shims after both .zshenv and interactive activation. Inside the
mise wrapper/Thria installer only, /usr/bin comes first so native mise writes tool shims
pointing at /usr/bin/mise, not the wrapper. Otherwise jj probing recursively re-enters the
broker wrapper and tool basenames are lost. MISE_BIN_PATH does not override PATH-based
shim selection in 2026.11.5. This does not reorder the caller's interactive PATH; child
helpers may prefer distro tools until mise builds a managed environment. The op gh
alias is removed on Thria, but other op integrations remain. The managed mise installer
calls app-run directly instead of discovering a personal token or allowing anonymous mode.
Its tool versions/security settings are not changed by the cutover.

Native Git needs its own helper policy: it does not run through app-run. The root app
helper returns quit=true on broker failure, preventing later helpers and prompts. Gist
HTTPS is intentionally unsupported/fail-closed. Only the three exact GitHub SSH prefixes
rewrite to HTTPS; other SSH hosts are unchanged. Explicit per-repo overrides/native binary
paths are cooperative-routing exceptions, not a security sandbox.

This is an authorized canary, not full acceptance. Genuine token-expiry and real
Git/jj evidence are recorded in Skift; installer fixtures are separate from a real
managed installer run.
OAuth credentials remain untouched only for explicit rollback; no upstream revocation.
Fresh login/group membership is required; restarting zsh inside an old terminal/agent
process does not acquire gh-app-clients. Restart long-running processes from a fresh login.

Evidence/rollback: local broker checkout docs/canary-cutover.md and Skift gh-app-broker#10.
Full acceptance/local logout and upstream-grant assessment remain #7/#8/#9 work. Source
publication follows passing full-suite and formatting checks and explicit approval.
