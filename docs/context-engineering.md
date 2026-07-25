# Context Engineering

Conventions for everything Claude loads as context: `AGENTS.md`/`CLAUDE.md`, agent
definitions, and skills — both the repo-local ones under `.claude/` and the global
ones chezmoi writes to `~/.claude/`.

## Problem

The instruction files had accreted the habits of earlier model generations: capitalized
imperatives (`CRITICAL`, `ALWAYS`, `NEVER`), the same rule restated in three layers,
few-shot examples pinned to every agent, and rigid output templates. Several files were
near-duplicates of each other — `.claude/agents/package-manager.md` reproduced most of
`.claude/skills/chezmoi/`, and `home/dot_claude/agents/prompt-engineer/` restated its
own skill's output contract verbatim.

That style is now counterproductive. Anthropic's
[new rules of context engineering for Claude 5 generation models](https://claude.com/blog/the-new-rules-of-context-engineering-for-claude-5-generation-models)
reports removing over 80% of the constraints from Claude Code's own system prompt and
skills, on the finding that they were "overconstraining Claude, both through our system
prompt and in our CLAUDE.md files and skills," with conflicting messages causing
"unnecessary cognitive overhead."

## Decisions

**Judgment over rules.** State the intent and let the model decide the application.
The canonical example from the post: "Never write multi-paragraph docstrings" became
"Write code that reads like the surrounding code: match its comment density, naming, and
idiom." Rules survive only where the cost of a wrong call is unrecoverable — the jj
safety protocol and secret handling in `home/dot_claude/CLAUDE.md` stay imperative,
because "don't rewrite history you didn't create" is not a stylistic preference.

**One home per instruction.** Trigger conditions live in the frontmatter `description`,
which is the only part loaded until the skill fires. Procedure lives in the body. Nothing
is restated in a parent `CLAUDE.md`. A "When to use this skill" section duplicating the
description is pure overhead.

**Progressive disclosure over completeness.** Long skills become a directory: a short
`SKILL.md` that orients and an index of `references/*.md` loaded on demand. Applied to
`ghostty-shaders`, which was a 677-line monolith carrying a full GLSL language reference
into context for a one-line shader edit.

**Interfaces over examples.** Few-shot examples "actually constrain [models] to a certain
exploration space." Agent descriptions carry expressive trigger conditions instead of
worked `<example>` transcripts; skills describe the shape of a good answer instead of a
fill-in template.

**Gotchas over inventory.** `AGENTS.md` spends its tokens on what Claude cannot infer from
the file tree — that `sourceDir` is the working tree, that prettier is deliberately outside
mise, that `.tmpl` files are excluded from formatting. Install steps, directory listings,
and troubleshooting live in `README.md` and `docs/`, where a human reads them.

## Trade-offs

Deleting the emphasis markers means a genuinely load-bearing constraint no longer looks
different from a preference. The mitigation is placement rather than volume: safety
constraints go in their own section near the top of the file that owns them, and nowhere
else.

Progressive disclosure costs a tool call when the reference is needed, and risks the model
answering from memory rather than opening the file. Reference indexes therefore say what
each file settles, not just its title.

Explicitly not done: collapsing `AGENTS.md` into skills-only. The `home/` vs `~/` editing
rule has to be in always-loaded context, since violating it silently produces work that
`chezmoi apply` destroys.
