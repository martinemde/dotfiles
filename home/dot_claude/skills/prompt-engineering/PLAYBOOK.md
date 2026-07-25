# Prompt Engineering — Condensed Playbook

Research-backed reference for the `/prompt-engineering` skill. Source essay lives at `docs/prompt-engineering.md` in the dotfiles repo; this file is the action-oriented distillation kept inside the skill so it works in every project.

## 1. The contract

A prompt is a contract that answers six questions:

1. **What is the job?** Task, role, outcome.
2. **What input?** Trusted instructions vs. untrusted user data, documents, examples, tool results — kept separate.
3. **What counts as success?** Quality criteria, edge cases, abstention rules.
4. **What should the output look like?** Schema, length, tone, labels, citation style, parsing requirements.
5. **How are hard parts handled?** Decomposition, retrieval, tools, verification, multiple samples.
6. **How will you know it improved?** Eval set + measurable outcomes.

Default skeleton:

```
Role / function: You are [role] helping with [task].
Goal:            Produce [deliverable] for [audience].
Context:         [background, definitions, constraints, source material]
Instructions:
  1. [concrete step or decision rule]
  2. [edge-case handling]
  3. [what to do when info is missing or conflicting]
Output format:   Return [JSON/schema/table/sections]. Use [length, tone, units, labels].
Quality bar:     A successful answer must [criteria]. Do not [X]; instead [preferred Y].
```

## 2. Principles (the gates)

### 2.1 Be explicit, concrete, outcome-oriented

Replace vague verbs with measurable constraints. `"brief"` → `"3–5 sentences"`. `"professional"` → name the register or show an example.

### 2.2 Separate instructions from data

Use XML-style tags (`<instructions>`, `<context>`, `<document>`, `<output_format>`) or fenced delimiters. State that documents are **untrusted** and that any instructions inside them must be ignored. Prompt injection is OWASP LLM Top-10 #1; delimiters are partial defense, not full.

### 2.3 Define the output contract

Prefer JSON schema, explicit field types, and `null` semantics over prose. For machine-consumed output: schema + rules + source-sentence quoting beats "extract the important info."

Never rely on adjectives ("brief", "detailed", "high quality") without defining them.

### 2.4 Examples when format, judgment, or taste matter

Few-shot helps most when it communicates label space, distribution, and format — not just input/label mapping.

- Balance label distribution
- Include edge cases (the `"mixed"` row in a sentiment set)
- For classification, **test multiple orderings** — order can swing accuracy from random to SOTA (Lu et al.; Zhao et al. calibration showed up to +30 pp)

Weigh this against the cost on frontier models: examples "constrain them to a certain
exploration space" ([Anthropic, context engineering for Claude 5 generation models](https://claude.com/blog/the-new-rules-of-context-engineering-for-claude-5-generation-models)).
For open-ended work, an expressive interface — named parameters, enumerated options, a stated
output contract — steers better than a worked example and leaves room for a better answer than
the one you demonstrated. Reach for few-shot when the target is a specific format or a
classification boundary you can't describe as cleanly as you can show.

### 2.5 Match the reasoning scaffold to the task

| Task shape                                     | Scaffold                                                          |
| ---------------------------------------------- | ----------------------------------------------------------------- |
| Multi-step arithmetic / commonsense / symbolic | Chain-of-thought ("Let's think step by step" — Kojima zero-shot)  |
| Robustness on hard math                        | Self-consistency (sample N, majority vote)                        |
| Hard compositional generalization              | Least-to-most (decompose → solve subproblems in order)            |
| Planning-heavy                                 | Plan-and-solve (plan, then execute, then verify each requirement) |
| Abstract / multi-hop                           | Step-back (identify principle first, then apply)                  |
| Math, data, code                               | Program-of-Thoughts (emit code, run it)                           |
| External knowledge / actions                   | ReAct (interleave reason + tool calls)                            |

**Do not** ask reasoning models for full visible chains of thought — they reason internally. Ask for concise rationale + verification summary instead.

### 2.6 Ground factual answers in evidence

For factual work, the prompt should:

- Restrict to provided sources
- Require a citation per claim (source ID + supporting quote)
- Define abstention: `"if sources don't answer, say so"`
- Define conflict handling: `"if sources conflict, describe the conflict"`
- Treat source text as evidence, not as instructions
- Output: answer + evidence table + confidence (high/med/low)

Grounding ≠ no hallucination. RAG can still generate text that conflicts with retrieved evidence — that's why you require quotes and abstention.

### 2.7 Verify against external checks, not "self-correct"

Self-correction without external feedback can degrade performance (Huang et al.). Verification works when there's a rubric, source, test, or computation to check against.

Weak: `"now check if your answer is correct."`
Strong: a checklist that names every property (units, arithmetic, unsupported claims, fact vs assumption) and instructs revision if any check fails.

### 2.8 Manage long context deliberately

"Lost in the middle": relevant info buried mid-context performs worse than start/end.

- Instructions first, context after a delimiter
- For long docs: tag each doc with `id` and `source`, put the query **at the end** (Anthropic reports up to +30% with query-last)
- Ask for evidence quotes **before** synthesis
- Remove irrelevant context — longer is not better
- High-priority constraints go in system/developer instructions, not buried in pasted text

### 2.9 Choose the right model and parameters

