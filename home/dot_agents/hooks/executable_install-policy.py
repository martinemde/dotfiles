#!/usr/bin/env python3
"""Claude PreToolUse reminder for obvious unmanaged CLI installs, not a sandbox.

Only shell commands exposed in tool_input.command are inspected. Scripts, Python
subprocesses (including Prime's python_repl), aliases and other harness tools can
bypass this check. Canonical agent guidance applies on those paths too.
"""

import json
from pathlib import PurePosixPath
import shlex
import sys


REASON = (
    "Use the installing-tools skill before installing or downloading a CLI. "
    "Keep project dependencies in the project; declare user-wide tools in the "
    "managed dotfiles manifest instead of an ad hoc global install. "
    "This hook only catches common direct shell commands, not every install path."
)


def unmanaged_install(words):
    # Recognize ordinary shell prefixes without interpreting arbitrary shell code.
    while words and ("=" in words[0] or words[0] in {"env", "command", "sudo"}):
        words = words[1:]
    if not words:
        return False
    tool = PurePosixPath(words[0]).name
    args = words[1:]
    global_flag = any(arg in {"-g", "--global", "--user"} or arg.startswith("--global=") for arg in args)
    if tool in {"npx", "bunx", "uvx"}:
        return True
    if tool in {"npm", "pnpm", "yarn", "bun"}:
        if args and (tool, args[0]) in {
            ("npm", "exec"), ("pnpm", "dlx"), ("yarn", "dlx"), ("bun", "x")
        }:
            return True
        return global_flag and any(arg in {"add", "install", "i", "update", "upgrade"} for arg in args) or (
            tool == "yarn" and "global" in args
        )
    if tool == "uv":
        return args[:2] in [["tool", "install"], ["tool", "run"], ["tool", "upgrade"]]
    if tool == "pipx":
        return bool(args) and args[0] in {"install", "run", "upgrade", "upgrade-all"}
    if tool in {"pip", "pip3"}:
        return "install" in args and "--user" in args
    if tool in {"python", "python3"} and args[:2] == ["-m", "pip"]:
        return "install" in args and "--user" in args
    if tool in {"brew", "cargo", "go"}:
        return "install" in args or (tool == "brew" and "upgrade" in args)
    if tool == "mise":
        return global_flag and any(arg in {"use", "install", "upgrade"} for arg in args)
    return False


def blocked(command):
    lexer = shlex.shlex(command, posix=True, punctuation_chars=";&|()")
    lexer.whitespace_split = True
    words = []
    segments = []
    for word in lexer:
        if word and all(char in ";&|()" for char in word):
            segments.append(words)
            words = []
        else:
            words.append(word)
    segments.append(words)
    if any(unmanaged_install(segment) for segment in segments):
        return True
    # Common download-to-shell bootstrap, without trying to parse all pipelines.
    downloads = any(segment and PurePosixPath(segment[0]).name in {"curl", "wget"} for segment in segments)
    shells = any(segment and PurePosixPath(segment[0]).name in {"sh", "bash", "zsh"} for segment in segments)
    return downloads and shells and "|" in command


def main():
    try:
        payload = json.load(sys.stdin)
        command = payload.get("tool_input", {}).get("command", "")
        deny = isinstance(command, str) and blocked(command)
    except (ValueError, TypeError, AttributeError):
        return
    if deny:
        print(json.dumps({"hookSpecificOutput": {
            "hookEventName": "PreToolUse",
            "permissionDecision": "deny",
            "permissionDecisionReason": REASON,
        }}))


if __name__ == "__main__":
    main()
