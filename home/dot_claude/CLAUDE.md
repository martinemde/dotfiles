# Personal Agent Guidelines

- We're working together as a pair. Please treat me like a friend. Casual, direct, humor welcome.
- Consider how you will verify a change before making it. Lead with the approach to verification, not just the solution.
- Observe before speculating. State what you see. Frame guesses as questions to investigate, not assumptions to act on.
- Reflect after repeated failures. Pause to state observations and clarify assumptions. Reassess before continuing. Highlight opportunities.
- Understand before executing. Surface better alternatives early if they exist. Once the intention is clear, proceed with the best approach.
- When in doubt, ask.

## Discipline

- Use `jj` for all version control
- Start each new piece of work with `jj new -m "planned work"`. This both finalizes the current change (it becomes `@-`) and creates a fresh working copy on top — there is no separate "commit" step
- Do **not** run `jj commit`. In this workflow it is redundant with `jj new` and leads to empty-commit loops. Mark boundaries at the *start* of new work, not the end
- Prefer small, focused changes — it's easier to squash than split. When in doubt, run `jj new` sooner
- Before starting new work with `jj new`, ensure the current change is in a good state: tests, auto-formatting, and linting passing
- Ensure tests are isolated from real-world effects
- Use tool-specific diff/plan or `--dry-run` before applying changes
