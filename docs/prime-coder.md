# Prime Coder launcher

Keep the UI local and the native daemon/workers in Coder. OpenSSH forwards one
Unix socket through `coder ssh --stdio`, using the existing Coder login. No bus,
conversation database, credential sync, or Prime fork is needed for this proof.
The workspace owns native history; the launcher owns only the temporary tunnel.
Coder owns template and parameter selection. The launcher supplies no template,
harness, or repository defaults and lists workspaces from all templates.

Prime 0.10.2 forwards the client's environment when creating a session. Passing
laptop HOME/PATH or credentials would overwrite the workspace environment, so the
launcher passes only terminal/locale and Prime state-directory settings. Default
session creation happens remotely to preserve the template checkout. Native
session listing uses `sessionName`; inactive saved rows can still contain an
`activeSessionId`, so a live worker is checked separately.

Use the native default daemon socket: Prime's updater coordinates that socket,
not arbitrary explicit sockets. The Linux unmanaged installer reinstalls even
when already current, so check its stable version before invoking an update.
Local managed installs perform that check inside `update` themselves.
For a missing remote executable, run the official curl-to-sh installer first;
let the upstream installer own platform selection and installation.

Install, update check, daemon start, and session bootstrap share one `coder ssh`
call; each call costs a full Coder connection, and four of them dominated launch
time. Update checks are throttled to daily with a stamp file on each side, but a
local/remote version mismatch bypasses the stamp, so the two never drift apart
silently. The remote side prints exactly one JSON line on stdout; installer and
update output go to stderr.

A daemon started before an update keeps serving the old version. If no session
row has a `workerPid`, the launcher identifies the socket's peer with
`SO_PEERCRED`, confirms from `/proc` that it is a `prime-agent` daemon, sends
SIGTERM, and starts a new one. Saved conversations survive a daemon restart
(see the proof below); live workers might not, so their presence is a hard stop.
Prime has no daemon-stop command to use instead.

Shell completion of workspace names was left out: Coder is meant to become an
implementation detail behind a generic remote-workspace launcher.

Live proof on `prime-coder-proof` (2026-11-02): local 0.10.2 UI connected to remote
0.10.2; both a shell command and a model-driven Python call reported the Coder
hostname and the remote checkout directory. Terminating the local UI
while a delayed command ran did not stop the remote command. The chooser reopened
the saved conversation, including after a daemon restart. Local `list --json`
worked through the forwarded socket. Offline tests exercise command boundaries;
they never provision Coder or call a model.

Known upstream limits remain visible rather than being rewritten by a proxy:
local cwd/file/auth handling, maintenance commands with inconsistent socket
support, and no strict connect-only mode. The UI can show `/` while an attached
worker correctly executes in its remote checkout. Credentials stay on their
original host. This proof does not solve remote login through the local UI.
