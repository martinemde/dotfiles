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
silently. Strip `PRIME_AGENT_INTERACTIVE_SELF_UPDATE` from the local updater:
inside a Prime shell it makes an already-current update exit 75 rather than 0. The remote side prints exactly one JSON line on stdout; installer and
update output go to stderr.

A daemon started before an update keeps serving the old version. If no session
row has a `workerPid`, the launcher sends the protocol's `shutdown` command on
the connection it already holds and starts a new daemon; the new one unlinks the
dead socket file before binding. Saved conversations survive a daemon restart
(see the proof below); live workers might not, so their presence is a hard stop.
An earlier version found the socket peer with `SO_PEERCRED` and sent SIGTERM,
on the mistaken belief that Prime had no stop command.

The daemon starts in the workspace's checkout. A client that cannot name a
remote directory gets the daemon's own cwd.

Shell completion of workspace names was left out: Coder is meant to become an
implementation detail behind a generic remote-workspace launcher.

Live proof on `prime-coder-proof` (2026-11-02): local 0.10.2 UI connected to remote
0.10.2; both a shell command and a model-driven Python call reported the Coder
hostname and the remote checkout directory. Terminating the local UI
while a delayed command ran did not stop the remote command. The chooser reopened
the saved conversation, including after a daemon restart. Local `list --json`
worked through the forwarded socket. Offline tests exercise command boundaries;
they never provision Coder or call a model.

The Python launcher replaces the Agent Feeds TypeScript client. Keep the current
Coder login, stable updates, native state/runtime and restricted UI environment;
do not retain the separate pinned bootstrap, private token config or launch receipts.
Those created a second installation/auth location without improving this interactive
workflow. Native Prime commands cover session listing and creation.

Live recheck on disposable Daedalus workspace `prime-python-978723` (2026-11-03):
0.10.2 local UI attached to remote 0.10.2; native bash returned the workspace hostname
and `/work/workspace`; all eight bundled Python skill modules imported from the
native kernel venv. Disconnect left the same worker alive. Stop/start retained the
durable conversation, and default attach resumed it. The test workspace was stopped.
A real model prompt was refused because the fresh template has no provider auth;
no laptop credentials were copied. Model execution still needs remote login.

Known upstream limits remain visible rather than being rewritten by a proxy:
local cwd/file/auth handling, maintenance commands with inconsistent socket
support, and no strict connect-only mode. The UI can show `/` while an attached
worker correctly executes in its remote checkout. Remote login through the local
UI remains unsupported.

Credential forwarding is explicit on each connection, with no workspace-ownership
check: the user decides which workspace to trust. Saved API keys travel on SSH
stdin, not argv, logs or the UI environment. Merge under Prime's auth lock and
atomically replace the private file so concurrent native auth writes do not lose
unrelated entries. Retain keys after disconnect because remote agents keep running.
OAuth/refresh tokens are deliberately excluded: two hosts refreshing one token
can invalidate each other's sessions. Command-backed credentials are excluded too;
copying their commands would execute them on a different host. Environment-only
credentials and a second remote credential store were left out. Existing session
streams can cache keys; model reselection may be needed after rotation.

The Prime fork (`martinemde/prime-agent`, branch
`claude/project-thread-lvon8q`, not proposed upstream) removes the client's
same-machine assumption. The daemon's hello reports its cwd; a client whose
connected socket is not the file the daemon bound treats it as remote, and
then defers cwd, session directory, and environment to the daemon, shows the
session's own cwd, and refuses to replace a mismatched daemon rather than
spawning a local one on the forwarded path. With that build on both sides, the
environment scrub and `PRIME_AGENT_SESSION_DIR` here become redundant, and the
agent picker's new-session path works. They stay while stock 0.10.2 is the
target. Still open: `--cwd` cannot name a remote directory (it chdirs locally),
`@` file completion searches the local disk, and an absent socket still spawns
a local daemon.

Forwarding proof on the same disposable workspace (2026-11-03): `--forward-auth`
copied only the saved API-key entry, with `0600` mode and no temporary-file residue.
After model reselection, a native remote `prompt_and_wait` authenticated to Kimi;
the persisted Python tool result returned `prime-python-978723` and
`/work/workspace`. Test credentials were removed and the workspace stopped.
Stock `--print` instead tried to execute locally with cwd `/` and failed its
kernel setup; it is not a remote execution path, even with the socket argument.
