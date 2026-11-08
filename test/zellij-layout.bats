#!/usr/bin/env bats

load test_helper

render_layout() {
  local os="$1" distro="$2" kernel="$3"
  chezmoi --config /dev/null --config-format toml --source "$TEST_SOURCE_DIR" \
    --override-data "{\"chezmoi\":{\"os\":\"$os\",\"osRelease\":{\"id\":\"$distro\"},\"kernel\":{\"osrelease\":\"$kernel\"}}}" \
    execute-template --file home/dot_config/zellij/layouts/default.kdl.tmpl
}

check_layout() {
  local os="$1" distro="$2" kernel="$3" icon="$4"
  render_layout "$os" "$distro" "$kernel" >"$TEST_TMPDIR/layout.kdl"
  grep -F "$icon" "$TEST_TMPDIR/layout.kdl"
  printf 'default_shell "/bin/sh"\n' >"$TEST_TMPDIR/config.kdl"
  run zellij --config "$TEST_TMPDIR/config.kdl" --layout "$TEST_TMPDIR/layout.kdl" setup --check
  printf '%s\n' "$output"
  [ "$status" -eq 0 ]
}

@test "Zellij accepts rendered macOS and Linux layouts with Starship OS icons" {
  command -v zellij >/dev/null 2>&1 || skip "zellij not installed"
  check_layout darwin '' '' '󰀵'
  check_layout linux fedora 6.12 '󰣛'
  check_layout linux debian 6.12 '󰣚'
  check_layout linux ubuntu 6.12 '󰕈'
  check_layout linux alpine 6.12 '󰌽'
}

@test "Zellij accepts Raspberry Pi OS layouts for Raspbian and Debian rpi kernels" {
  command -v zellij >/dev/null 2>&1 || skip "zellij not installed"
  check_layout linux raspbian 6.12 ''
  check_layout linux debian 6.12.47+rpt-rpi-v8 ''
}
