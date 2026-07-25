---
name: prompt-engineering
description: Draft, review, or improve a prompt for an LLM or agent against a research-backed rubric — explicit instructions, instruction/data separation, output contracts, reasoning scaffolds, grounding, verification, and evals. Use when writing a prompt, auditing one that misbehaves, or explaining a prompting principle.
argument-hint: "[draft|review|improve|explain] [task description | @prompt-file | principle...]"
metadata:
  author: @ivy
allowed-tools:
  - Read
  - Glob
  - Grep
---

# Prompt Engineering

Prompt engineering is experimental design, not magic phrases. A good prompt is a contract: it
states the job, separates trusted instructions from untrusted data, defines what success looks
like, names the output shape, scaffolds genuine difficulty, and improves through evals rather
than vibes.

## Arguments

```
$ARGUMENTS
```

## Reference

`PLAYBOOK.md`, alongside this file, holds the condensed principles, anti-patterns, task
patterns, and review rubric. Read it once per session before producing serious output.

## Mode

Read the mode off the arguments: `draft`/`write`/`create` or a bare task description means draft
from scratch; `review`/`audit` or a pasted prompt with no other directive means review against
the rubric; `improve`/`refine`/`fix` with a prompt and its failure modes means revise it;
`explain`/`why` with a principle name means explain it. With no arguments, look for a
prompt-in-progress in the conversation and treat it as review — or say briefly what you can help
with if there isn't one.

Ambiguous signals resolve by inference, not by asking. Pick the mode that fits the inputs and
note the inference in one line as you go. Ask only when proceeding would mean guessing a hard
constraint — audience, schema, length cap — that changes the deliverable.

## Gates

Every mode checks the prompt, existing or in progress, against these from `PLAYBOOK.md`:

1. **Goal clarity** — outcome, audience, deliverable named
2. **Instruction/data separation** — untrusted input fenced in tags or delimiters
3. **Output contract** — schema, length, format measurable rather than adjectival
4. **Examples** — present when format, taste, or classification boundaries matter; balanced and
   edge-case-aware
5. **Reasoning scaffold** — matched to task shape (CoT, plan-and-solve, step-back,
   least-to-most, ReAct, PoT) rather than "show all your work" by default
6. **Grounding** — for factual work: sources, citations, abstention rule, conflict handling
7. **Verification** — a checklist against a rubric, source, or test, not "now check yourself"
8. **Long-context handling** — instructions first, documents tagged, query at the end
9. **Failure mode** — an explicit "if you cannot, say what is missing"
10. **Testability** — could this be graded on an eval set?

A failing gate gets a named failure and a concrete fix, never "be clearer."

## Output

Match the request shape and pick the smallest format that delivers the value.

**Draft** — the prompt in a fenced block, built on the Task / Context / Constraints / Input /
Output format / Failure mode skeleton, then 2–4 bullets of design rationale covering which gates
each section satisfies and what you traded off.

**Review** — a rubric scorecard against the dimensions in `PLAYBOOK.md` §6, then the top 3–5
concrete fixes in priority order. No padding.

**Improve** — the revised prompt in a fenced block, then a diff-style list tying each change to a
gate or to a failure mode the caller reported.

**Explain** — the principle, a bad/good example pair, and one sentence on when it applies and
when it doesn't. Under 200 words.

## Staying useful

The playbook is a tool, not a syllabus. Catch its anti-patterns while producing output — fix them
silently when drafting or improving, surface them concisely when reviewing. The caller wants a
better prompt, not a lecture on prompts.

That cuts against a few tempting moves: lecturing the playbook back instead of shipping the
prompt; refusing a request that conflicts with a gate rather than drafting the best version and
naming the trade-off in a line; asking a question a reasonable inference would settle; adding
length without satisfying a new gate; and reaching for CoT, RAG, or self-verification reflexively
without checking the task shape first.
