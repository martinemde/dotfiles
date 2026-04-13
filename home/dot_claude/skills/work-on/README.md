# `/work-on` — Ship an Issue End-to-End

The complete workflow for taking a GitHub issue from "open" to "merged PR." Invoke it once; the agent handles research, planning, implementation, and review — asking you only at the moments where human judgment matters.

```
/work-on #123
```

## Why this exists

Agent-driven development has a failure mode: the agent codes confidently in the wrong direction. By the time it opens a PR, you've got a technically competent solution to the wrong problem. The expensive mistake isn't bad code — it's code that doesn't solve the actual issue.

[`/work-on`](../work-on/README.md) is designed around that insight. It front-loads the moments that require human judgment:

- **What's the actual problem?** ([`/gather-context`](../gather-context/README.md) surfaces what the code and history say)
- **What should we build?** ([`/think`](../think/README.md) pressure-tests the approach against your vision and principles)
- **How should we build it?** ([`/plan`](../plan/README.md) structures the work before any code gets written)

Once those questions are answered — once human and agent are aligned — execution becomes mechanical. The agent works autonomously through implementation, review, and PR.

## How it works

When you run `/work-on #123`, the agent:

1. Fetches the issue and reads [TIERS.md](TIERS.md) to assess complexity
2. Proposes a tailored workflow based on the tier (see below)
3. Waits for your confirmation before starting
4. Builds a task list with dependencies, then works through it
5. Surfaces findings during research, converges with you during [`/think`](../think/README.md), then executes autonomously

### The tiers

| Tier | Profile | Workflow |
|------|---------|----------|
| **Quick fix** | Single file, exact description | checkout → fix → commit → PR |
| **Small** | Clear scope, few files | checkout → gather-context → fix → commit → PR |
| **Medium** | Design choices needed | checkout → gather-context → **think** → plan → execute → PR |
| **Large** | Cross-cutting, parallel workstreams | Medium + agent teams, worktree isolation |
| **Epic** | Multi-PR, potentially multi-session | Decompose → run each sub-unit at appropriate tier |

The tier is assessed from signals: issue labels, body length, comment count, linked issues, design questions. When in doubt, the agent picks the higher tier — over-planning wastes minutes; under-planning wastes hours.

### The autonomy boundary

```
/gather-context  →  /think  →  /plan  ‖  execution  →  /simplify  →  /pr
                                       ↑
                               handoff to autonomy
```

The human collaborates actively through research and planning. After [`/think`](../think/README.md) converges on a direction, the agent executes without interruption — committing incrementally, running reviews, opening the PR. If it hits a genuine blocker (unexpected test failures, ambiguous requirements), it flags you rather than guessing.

### Adaptive behavior

[`/work-on`](../work-on/README.md) reads available skills and agents at activation time. It only orchestrates what actually exists in your environment — it degrades gracefully in projects without the full suite. A project with only [`/checkout`](../checkout/README.md), [`/commit`](../commit/README.md), and [`/pr`](../pr/README.md) gets a lean workflow; a project with the complete toolkit gets the full orchestration.

## The component skills

Each skill in the workflow is independently useful and documented separately:

**Research phase**
- [`/checkout`](../checkout/README.md) — create a feature branch
- [`/gather-context`](../gather-context/README.md) — parallel research across issue, codebase, and history

**Planning phase**
- [`/think`](../think/README.md) — converge on approach with the human
- [`/plan`](../plan/README.md) — build a parallelized task graph
- [`/review-plan`](../review-plan/README.md) — validate the plan before execution
- [`/share-plan`](../share-plan/README.md) — publish the plan to the issue

**Execution phase**
- [`/commit`](../commit/README.md) — incremental commits during autonomous execution

**Review phase**
- [`/simplify`](../simplify/README.md) — code quality pass (built-in)
- [`/pr`](../pr/README.md) — open the PR

**Retrospective**
- [`/reflect`](../reflect/README.md) — extract lessons for future sessions

## Supporting docs

- [TIERS.md](TIERS.md) — decision matrix with signals, examples, and tier definitions
- [EPIC-WORKFLOW.md](EPIC-WORKFLOW.md) — how to decompose and coordinate epic-scale work
