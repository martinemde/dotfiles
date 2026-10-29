---
name: eval-instructions
description: A/B-test a change to CLAUDE.md, AGENTS.md, a skill, or an agent before keeping it. Use when trimming or rewriting agent instructions and you need evidence that behavior held, or to show a removed line was dead weight.
---

# Eval instruction changes

`scripts/eval.py` runs the same probes with headless `claude -p` in a baseline checkout and a
candidate checkout (or worktree), grades each answer, and reports pass rates, cost per run,
and the always-loaded token count of each arm.

1. Put the change in a worktree; the main checkout is the baseline.
2. Write a probe for every rule you removed or rewrote, plus a few for rules you kept as a
   control. A probe is a realistic task whose right answer depends on the rule, graded by
   regexes (`must`, `must_not`; lines that reject a pattern don't count against it) and
   optionally an LLM `judge` rubric. Name what it guards in `covers`.
3. Run 3 reps per arm: `scripts/eval.py probes.json --baseline MAIN --candidate WORKTREE
--reps 3 -j 6 --out results.json`. Rescore stored answers after fixing a probe with
   `--regrade results.json`; `--tokens-only` measures context size alone.

To test user-level files, set `config_dirs` per arm to a fake home containing `.claude/`
(CLAUDE.md, skills, agents) and `.agents/`. The script adds a `settings.json` with
`syncClaudeAiSkills: false` if the fake home has none; otherwise account skills sync into the
symlinked skills directory, i.e. into the checkout. The script clears this session's extra
CLAUDE.md directories so each arm sees only its own instructions.

A failing probe in both arms is a probe problem or a gap the instructions never covered;
read the answers before blaming the change. Lower cost per run at the same pass rate is the
evidence that removed text was dead weight.
