# `/reflect` — Session Retrospective

Review what happened in a session, surface friction and codebase issues, and turn every finding into either a fix or a tracked issue.

```
/reflect
/reflect @notes.md
/reflect the branch switching was painful
```

## How it works

`/reflect` runs a five-phase pipeline:

1. **Gather metrics** — runs `ccstat` against the current session to get cost, token usage, autonomy, interruptions, tool calls, and subagent activity
2. **Interpret metrics** — flags anomalies relative to the session's scope (high cost/commit, frequent interruptions, subagent failures, narrating vs working)
3. **Extract findings** — scans the conversation for session friction (mistakes, stalls, corrections) and codebase observations (tech debt, missing docs, fragile architecture)
4. **Triage** — classifies every finding as **fix now** (<10 min, obvious) or **backlog** (needs thought or broader scope)
5. **Execute** — after user approval, applies quick fixes with `/commit` and files/updates GitHub issues for backlog items

## What it produces

Two buckets, nothing else:

| Bucket      | Criteria                                                | Action                        |
| ----------- | ------------------------------------------------------- | ----------------------------- |
| **Fix now** | Small, obvious, no design decisions                     | Apply inline, `/commit`       |
| **Backlog** | Needs thought, research, or is part of a larger problem | File or update a GitHub issue |

Backlog items target the right repo:

- Dev environment friction (skills, hooks, dotfiles) goes to the dotfiles repo
- Codebase friction goes to the repo being worked on

Before filing, `/reflect` searches for existing issues to avoid duplicates. If a duplicate exists, it adds a comment with new context.

## What it does NOT produce

- **Memories** — zero, ever
- **Skips** — nothing gets skipped

## Arguments

| Input       | Behavior                                                   |
| ----------- | ---------------------------------------------------------- |
| (empty)     | Full retrospective using metrics and conversation analysis |
| `@notes.md` | Incorporates the referenced file as user observations      |
| Plain text  | Treats as user-provided context about the session          |

## In the `/work-on` workflow

`/reflect` runs at the end of Large and Epic tier workflows. Smaller tasks rarely surface patterns worth capturing, but a multi-phase session almost always does.

## Standalone usage

Use `/reflect` after any session with significant friction, surprising discoveries, or user corrections. It doesn't have to follow a `/work-on` workflow — any substantial session is a candidate.
