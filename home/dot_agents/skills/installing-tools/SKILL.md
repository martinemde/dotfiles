---
name: installing-tools
description: Choose the right scope and manifest before installing a CLI or runtime, fetching a one-off executable, or fixing a missing tool. Keep project dependencies local and user-wide tools in managed dotfiles.
---

# Installing tools

Check the project's instructions and existing manifests before choosing an install path.
Distinguish a missing dependency from a missing CLI; do not fix either by silently
installing a global executable.

- **Project dependencies:** use its existing package manager, manifest and lockfile.
  `bun add`, `pnpm add`, `bundle install`, and `uv sync` remain project operations.
  Use the project's environment, not the agent's Python kernel.
- **Project CLI/runtime:** use the project's existing tool manifest, such as mise.
  Keep `mise use TOOL@VERSION` project scoped, not `--global`.
- **User-wide CLI:** edit the managed Chezmoi manifest. In the dotfiles repo, use
  `managing-chezmoi-packages` for backend selection, verification and update coverage.
  Existing manifest-driven Bun globals and uv tools are intentional; do not replace
  them with unrecorded `npm/bun/pnpm -g`, `pip --user`, `uv tool install`, `cargo install`,
  `go install`, or `brew install` commands.
- **One-off executable:** `npx`, `bunx`, `uvx`, `npm exec`, and `pnpm dlx` can download
  and execute tools too. Prefer an already declared project executable. If a temporary
  tool is needed, propose an isolated environment and ask before downloading it.

Editing declarations and installing them are separate actions. Before installing,
applying or upgrading tools, state the scope, manifest and verification approach and
get permission. If no managed path exists, explain what is missing rather than
inventing a global install. Do not change projects to a different package manager
just to satisfy this guidance.

The Claude shell hook catches common direct installer commands as a reminder. It is
not a sandbox and does not inspect scripts or Python subprocesses. Prime's
`python_repl` -> `bash(...)` path and other harnesses are not covered by that Claude
hook; follow this guidance there as well.
