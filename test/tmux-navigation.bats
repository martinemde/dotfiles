#!/usr/bin/env bats

# Tmux Navigation Tests
# Tests for edge-aware tmux/vim pane and window navigation.
# Validates bindings.conf syntax, nvim tmux-nav module, and functional
# navigation behavior using isolated tmux server sockets.

load test_helper

TMUX_SOCKET="bats-nav-$$"
BINDINGS="home/dot_config/tmux/bindings.conf"
NAV_LUA="home/dot_config/nvim/lua/config/tmux-nav.lua"

# Kill the test tmux server after each test
teardown() {
  tmux -L "$TMUX_SOCKET" kill-server 2>/dev/null || true
  rm -rf "$TEST_TMPDIR"
}

# Helper: start isolated tmux server with a named session
start_tmux() {
  tmux -L "$TMUX_SOCKET" new-session -d -s test -x 80 -y 24
}

# Helper: run a tmux command against the test server
t() {
  tmux -L "$TMUX_SOCKET" "$@"
}

# Helper: wait briefly for tmux async commands to settle
settle() { sleep 0.3; }

# =============================================================================
# Static validation
# =============================================================================

@test "bindings.conf can be sourced by tmux" {
  if ! command -v tmux >/dev/null 2>&1; then
    skip "tmux not installed"
  fi

  start_tmux
  # source-file will error on syntax problems
  run t source-file "$BINDINGS"
  [ "$status" -eq 0 ]
}

@test "bindings.conf registers C-h/C-j/C-k/C-l in root table" {
  if ! command -v tmux >/dev/null 2>&1; then
    skip "tmux not installed"
  fi

  start_tmux
  t source-file "$BINDINGS"

  for key in C-h C-j C-k C-l; do
    run t list-keys -T root "$key"
    [ "$status" -eq 0 ]
  done
}

@test "C-h/C-l bindings use if-shell -F for edge detection" {
  if ! command -v tmux >/dev/null 2>&1; then
    skip "tmux not installed"
  fi

  start_tmux
  t source-file "$BINDINGS"

  run t list-keys -T root C-h
  [[ "$output" == *'if-shell -F "#{pane_at_left}"'* ]]

  run t list-keys -T root C-l
  [[ "$output" == *'if-shell -F "#{pane_at_right}"'* ]]
}

@test "tmux-nav.lua has valid lua syntax" {
  if command -v luac >/dev/null 2>&1; then
    run luac -p "$NAV_LUA"
    [ "$status" -eq 0 ]
  elif command -v nvim >/dev/null 2>&1; then
    run nvim --headless -u NONE -c "luafile $NAV_LUA" +qall 2>&1
    [ "$status" -eq 0 ]
  else
    skip "no lua parser available"
  fi
}

@test "tmux-nav.lua registers C-h/C-j/C-k/C-l keymaps in neovim" {
  if ! command -v nvim >/dev/null 2>&1; then
    skip "neovim not installed"
  fi

  # Run headless nvim, load the module, check keymaps exist
  run nvim --headless --noplugin -u NONE \
    -c "lua package.path = 'home/dot_config/nvim/lua/?.lua;' .. package.path" \
    -c 'lua require("config.tmux-nav").setup()' \
    -c 'lua for _,k in ipairs({"<C-h>","<C-j>","<C-k>","<C-l>","<C-\\>"}) do local m = vim.fn.maparg(k, "n"); if m == "" then vim.print("MISSING:" .. k); vim.cmd("cq") end end; vim.print("ALL_MAPPED")' \
    -c 'qall!' 2>&1
  [ "$status" -eq 0 ]
  [[ "$output" == *"ALL_MAPPED"* ]]
}

# =============================================================================
# Functional: tmux edge-detection logic
# =============================================================================
# tmux send-keys bypasses the binding table, so we test the commands
# that the bindings execute rather than simulating keypresses.

@test "if-shell -F at left edge runs previous-window" {
  if ! command -v tmux >/dev/null 2>&1; then
    skip "tmux not installed"
  fi

  start_tmux
  # Create window 2, return to window 1 (single pane = at left edge)
  t new-window -t test
  t select-window -t test:1

  # Run the exact command from the C-h binding's false branch
  t if-shell -F "#{pane_at_left}" "previous-window" "select-pane -LZ"
  settle

  run t display-message -t test -p '#{window_index}'
  [ "$output" = "2" ]
}

@test "if-shell -F at right edge runs next-window" {
  if ! command -v tmux >/dev/null 2>&1; then
    skip "tmux not installed"
  fi

  start_tmux
  # Create window 2, stay on window 1 (single pane = at right edge)
  t new-window -t test
  t select-window -t test:1

  t if-shell -F "#{pane_at_right}" "next-window" "select-pane -RZ"
  settle

  run t display-message -t test -p '#{window_index}'
  [ "$output" = "2" ]
}

@test "if-shell -F not at left edge runs select-pane -L" {
  if ! command -v tmux >/dev/null 2>&1; then
    skip "tmux not installed"
  fi

  start_tmux
  # Split: pane 1 (left) | pane 2 (right, active)
  # Active pane is NOT at left edge
  t split-window -h -t test
  settle

  local pane_before
  pane_before=$(t display-message -t test -p '#{pane_index}')

  t if-shell -F "#{pane_at_left}" "previous-window" "select-pane -LZ"
  settle

  local pane_after
  pane_after=$(t display-message -t test -p '#{pane_index}')

  [ "$pane_before" != "$pane_after" ]
}

@test "if-shell -F not at right edge runs select-pane -R" {
  if ! command -v tmux >/dev/null 2>&1; then
    skip "tmux not installed"
  fi

  start_tmux
  # Split and select the left pane — NOT at right edge
  t split-window -h -t test
  t select-pane -t test:.1
  settle

  local pane_before
  pane_before=$(t display-message -t test -p '#{pane_index}')

  t if-shell -F "#{pane_at_right}" "next-window" "select-pane -RZ"
  settle

  local pane_after
  pane_after=$(t display-message -t test -p '#{pane_index}')

  [ "$pane_before" != "$pane_after" ]
}

@test "select-pane -D moves down" {
  if ! command -v tmux >/dev/null 2>&1; then
    skip "tmux not installed"
  fi

  start_tmux
  # Split vertically, select top pane
  t split-window -v -t test
  t select-pane -t test:.1
  settle

  local pane_before
  pane_before=$(t display-message -t test -p '#{pane_index}')

  t select-pane -DZ
  settle

  local pane_after
  pane_after=$(t display-message -t test -p '#{pane_index}')

  [ "$pane_before" != "$pane_after" ]
}

@test "select-pane -U moves up" {
  if ! command -v tmux >/dev/null 2>&1; then
    skip "tmux not installed"
  fi

  start_tmux
  # Split vertically, stay on bottom pane
  t split-window -v -t test
  settle

  local pane_before
  pane_before=$(t display-message -t test -p '#{pane_index}')

  t select-pane -UZ
  settle

  local pane_after
  pane_after=$(t display-message -t test -p '#{pane_index}')

  [ "$pane_before" != "$pane_after" ]
}
