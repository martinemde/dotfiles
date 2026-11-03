#!/usr/bin/env bats

@test "Prime Coder launcher uses offline process and daemon boundaries" {
  command -v python3 >/dev/null 2>&1 || skip "Python 3 is not installed"
  run python3 "$BATS_TEST_DIRNAME/prime-coder.py"
  printf '%s\n' "$output"
  [ "$status" -eq 0 ]
}
