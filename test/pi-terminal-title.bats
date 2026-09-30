#!/usr/bin/env bats

@test "Pi terminal title follows real TUI lifecycle and input prompts" {
  command -v pi >/dev/null 2>&1 || skip "Pi is not installed"
  command -v python3 >/dev/null 2>&1 || skip "Python 3 is not installed"
  run python3 "$BATS_TEST_DIRNAME/pi-terminal-title.py"
  printf '%s\n' "$output"
  [ "$status" -eq 0 ]
}
