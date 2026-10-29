---
name: review-plan
description: Validate an implementation plan by checking for gaps, ambiguity, incorrect assumptions, and missing dependencies. Use after creating a plan and before execution.
---

# Review Plan: Validate Before Executing

```
$ARGUMENTS
```

Find the plan: an explicit path in the arguments, plan content in the conversation, or the
harness's plan directory. If there is none, say so and stop.

Delegate to the `plan-reviewer` agent when the harness supports subagents, passing the full
plan, the repository location, and any focus areas from the arguments. Return its findings
without softening them. Without subagents, read `~/.agents/agents/plan-reviewer.md` and follow
its method in this context, treating every claim in the plan as an untested hypothesis.
