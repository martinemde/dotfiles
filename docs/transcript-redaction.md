# Transcript secret masking

## Usage

`transcript-redact` previews Gitleaks findings in local Claude, Codex, and Prime
transcript/history files. Every finding is masked, including false positives.
It leaves `.env`, credentials, config, and all non-transcript files alone.

```bash
transcript-redact
# Exit all coding agents and their background daemons, then run from a normal shell:
transcript-redact --write --agents-stopped
# Repeat to confirm there are no remaining findings:
transcript-redact
```

Requires Python 3 and the managed Gitleaks installation. `--home PATH` targets a
separate home directory, for example a disposable test fixture. No values or
surrounding transcript text are printed. Masking uses `X` bytes, preserves JSON
and UTF-8 byte lengths, validates the result, and rescans before writing. Repeated
runs are safe; new leaks require another run. Do not run writes from an active
agent or schedule them while agents are running. The confirmation flag is an
operator assertion, not automatic process detection.

This cleans transcript files only. SQLite copies, caches, snapshots, backups,
provider records, and encoded secrets Gitleaks does not recognize remain outside
scope. It is not forensic erasure or a substitute for rotating exposed credentials.

## Design notes

Coding-agent transcripts retain tool output and copied credentials. Gitleaks
findings are disposable here, even false positives; these files are not secret
stores. Credential/config files, including `.env`, must remain available for
manual cleanup and are never mutation targets.

Use an explicit transcript/history path allowlist for Claude, Codex, and Prime.
Do not reuse the home scanner's path exclusions, size limit, or local allowlists:
those can hide transcript findings. Detect in decoded JSON string values, then
mask every matching value across the allowlisted files. Keep reports in memory;
never echo detector output or save secret-bearing backups. Disable recursive
Gitleaks decoding: encoded payload transformations need a separate mapping, not
blind replacement. JSON escapes are mapped back to their original byte spans.

Codex maintains rollout byte offsets in SQLite. Replacing secrets with the literal
`REDACTED` or reserializing JSON changes offsets. Replace each matching encoded
character span with the same number of ASCII `X` bytes instead. Preserve line
boundaries and validate JSON before and after masking. Scan the proposed result
again before writing; fail rather than silently accept remaining findings.

Writers must be stopped, including the agent proposing cleanup: atomic replacement
cannot prevent a live writer from restoring cached secrets or appending to an old
inode. Keep execution operator-triggered rather than a background timer or a
Chezmoi apply hook. Dry-run is the default; writes require explicit confirmation
that agents are stopped. Check source files for concurrent changes before writes.

SQLite duplicates and Prime caches are deliberately not handled by this file-only
command. SQL rows, WAL files, indexes, and unused pages require an independent,
verified cleanup procedure. Byte-preserving file masking keeps offsets stable but
does not make database copies safe. Snapshots and provider storage are also out of
scope. No claim of complete credential removal or forensic erasure is made.

The existing Chezmoi scanner must redact its output too: verbose unredacted scan
results can feed the same secrets straight back into transcripts.
