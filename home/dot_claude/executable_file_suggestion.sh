#!/bin/bash
#
# Fast file suggestion for Claude Code @file in big repositories
#
# Repository: https://github.com/martinemde/dotfiles
#
# Usage:
#   Add to ~/.claude/settings.json:
#   {
#     "fileSuggestion": {
#       "type": "command",
#       "command": "~/.claude/file_suggestion.sh"
#     }
#   }
#
# MIT License
# Copyright (c) 2026 Martin Emde
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

cd "${CLAUDE_PROJECT_DIR:-.}" || exit 1

# Parse query from JSON input
read -r input
query="${input#*\"query\"*:}"
query="${query#"${query%%[![:space:]]*}"}"
query="${query#\"}"
query="${query%%\"*}"

# Check for fzf once
HAS_FZF=0
command -v fzf &>/dev/null && HAS_FZF=1

# Check if we're in a git repo (works for normal repos and worktrees)
if [[ -e .git ]]; then
  # Git repo: use cached file list
  CACHE_FILE=".claude/file-suggestions.cache"

  [[ -d .claude ]] || mkdir -p .claude 2>/dev/null

  # Rebuild cache if stale (git index/HEAD newer than cache)
  # For worktrees, .git is a file - cache check fails, always rebuilds (correct but slower)
  if [[ ! -f "$CACHE_FILE" ]] ||
    [[ .git/index -nt "$CACHE_FILE" ]] ||
    [[ .git/HEAD -nt "$CACHE_FILE" ]]; then
    {
      git ls-files
      git ls-files --others --exclude-standard
    } 2>/dev/null | sort -u >"$CACHE_FILE"
  fi

  # Search cached file list
  if [[ -z "$query" ]]; then
    head -15 "$CACHE_FILE"
  elif [[ $HAS_FZF -eq 1 ]]; then
    safe_query="${query//[^a-zA-Z0-9_\/.-]/}"
    # Extract first few chars for rg pre-filter (not whole first term)
    first_chars="${safe_query:0:3}"
    if [[ -n "$first_chars" ]] && [[ ${#first_chars} -ge 2 ]]; then
      # Pre-filter with just first 2-3 chars to keep rg fast but not too restrictive
      rg -i "$first_chars" "$CACHE_FILE" 2>/dev/null | fzf --filter="$query" 2>/dev/null | head -15 || true
    else
      fzf --filter="$query" <"$CACHE_FILE" 2>/dev/null | head -15 || true
    fi
  else
    # Fallback: bash expansion instead of echo|sed
    pattern="${query//[^a-zA-Z0-9_\/.-]/}"
    pattern="${pattern//[\/.-]/.*/}"
    rg -i "$pattern" "$CACHE_FILE" 2>/dev/null | head -15 || true
  fi
else
  # Non-git: use fd or find with fzf (no caching)
  if command -v fd &>/dev/null; then
    get_files() { fd --type f --hidden --exclude .git 2>/dev/null; }
  else
    get_files() { find . -type f -not -path '*/.git/*' 2>/dev/null | sed 's|^\./||'; }
  fi

  if [[ -z "$query" ]]; then
    get_files | head -15
  elif [[ $HAS_FZF -eq 1 ]]; then
    get_files | fzf --filter="$query" 2>/dev/null | head -15 || true
  else
    pattern="${query//[^a-zA-Z0-9_\/.-]/}"
    pattern="${pattern//[\/.-]/.*/}"
    get_files | grep -iE "$pattern" 2>/dev/null | head -15 || true
  fi
fi
