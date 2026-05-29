---
name: prompt-engineering
description: Use when drafting, reviewing, or improving a prompt for an LLM or agent. Applies research-backed principles — explicit instructions, instruction/data separation, output contracts, examples, reasoning scaffolds, grounding, verification, and evals.
argument-hint: "[draft|review|improve|explain] [task description | @prompt-file | principle...]"
metadata:
  author: @ivy
allowed-tools:
  - Read
  - Glob
  - Grep
---

# Prompt Engineering Playbook

Treat prompt engineering as **experimental design**, not magic phrases. A good prompt is a contract: it states the job, separates trusted instructions from untrusted data, defines what success looks like, names the output shape, scaffolds genuine difficulty, and is improved by evals — not vibes.

## Arguments

```
$ARGUMENTS
```

## Reference

The condensed principles, anti-patterns, task patterns, and review rubric live in `PLAYBOOK.md` alongside this file. Read it once per session before producing serious output.

## Process

### 1. Detect intent

Parse arguments — be flexible.

| Signal                                                                       | Mode                                                                                                                                    |
| ---------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------- |
| `draft` / `write` / `create`, or a task description with no existing prompt  | **Draft** a new prompt from scratch                                                                                                     |
| `review` / `audit`, or `@file` / pasted prompt with no other directive       | **Review** against the rubric                                                                                                           |
| `improve` / `refine` / `fix`, paired with an existing prompt + failure modes | **Improve** an existing prompt                                                                                                          |
| `explain` / `why`, followed by a principle name                              | **Explain** a principle with examples                                                                                                   |
| empty                                                                        | Look at the conversation for a prompt-in-progress; treat it as review/improve. If nothing relevant, briefly say what you can help with. |

When the signal is ambiguous, **infer and proceed** — pick the mode that fits the inputs and note your inference in one line as you produce output. Only ask a question when proceeding would force you to guess a hard constraint (audience, schema, length cap) that materially changes the deliverable.

### 2. Apply the playbook

For every mode, check the prompt (existing or being drafted) against these gates from `PLAYBOOK.md`:

1. **Goal clarity** — outcome, audience, deliverable named
2. **Instruction/data separation** — untrusted input fenced in tags/delimiters
3. **Output contract** — schema, length, format are measurable, not adjectives
4. **Examples** — present when format, taste, or classification boundaries matter; balanced and edge-case-aware
5. **Reasoning scaffold** — matches task shape (CoT, plan-and-solve, step-back, least-to-most, ReAct, PoT) — not "show all your work" by default
6. **Grounding** — for factual work: sources, citations, abstention rule, conflict handling
7. **Verification** — checklist against rubric/source/test, not "now check yourself"
8. **Long-context handling** — instructions first, documents tagged, query at the end
9. **Failure mode** — explicit "if you cannot, say what is missing"
10. **Testability** — can this be graded on an eval set?

For each gate that fails, name the specific failure (not "be clearer") and propose the concrete fix.

### 3. Output

**Draft mode** — produce the prompt in a fenced block using the skeleton (Task / Context / Constraints / Input / Output format / Failure mode). After the prompt, give 2–4 bullets of design rationale (which gates each section satisfies, which trade-offs you made).

**Review mode** — short rubric scorecard (1–5 on the dimensions in `PLAYBOOK.md` §6), then the top 3–5 concrete fixes in priority order. No padding.

**Improve mode** — output the revised prompt in a fenced block, then a diff-style bullet list of what changed and why (tie each change to a gate or failure mode the user reported).

**Explain mode** — name the principle, give a bad/good example pair, and one sentence on when it applies vs. when it doesn't. Under 200 words.

## How this skill stays useful

The playbook is a tool, not a syllabus. Catch anti-patterns from `PLAYBOOK.md` §4 while you produce output — silently improve them in **draft** and **improve** modes, surface them concisely in **review**. The caller wants a better prompt, not a lecture.

Avoid:

- Lecturing the playbook back instead of producing the prompt
- Refusing to draft what was asked; if a request conflicts with a gate, draft the best version and note the trade-off in one line
- Asking clarifying questions when a reasonable inference would do
- Producing a "better" prompt that's just longer without satisfying new gates
- Adding ceremony (role-play, "you are a world-class…") that doesn't change behavior
- Recommending CoT, RAG, or self-verification by default without checking the task shape

## Examples

```
/prompt-engineering draft extractor for acquisition news → return JSON                  → produces a structured extraction prompt with schema, abstention, source quoting
/prompt-engineering review @prompts/triage.md                                           → rubric scorecard + top fixes
/prompt-engineering improve <pasted prompt>  failures: returns prose when JSON asked    → revised prompt + change log tied to output-contract gate
/prompt-engineering explain step-back prompting                                         → principle + bad/good pair + citation
/prompt-engineering                                                                     → looks at the current conversation for a prompt-in-progress
```
