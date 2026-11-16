#!/usr/bin/env bats

load test_helper

@test "Codex Root Shell hook preserves local hooks and deduplicates on reapply" {
  mkdir -p "$TEST_SOURCE_DIR/dot_codex" "$TEST_HOME_DIR/.codex"
  cp home/dot_codex/modify_private_hooks.json "$TEST_SOURCE_DIR/dot_codex/"
  cat >"$TEST_HOME_DIR/.codex/hooks.json" <<'JSON'
{"custom":true,"hooks":{"SessionStart":[{"hooks":[{"type":"command","command":"local-start"}]}],"Stop":[{"hooks":[{"type":"command","command":"local-stop"},{"type":"command","command":"rootshell-notify hook --agent codex","timeout":1}]}]}}
JSON
  local target="$TEST_HOME_DIR/.codex/hooks.json"
  for pass in 1 2; do
    run chezmoi --config /dev/null --config-format toml \
      --source "$TEST_SOURCE_DIR" --destination "$TEST_HOME_DIR" \
      --persistent-state "$TEST_TMPDIR/state.boltdb" apply
    [ "$status" -eq 0 ]
    jq -e '. == {"custom":true,"hooks":{"SessionStart":[{"hooks":[{"type":"command","command":"local-start"}]}],"Stop":[{"hooks":[{"type":"command","command":"local-stop"}]},{"hooks":[{"type":"command","command":"rootshell-notify hook --agent codex","async":false,"timeout":10,"_rootshell":"push"}]}]}}' "$target"
  done
}
