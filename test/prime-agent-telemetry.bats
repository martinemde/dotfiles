#!/usr/bin/env bats

load test_helper

apply_prime_settings() {
  chezmoi --config /dev/null --config-format toml \
    --source "$TEST_SOURCE_DIR" --destination "$TEST_HOME_DIR" \
    --persistent-state "$TEST_TMPDIR/chezmoi-state.boltdb" \
    apply
}

prepare_prime_source() {
  mkdir -p "$TEST_SOURCE_DIR/dot_prime/agent"
  cp home/dot_prime/agent/modify_private_settings.json "$TEST_SOURCE_DIR/dot_prime/agent/"
}

@test "Prime Agent telemetry is disabled without replacing local settings" {
  prepare_prime_source
  local settings="$TEST_HOME_DIR/.prime/agent/settings.json"
  mkdir -p "$(dirname "$settings")"
  printf '%s\n' '{"defaultModel":"local-model","telemetry":{"enabled":true,"noticeShown":true},"skills":["local-skill"]}' >"$settings"

  run apply_prime_settings
  [ "$status" -eq 0 ]
  jq -e '. == {"defaultModel":"local-model","telemetry":{"enabled":false,"noticeShown":true},"skills":["local-skill"]}' "$settings"

  cp "$settings" "$TEST_TMPDIR/first.json"
  run apply_prime_settings
  [ "$status" -eq 0 ]
  cmp "$settings" "$TEST_TMPDIR/first.json"
}

@test "Prime Agent telemetry config is created on a fresh install" {
  prepare_prime_source
  run apply_prime_settings
  [ "$status" -eq 0 ]
  jq -e '. == {"telemetry":{"enabled":false}}' "$TEST_HOME_DIR/.prime/agent/settings.json"
}

@test "non-interactive shells export the Prime Agent telemetry opt-out" {
  command -v zsh >/dev/null 2>&1 || skip "zsh not installed"
  chezmoi --config /dev/null --config-format toml \
    --source "$BATS_TEST_DIRNAME/../home" \
    execute-template --file "$BATS_TEST_DIRNAME/../home/dot_zshenv.tmpl" >"$TEST_TMPDIR/zshenv"
  run env -i HOME="$TEST_HOME_DIR" PATH="$PATH" zsh -dfc \
    'source "$1"; sh -c '\''test "$PRIME_AGENT_TELEMETRY" = 0'\''' zsh "$TEST_TMPDIR/zshenv"
  [ "$status" -eq 0 ]
}
