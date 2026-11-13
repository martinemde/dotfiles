# Pi extensions

## Terminal title

The personal extension in `home/dot_pi/private_agent/extensions/terminal-title.ts`
shows `π ⠏ working | 42% | model xhigh | session name` (or `π ready` when
settled). The working spinner uses Pi's default frames and 80 ms cadence. Reasoning
models show their current effort level, which updates when you cycle it.
Blocking extension questions and confirmations alternate `[.]` / `[!]` until
answered or cancelled. Plain-text questions are not guessed from assistant prose.
Context is percent used; `?%` means unknown, such as immediately after compaction.
Unnamed sessions use the directory name. Run `/reload` in Pi after applying it.

The sandboxed TUI integration test runs with `bats test/pi-terminal-title.bats`
and requires an installed Pi and Python 3; it never calls a real model provider.

## PR session names

[pi-pr-session-title](https://github.com/lepht/pi-pr-session-title) detects PR
references in prompts (`PR 123`, `pull request 123`, `#123`, or GitHub PR URLs)
and looks up the title with `gh`. `home/.chezmoiexternals/pi.externals.toml` pins
its unmodified source and MIT license to a commit; Renovate updates both pins.
The local `pr-session-title/index.ts` wrapper formats native session names as
`pinwheel#123 — fix login race conditions`, which the terminal title displays too.
It lowercases the PR subject and keeps at most five words, without another model
request. Short subjects stay short; conventional-commit scopes are removed.

Manual names win, including names set while a lookup is pending. Failed lookups
leave the session unnamed. Detection uses prompt references, not the current
branch's PR. Bare numbers need a GitHub checkout; URL references work anywhere.

Apply `~/.pi/agent/extensions/pr-session-title` and run `/reload` in Pi. After
applying, `bats test/pi-pr-session-title.bats test/pi-terminal-title.bats` exercises
real Pi sessions and titles with a fake `gh` and an offline model provider. To test
without installing the external, set `PI_PR_SESSION_TITLE_UPSTREAM` to a local copy
of the pinned source. Tests themselves never download dependencies or call GitHub.
