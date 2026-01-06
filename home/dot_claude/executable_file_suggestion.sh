#!/bin/bash
# Fast file suggestion for Claude Code @file autocomplete

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
    first_term="${safe_query%%[/.-]*}"
    if [[ -n "$first_term" ]] && [[ ${#first_term} -ge 2 ]]; then
      rg -i "$first_term" "$CACHE_FILE" 2>/dev/null | fzf --filter="$query" 2>/dev/null | head -15 || true
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
