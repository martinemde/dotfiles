---
description: Make small focused commits with jj-vcs, e.g. `jj commit -m "message"`. Use when asked to commit changes or when starting new work.
---

Make focused commits using `jj` to create a clean atomic history resulting in a fully clean working copy.

- If there is existing changes, prefer splitting commits.
- Organize with `jj split -m "message" <files>` or `jj squash --use-destination-message <files>`
- Commit message should finish the phrase: "This commit will..."
- Follow conventional commits if the repository already uses them
- Explain _why_ in the commit body
- Add `Fixes #NN` if applicable
- When committing before starting new work, start clean with `jj new -m "<goal of new work>"`
