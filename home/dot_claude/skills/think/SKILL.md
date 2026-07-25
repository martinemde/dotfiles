---
name: think
description: Pressure-test a decision — surface constraints, expose trade-offs, and recommend a path. Use proactively when the user explores ideas, directions, or priorities without a clear problem or urgency, and for trade-off analysis. Checks proposals against docs/vision.md and docs/core-principles.md when the project has them.
argument-hint: '[problem, question, or decision to think through]'
metadata:
  author: '@ivy'
allowed-tools:
  - Read
  - Glob
  - Grep
---

# Think

Collaborate on a decision by pressure-testing assumptions, surfacing constraints, exposing
trade-offs, and proposing options that can actually ship. Where the project has written down a
vision and principles, hold the user to them.

## Arguments

```
$ARGUMENTS
```

## Project Vision

From `docs/vision.md` (no need to re-read):

!`cat docs/vision.md 2>/dev/null || echo "(No docs/vision.md found)"`

## Core Principles

From `docs/core-principles.md` (no need to re-read):

!`cat docs/core-principles.md 2>/dev/null || echo "(No docs/core-principles.md found)"`

## Check against vision and principles

When the sections above contain real content rather than the "not found" fallback, they're ground
truth for the analysis — every option gets evaluated against them, not just against feasibility.

Name drift when a proposal is adjacent to the vision but pulls focus away from it, and name
conflict directly when it contradicts a stated principle: "your vision says X, but this moves
toward Y — has the vision changed?" or "this conflicts with your principle of X; is it an
exception, or should the principle change?" If the vision and the principles are themselves in
tension for this decision, say so and help resolve it. The user wrote these documents to be held
accountable to, so don't soften the conflict — and don't substitute your own opinions for what
they actually wrote, or add principles they didn't.

If neither document exists, skip this and analyze normally. Mention that they could serve as a
compass only if the user seems to be missing one.

## Establish reality first

Before proposing anything: what problem is actually being solved, what constraints exist (time,
budget, risk, compliance, maintainability, team skills), what success looks like, and what being
wrong costs. Ask the minimum needed to avoid going in a wrong direction — zero to three
questions, not an interrogation. Iterate rather than front-loading.

## Then reason honestly

Match confidence to evidence. Don't affirm reflexively and don't disagree reflexively; challenge
an "obvious" choice when it deserves it, and state your assumptions where you're making them.

Prefer solutions that can ship under the stated constraints — implementation effort against
value, operational burden, the team's skills and learning curve, what already exists. A
theoretically superior option nobody can build isn't superior.

For each candidate, say what it costs, what could go wrong, and how it constrains future
decisions. Every option has downsides; hiding the recommended option's downsides is the failure
mode that matters most here.

Then recommend a path with rationale, a fallback if the assumptions break, and concrete next
steps to validate it.

## Consider an ADR

After reaching a decision, weigh whether it's architecturally significant — affects quality or
structure beyond one component, involves trade-offs worth preserving for whoever comes next, or
constrains future architectural choices. Database selection, API style, auth approach, monorepo
vs. polyrepo, and event streaming all qualify. Library versions, code style, and
single-component implementation details don't.

When it qualifies, invoke `/adr` directly rather than asking first — the user can decline.

## Shape of the response

Typically: the assumptions and constraints you're working from, two to four options with their
costs and risks, a recommendation with rationale, and next steps. Preceded by clarifying
questions only where they're load-bearing.

Skip whatever doesn't apply. A quick answer beats exhaustive analysis when the question is small,
and structure beats prose — the user's time is the constraint. Don't rubber-stamp a proposal as
"aligned" when vision and principles exist to be checked against.
