# `/review-plan` — Validate Before Executing

An isolated reviewer checks the implementation plan for errors before any code runs. Catches wrong file paths, incorrect API assumptions, missing dependencies, and ordering issues.

```
/review-plan
/review-plan focus on file paths and API correctness
```

## Why this exists

Plans are written by the agent that will execute them. That agent has context from the entire planning conversation — the rationale behind each decision, the assumptions made along the way. This context makes it easier to rationalize problems away rather than see them clearly. "The plan says to call `foo.bar()` — I know what I meant, so that must be right."

An isolated reviewer doesn't have that context. It can only check whether the plan's claims are true against the actual codebase. If the plan says `src/auth/session.ts` exists, the reviewer checks. If it doesn't, that's a blocking issue — and it's much cheaper to find before execution than after.

This is the same reasoning behind code review: the author is the worst person to review their own work, not because they're incompetent, but because they already know what they meant.

## How it runs

[`/review-plan`](../review-plan/README.md) uses `context: fork` with the `reviewer` agent. This means:

- It runs in an **isolated subagent** with no access to the planning conversation
- The reviewer's only inputs are the plan file and the actual codebase
- Results are returned to the main conversation without polluting its context

The isolation is load-bearing. A reviewer that saw the planning discussion would rationalize the same assumptions. Fresh context forces verification.

## What it checks

1. **Codebase reality** — do referenced files, functions, and packages actually exist?
2. **Task graph integrity** — are dependencies correct? any missing blockers? any false sequencing?
3. **Instruction clarity** — are task descriptions specific enough for an executing agent to act on without further clarification?
4. **Alignment** — does the plan match project conventions (from CLAUDE.md)?
5. **Coverage** — are there obvious gaps (missing tests, unhandled edge cases)?

## Severity levels

- **Blocking** — must fix before execution: wrong paths, missing dependencies, incorrect API signatures
- **Warning** — should address but can proceed: vague instructions, untested assumptions
- **Note** — optional improvements, not blockers

The skill returns a clear verdict: **Approve** or **Revise**. Blocking issues require a plan update before execution begins.

## In the [`/work-on`](../work-on/README.md) workflow

[`/review-plan`](../review-plan/README.md) runs between [`/plan`](../plan/README.md) and execution. If it finds blocking issues, the agent updates the plan and may re-run the review. Once approved, execution starts with the confidence that the plan's factual claims have been verified.
