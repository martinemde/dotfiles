#!/usr/bin/env bats

load test_helper

@test "tmux persistence plugins work from local pinned sources" {
  [ -n "${TMUX_PLUGIN_SOURCES:-}" ] || skip "set TMUX_PLUGIN_SOURCES to downloaded pinned plugin directories"
  command -v tmux >/dev/null || skip "tmux not installed"
  run python3 test/tmux-plugins.py
  [ "$status" -eq 0 ]
}
