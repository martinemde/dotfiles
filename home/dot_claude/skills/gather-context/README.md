# `/gather-context` — Build Understanding Before Acting

Research a problem thoroughly before proposing solutions. Parallel exploration across the issue, codebase, and history — synthesized into structured input for the next phase.

```
/gather-context #123
/gather-context "why does login fail intermittently"
```

## Why this exists

**Chesterton's Fence.** Before you remove a fence, you should understand why it was built. Code that looks wrong often has a reason — a security constraint, a backward compatibility requirement, a workaround for an upstream bug. An agent that changes code without understanding its history is a liability.

**Serial exploration is slow.** When an agent investigates a problem, it naturally works serially: read the issue, then explore the codebase, then check the history, then follow links. These are independent tasks. [`/gather-context`](../gather-context/README.md) runs them in parallel via Explore agents, collapsing research time.

**Open questions are expensive to discover late.** The synthesis output explicitly surfaces what's unknown: gaps in the issue spec, ambiguities that need human clarification, assumptions that need validation. Finding these during research costs a conversation turn. Finding them during implementation costs a rework cycle.

## How to use it

**From an issue reference:**
```
/gather-context #123
```
Fetches the issue, comments, and linked references, then spawns parallel agents to explore the codebase and history.

**From a description (no issue):**
```
/gather-context "the dark mode toggle doesn't persist across page reloads"
```
Skips issue fetching; goes straight to codebase and history exploration using the description as search context.

## Scope: light vs. full

The agent calibrates research depth to the problem:

- **Light** — issue is narrow and well-specified: fetch the issue, one quick codebase scan
- **Full** — issue is broad, vague, or has many comments: fetch issue + parallel Explore agents + history search + follow linked references

A typo fix doesn't need three Explore agents.

## What the synthesis looks like

The output is structured for consumption by [`/think`](../think/README.md) and [`/plan`](../plan/README.md), not for general reading:

- **Problem statement** — what needs to change and why, with acceptance criteria if stated
- **Relevant code** — file paths, line ranges, key functions, how the current code works
- **Prior art** — previous attempts, related commits, reverted changes, relevant discussion
- **Constraints** — project conventions, testing requirements, platform considerations
- **Open questions** — what's ambiguous or unknown, what needs human input

## In the [`/work-on`](../work-on/README.md) workflow

[`/gather-context`](../gather-context/README.md) runs after [`/checkout`](../checkout/README.md) and before [`/think`](../think/README.md). Its output is the factual foundation that makes [`/think`](../think/README.md) productive — instead of discussing what the problem *might* be, the conversation starts from what the code and history *actually say*. The open questions section is passed directly to [`/think`](../think/README.md) as the framing for discussion.

[`/gather-context`](../gather-context/README.md) is also useful standalone for investigation work that isn't headed toward a PR — debugging, code review, or just understanding an unfamiliar part of the codebase.