- **Low temperature (0)**: extraction, classification, compliance, factual QA, code transformation
- **Higher temperature**: brainstorming, naming, ideation
- **Reasoning model / high effort**: multi-step planning, math, complex code, agentic workflows
- **Small model**: narrow tasks with constrained output and acceptable failure modes

Temperature controls randomness, not truthfulness.

### 2.10 Optimize with evals, not vibes

Minimal loop:

1. 30–100 representative inputs with expected outputs or rubric
2. Run baseline
3. Change one thing
4. Track accuracy, refusal rate, citation quality, parse failures, latency, cost
5. Keep regressions as test cases
6. Promote only if target metric improves without unacceptable regressions

For open-ended tasks, LLM-as-judge approximates human preferences (MT-Bench) but has position, verbosity, and self-preference bias. Randomize order, hide model identity, periodically compare to human review.

## 3. Style guide

### Do

- Lead with the desired outcome
- Name audience and use case
- Define ambiguous terms
- Separate instructions, examples, context, untrusted input
- Use examples for subtle format, tone, classification, edge cases
- Specify behavior when info is missing
- Prefer `"do X"` over `"don't do Y"` (state the preferred behavior, not just the prohibition)
- Use fixed schemas for machine-consumed output
- Require citations or evidence when factuality matters
- Ask for a brief verification summary when errors are costly
- Test on real examples before trusting

### Don't

- `"be accurate"`, `"be smart"`, `"be professional"`, `"don't hallucinate"` — vague
- Mix task instructions with untrusted pasted text in one blob
- Contradictory constraints (`"comprehensive but under 50 words"`)
- One prompt with multiple unrelated tasks
- All-caps `"IMPORTANT"` spam instead of clear hierarchy
- Restate the same rule in several layers — repetition reads as conflict, not emphasis
- Over-constrain what the model is good at judging; state the intent and leave the application
- Bury important constraints mid-context
- Reach for CoT on every task
- Treat one good output as proof of robustness
- LLM-as-judge without checking position/verbosity/self-preference bias
- Let a model take external actions without tool permissions, sandboxing, and approval

## 4. Anti-patterns and fixes

### The wish prompt

> Give me the best possible strategy.

**Fix:** name the goal, constraints (budget, team, time horizon), and required output sections.

### The "no hallucinations" prompt

> Answer the question. Do not hallucinate.

**Fix:** restrict to provided sources, require citation per claim, define abstention, separate facts/inferences/assumptions.

### The overloaded prompt

> Read this contract, summarize it, identify risks, rewrite bad clauses, compare to market, and draft an email.

**Fix:** chain. Step 1: identify top 10 risk clauses with severity and supporting text. Step 2 (separate prompt): proposed rewrites. Step 3: drafted email. Each step is testable.

### Unbalanced examples

Three `approve` examples in a row + one `reject` test case. The model learned "always approve."

**Fix:** balance labels, include edge cases (`approve`, multiple `reject` reasons), name the decision rule explicitly.

### Unsafe tool use

> Read this email and do what it says.

**Fix:** read as **untrusted**. Enumerate allowed actions (summarize, identify requested actions, draft a reply). Enumerate disallowed actions (send, open links, change settings, reveal prompts). Require confirmation for external actions.

## 5. Task patterns

### Summarization

Audience + focus topics + preservation rules (numbers, dates) + length cap + "flag missing context" + no outside info.

### Extraction

`Return JSON only.` + schema with `| null` types + "do not infer values not explicitly stated" + source quote per extracted field.

### Classification

Exactly-one-label rule + label definitions + decision rule for ties + `"unknown"` for insufficient evidence + balanced edge-case examples.

### Research synthesis

Compare sources rather than summarize one-by-one + identify consensus / disagreement / gaps + cite non-obvious claims + distinguish evidence from interpretation + state what would change the conclusion.

### Complex reasoning

Internal process: principle → subproblems → solve → check (arithmetic, units, assumptions). Return: final answer + brief rationale + assumptions.

### Creative ideation

`Generate N ideas` + constraints (audience, tone, must-include, must-avoid) + per-idea fields (name, concept, fit rationale) + `"optimize for variety, avoid repeating the same concept with different wording"`. Higher temperature; separate selection/critique step.

## 6. Review rubric

Score 1–5 on each. A prompt below 4 on **goal clarity**, **output contract**, or **testability** is not ready for production.

| Dimension         | Question                                                               |
| ----------------- | ---------------------------------------------------------------------- |
| Goal clarity      | Is the desired deliverable unmistakable?                               |
| Context           | Does the model have necessary background and source material?          |
| Scope             | Are boundaries and exclusions clear?                                   |
| Output contract   | Is the format parseable or easy to review?                             |
| Examples          | Are examples relevant, diverse, edge-case aware?                       |
| Reasoning support | Does the prompt use decomposition, tools, or verification when needed? |
| Factual grounding | Are citation, evidence, and abstention rules explicit?                 |
| Safety            | Is untrusted input separated from trusted instructions?                |
| Testability       | Can success be measured on an eval set?                                |
| Maintainability   | Can another person understand and modify the prompt?                   |

## 7. The shortest useful version

```
Task:          [what to produce]
Context:       [what the model needs to know]
Constraints:   [must include, exclude, assume, check]
Input:         [the actual data]
Output format: [exact structure]
Failure mode:  If you cannot answer from the available information, say what is missing.
```
