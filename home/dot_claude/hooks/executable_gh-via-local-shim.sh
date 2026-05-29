#!/usr/bin/env bash
# PreToolUse(Bash) hook: make `gh` resolve the right repo inside jj workspaces.
#
# `gh` shells out to git for repo detection. In a non-colocated jj workspace
# there is no local .git, so gh walks UP the tree and resolves whatever parent
# repo it finds first (e.g. ~/pt/.git -> the wrong owner/repo). The shim at
# ~/.local/bin/gh fixes this by setting GIT_DIR from `jj git root`, but it only
# wins if ~/.local/bin precedes the real gh on PATH — which isn't guaranteed in
# every shell Claude spawns.
#
# This hook fronts ~/.local/bin on PATH for `gh` invocations so the shim is the
# gh that runs. It is a no-op anywhere the shim doesn't exist (gh falls through
# to the next PATH entry) and anywhere outside a jj workspace (the shim itself
# no-ops). Filtered to `gh *` commands via the hook's `if` clause.
set -uo pipefail

# Without jq we can't rewrite the input; proceed with the command untouched.
command -v jq >/dev/null 2>&1 || exit 0

# $HOME / $PATH stay literal in the rewritten command so the spawning shell
# expands them at run time.
jq -c '{
  hookSpecificOutput: {
    hookEventName: "PreToolUse",
    updatedInput: (.tool_input + {
      command: ("PATH=\"$HOME/.local/bin:$PATH\" " + .tool_input.command)
    })
  }
}' 2>/dev/null || exit 0
