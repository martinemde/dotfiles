#!/usr/bin/env bats

load test_helper

ssh_chezmoi() {
  env HOME="$TEST_HOME_DIR" chezmoi --config "$TEST_TMPDIR/chezmoi.toml" \
    --source "$TEST_SOURCE_DIR" --destination "$TEST_HOME_DIR" \
    --persistent-state "$TEST_TMPDIR/state.boltdb" "$@"
}

init_ssh_test() {
  local tool
  for tool in chezmoi ssh; do
    command -v "$tool" >/dev/null 2>&1 || skip "$tool not installed"
  done
  touch "$TEST_TMPDIR/chezmoi.toml"
  cp -R "$BATS_TEST_DIRNAME/../home/private_dot_ssh" "$TEST_SOURCE_DIR/"
  mkdir -p "$TEST_SOURCE_DIR/.chezmoiscripts"
  cp "$BATS_TEST_DIRNAME/../home/.chezmoiscripts/run_after_ensure-ssh-config-include.sh" \
    "$TEST_SOURCE_DIR/.chezmoiscripts/"
  cd "$TEST_TMPDIR"
}

ssh_settings() {
  # Absolute paths keep ssh -F independent of the real user's ~/.ssh.
  # Relative Include paths resolve against the OS account home, not $HOME.
  sed "s|Include config.d/\*.conf|Include $TEST_HOME_DIR/.ssh/config.d/*.conf|" \
    "$TEST_HOME_DIR/.ssh/config" >"$TEST_TMPDIR/ssh_config"
  ssh -G -F "$TEST_TMPDIR/ssh_config" "$1" 2>/dev/null
}

@test "fresh SSH install loads shared settings and reapplies without changes" {
  init_ssh_test
  ssh_chezmoi apply
  cp "$TEST_HOME_DIR/.ssh/config" "$TEST_TMPDIR/original"
  ssh_chezmoi apply
  cmp "$TEST_TMPDIR/original" "$TEST_HOME_DIR/.ssh/config"

  run ssh_settings homeassistant.local
  [ "$status" -eq 0 ]
  [[ "$output" == *"hashknownhosts yes"* ]]
  [[ "$output" == *"setenv TERM=xterm-256color"* ]]

  run ssh_chezmoi managed
  [ "$status" -eq 0 ]
  [[ "$output" == *".ssh/config.d/90-dotfiles.conf"* ]]
  [[ "$(printf '%s\n' "$output" | grep -x '.ssh/config' || true)" == "" ]]
}

@test "migration keeps machine-local content and local overrides" {
  init_ssh_test
  mkdir -p "$TEST_HOME_DIR/.ssh"
  printf '# machine local\nHost homeassistant.local\n  SetEnv TERM=local\n  HashKnownHosts no\nHost coder.test\n  ProxyCommand coder ssh --stdio coder.test\n' \
    >"$TEST_HOME_DIR/.ssh/config"
  cp "$TEST_HOME_DIR/.ssh/config" "$TEST_TMPDIR/original"
  ssh_chezmoi apply
  head -n 6 "$TEST_HOME_DIR/.ssh/config" >"$TEST_TMPDIR/preserved"
  cmp "$TEST_TMPDIR/original" "$TEST_TMPDIR/preserved"

  run ssh_settings homeassistant.local
  [ "$status" -eq 0 ]
  [[ "$output" == *"hashknownhosts no"* ]]
  [[ "$output" == *"setenv TERM=local"* ]]
  run ssh_settings other.invalid
  [ "$status" -eq 0 ]
  [[ "$output" == *"hashknownhosts yes"* ]]
}

@test "an existing snippet include is left untouched" {
  init_ssh_test
  mkdir -p "$TEST_HOME_DIR/.ssh"
  printf 'Include config.d/*.conf\nHost local\n  User someone\n' >"$TEST_HOME_DIR/.ssh/config"
  cp "$TEST_HOME_DIR/.ssh/config" "$TEST_TMPDIR/original"
  ssh_chezmoi apply
  cmp "$TEST_TMPDIR/original" "$TEST_HOME_DIR/.ssh/config"
}

@test "the include escapes a trailing machine-local Match block" {
  init_ssh_test
  mkdir -p "$TEST_HOME_DIR/.ssh"
  printf 'Match host never.invalid\n  User someone\nInclude config.d/*.conf\n' >"$TEST_HOME_DIR/.ssh/config"
  ssh_chezmoi apply
  run ssh_settings other.invalid
  [ "$status" -eq 0 ]
  [[ "$output" == *"hashknownhosts yes"* ]]
}

@test "shared Match conditions do not constrain later snippets" {
  init_ssh_test
  ssh_chezmoi apply
  printf '  ServerAliveInterval 43\n' \
    >"$TEST_HOME_DIR/.ssh/config.d/99-local.conf"
  # Exercise the macOS SSH-session branch where the agent Match is false.
  export SSH_CONNECTION='127.0.0.1 1234 127.0.0.1 22'
  run ssh_settings other.invalid
  [ "$status" -eq 0 ]
  [[ "$output" == *"serveraliveinterval 43"* ]]
}
