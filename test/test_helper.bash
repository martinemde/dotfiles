#!/usr/bin/env bats

# Test helper for chezmoi brew bundle tests
# This file is automatically loaded by bats

# Setup function that runs before each test
setup() {
  # Create temporary directories for testing
  TEST_TMPDIR=$(mktemp -d)
  export TEST_TMPDIR
  export TEST_SOURCE_DIR="$TEST_TMPDIR/source"
  export TEST_HOME_DIR="$TEST_TMPDIR/home"

  mkdir -p "$TEST_SOURCE_DIR"
  mkdir -p "$TEST_HOME_DIR"

  # Set up test environment variables
  export CHEZMOI_SOURCE_DIR="$TEST_SOURCE_DIR"
  export CHEZMOI_HOME_DIR="$TEST_HOME_DIR"
}

# Teardown function that runs after each test
teardown() {
  # Clean up temporary directories
  rm -rf "$TEST_TMPDIR"
}

# Helper function to assert valid YAML
assert_valid_yaml() {
  local file="$1"

  yq '.' "$file" >/dev/null
}

# Helper function to assert valid shell syntax
assert_valid_shell() {
  local script="$1"

  # Write script to temporary file for shellcheck
  local temp_script="$TEST_TMPDIR/temp_script.sh"
  echo "$script" >"$temp_script"

  # Test basic syntax with bash -n
  bash -n "$temp_script"

  # Test with shellcheck if available
  if command -v shellcheck >/dev/null 2>&1; then
    shellcheck "$temp_script"
  fi
}

# Helper function to assert script has proper structure
assert_script_structure() {
  local script="$1"

  # Should start with shebang
  [[ "$script" == *"#!/bin/bash"* || "$script" == *"#!/bin/sh"* ]]

  # Should be syntactically valid
  echo "$script" >"$TEST_TMPDIR/temp.sh"
  bash -n "$TEST_TMPDIR/temp.sh"
}

# Keep broker installation detection isolated from the machine running the tests.
prepare_gh_app_source() {
  mkdir -p "$TEST_SOURCE_DIR/.chezmoitemplates" "$TEST_SOURCE_DIR/dot_config/mise"
  sed "s|/usr/local/lib/gh-app-broker|$TEST_TMPDIR/broker-install|" \
    "$BATS_TEST_DIRNAME/../home/.chezmoitemplates/github-app-installed" \
    >"$TEST_SOURCE_DIR/.chezmoitemplates/github-app-installed"
  cp "$BATS_TEST_DIRNAME/../home/dot_config/mise/config.toml" "$TEST_SOURCE_DIR/dot_config/mise/config.toml"
  if [ "${1:-1}" = 1 ]; then
    mkdir -p "$TEST_TMPDIR/broker-install"
  else
    rmdir "$TEST_TMPDIR/broker-install" 2>/dev/null || true
  fi
}
