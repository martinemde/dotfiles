# `/share-plan` — Publish the Plan to the Issue

Format an implementation plan into a GitHub issue using collapsible sections — scannable for most readers, detailed for implementers.

```
/share-plan #123
/share-plan #123 from path/to/plan.md
/share-plan new tmux session naming refactor
```

## Why this exists

Plans live in the agent's context window. When the session ends, they're gone. If you need to resume the work in a new session, or hand it off to another engineer, or just want to understand why a decision was made three months later — the plan is nowhere.

[`/share-plan`](../share-plan/README.md) makes the plan a permanent artifact on the issue. It becomes:

- A record of what was decided and why, timestamped before any code changed
- Context for future engineers who ask "why was this implemented this way?"
- A resume point if the implementation gets interrupted
- Visibility for teammates who want to understand or comment on the approach

## The formatting rationale

GitHub issues need to balance two audiences: people who want a quick summary, and people who need full implementation detail. [`/share-plan`](../share-plan/README.md) handles this with collapsible `<details>` sections.

The **Approach** section is always visible — the 3-5 bullet summary that answers "what are we doing and why?" Most readers stop here. The **Implementation** sections are collapsed by default — detailed enough to implement from, but not in the way of people who just want the overview.

This isn't aesthetic preference. An issue that's a wall of text gets skimmed; the key decisions get missed. An issue where the decisions are visible and the details are accessible gets actually read.

## In the [`/work-on`](../work-on/README.md) workflow

[`/share-plan`](../share-plan/README.md) runs after [`/review-plan`](../review-plan/README.md) approves the plan and before execution begins. The sequence creates a paper trail:

```
/plan → /review-plan (approved) → /share-plan → execution
```

Publishing before execution means the issue reflects the *intended* implementation, not a post-hoc rationalization. If the implementation diverges from the plan (as it often does), the issue shows what was planned and the PR diff shows what actually happened.
