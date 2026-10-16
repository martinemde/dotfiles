#!/usr/bin/env bats

load test_helper

# No user config, agent, credentials, or network remotes enter these tests.
signing_env() {
  env -i HOME="$TEST_HOME_DIR" PATH="$PATH" \
    XDG_CONFIG_HOME="$TEST_HOME_DIR/.config" \
    JJ_CONFIG="$TEST_TMPDIR/jj.toml" \
    GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null "$@"
}

init_signing_test() {
  local tool
  for tool in chezmoi jj git ssh-keygen; do
    if ! command -v "$tool" >/dev/null 2>&1; then
      skip "$tool not installed"
    fi
  done

  printf '[user]\nname = "Signing Test"\nemail = "signing@example.invalid"\n' \
    >"$TEST_TMPDIR/jj.toml"
  touch "$TEST_TMPDIR/chezmoi.toml"
  cd "$TEST_TMPDIR"
}

render_signing_config() {
  signing_env chezmoi --config "$TEST_TMPDIR/chezmoi.toml" \
    --source "$TEST_SOURCE_DIR" --destination "$TEST_HOME_DIR" \
    execute-template --file \
    "$BATS_TEST_DIRNAME/../home/dot_config/jj/conf.d/signing.toml.tmpl" \
    >>"$TEST_TMPDIR/jj.toml"
}

@test "jj signing stays disabled without a machine-local key" {
  init_signing_test
  render_signing_config

  run signing_env jj config get signing.backend
  [ "$status" -eq 0 ]
  [ "$output" = "none" ]

  run signing_env jj config get git.sign-on-push
  [ "$status" -eq 0 ]
  [ "$output" = "false" ]
}

@test "jj signs with the local private key only when pushing" {
  init_signing_test
  mkdir -p "$TEST_HOME_DIR/.ssh"
  signing_env ssh-keygen -q -t ed25519 -N '' \
    -f "$TEST_HOME_DIR/.ssh/commit_signing"
  render_signing_config

  run signing_env jj config get signing.behavior
  [ "$status" -eq 0 ]
  [ "$output" = "drop" ]

  signing_env jj git init --colocate "$TEST_TMPDIR/repo"
  cd "$TEST_TMPDIR/repo"
  printf 'signing test\n' >example.txt
  signing_env jj describe -m "Signing test"
  signing_env jj new
  signing_env jj bookmark create signing-test -r @-

  run signing_env jj log --no-graph -r @- -T 'if(signature, "signed", "unsigned")'
  [ "$status" -eq 0 ]
  [ "$output" = "unsigned" ]

  signing_env git init --bare "$TEST_TMPDIR/remote.git"
  signing_env jj git remote add origin "$TEST_TMPDIR/remote.git"
  run signing_env jj git push --bookmark signing-test
  [ "$status" -eq 0 ]

  printf 'signing@example.invalid %s\n' \
    "$(cat "$TEST_HOME_DIR/.ssh/commit_signing.pub")" \
    >"$TEST_TMPDIR/allowed-signers"
  run signing_env git --git-dir="$TEST_TMPDIR/remote.git" \
    -c gpg.ssh.allowedSignersFile="$TEST_TMPDIR/allowed-signers" \
    verify-commit refs/heads/signing-test
  [ "$status" -eq 0 ]

  # Pushing must not enable write-time signing for subsequent snapshots.
  run signing_env jj log --no-graph -r @ -T 'if(signature, "signed", "unsigned")'
  [ "$status" -eq 0 ]
  [ "$output" = "unsigned" ]
}
