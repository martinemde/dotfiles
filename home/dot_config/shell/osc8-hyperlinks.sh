#!/usr/bin/env bash
# OSC 8 hyperlink support for terminal
#
# Provides functions to emit OSC 8 hyperlinks in the terminal
# Supported by ghostty, iTerm2, kitty, wezterm, and others
#
# Reference: https://gist.github.com/egmontkob/eb114294efbcd5adb1944c9f3cb5feda

# Check if terminal supports OSC 8 hyperlinks
_osc8_supported() {
  # Check for known supporting terminals
  case "${TERM_PROGRAM:-}" in
    ghostty|iTerm.app|WezTerm) return 0 ;;
  esac

  # Check TERM variable
  case "${TERM:-}" in
    xterm-ghostty|xterm-kitty|wezterm) return 0 ;;
  esac

  # Inside tmux, check outer terminal
  if [[ -n "${TMUX:-}" ]]; then
    # Assume support if using ghostty or modern terminal
    return 0
  fi

  return 1
}

# Emit OSC 8 hyperlink
# Usage: osc8_link <url> <text>
osc8_link() {
  local url="$1"
  local text="${2:-$url}"

  if ! _osc8_supported; then
    echo -n "$text"
    return
  fi

  printf '\e]8;;%s\e\\%s\e]8;;\e\\' "$url" "$text"
}

# Create file hyperlink
# Usage: file_link <path> [line] [text]
file_link() {
  local file="$1"
  local line="${2:-}"
  local text="${3:-}"

  # Make path absolute
  if [[ ! "$file" =~ ^/ ]]; then
    file="$(cd "$(dirname "$file")" && pwd)/$(basename "$file")"
  fi

  # Build URI
  local uri="file://${file}"
  if [[ -n "$line" ]]; then
    uri="${uri}:${line}"
  fi

  # Default text to filename with line number
  if [[ -z "$text" ]]; then
    text="$file"
    [[ -n "$line" ]] && text="${text}:${line}"
  fi

  osc8_link "$uri" "$text"
}

# Enhanced grep with hyperlinks
# Usage: hgrep <pattern> [grep args...]
hgrep() {
  if ! _osc8_supported; then
    command grep --color=auto -n "$@"
    return
  fi

  # Run grep and add hyperlinks
  command grep --color=auto -n "$@" | while IFS=: read -r file line content; do
    printf '%s:%s:%s\n' "$(file_link "$file" "$line")" "$line" "$content"
  done
}

# Enhanced ripgrep wrapper (if rg is installed)
if command -v rg &>/dev/null; then
  hrg() {
    if ! _osc8_supported; then
      rg "$@"
      return
    fi

    rg --line-number --color=always "$@" | while IFS=: read -r file line content; do
      if [[ -f "$file" ]]; then
        printf '%s:%s:%s\n' "$(file_link "$file" "$line")" "$line" "$content"
      else
        printf '%s:%s:%s\n' "$file" "$line" "$content"
      fi
    done
  }
fi

# ls with file hyperlinks
hls() {
  if ! _osc8_supported || ! command -v gls &>/dev/null; then
    command ls --color=auto "$@"
    return
  fi

  # Use GNU ls with hyperlink support
  gls --color=auto --hyperlink=auto "$@"
}

# Print file path as hyperlink
# Usage: flink <file> [line]
flink() {
  local file="$1"
  local line="${2:-}"

  file_link "$file" "$line"
  echo
}

# Export functions for use in subshells
export -f _osc8_supported osc8_link file_link flink 2>/dev/null || true

# vim: ft=bash
