#!/usr/bin/env bats

# Configuration Validation Tests
# Tests that validate config files can be loaded by their respective tools
# This allows catching errors before applying chezmoi

load test_helper

# Helper to render a template file
render_template() {
  local file="$1"
  local hosttype="${2:-work}"
  chezmoi execute-template --config /dev/null --config-format toml --source "$BATS_TEST_DIRNAME/../home" \
    --override-data "{\"hosttype\":\"$hosttype\",\"git\":{\"name\":\"CI Test\",\"email\":\"ci@example.com\"}}" \
    --file "$file"
}

# Helper to render and write template to temp file
render_to_temp() {
  local file="$1"
  local temp_file="$TEST_TMPDIR/$(basename "$file" .tmpl)"
  render_template "$file" > "$temp_file"
  echo "$temp_file"
}

# ==============================================================================
# Shell Configuration Tests
# ==============================================================================

@test "zshrc has valid syntax" {
  if ! command -v zsh >/dev/null 2>&1; then
    skip "zsh not installed"
  fi

  local file="home/dot_zshrc"

  # Create a temporary file with the zshrc content
  local temp_file="$TEST_TMPDIR/.zshrc"
  cat "$file" > "$temp_file"

  # Check syntax without executing
  run zsh -n "$temp_file"
  [ "$status" -eq 0 ]
}

@test "zshenv template renders and has valid syntax" {
  if ! command -v zsh >/dev/null 2>&1; then
    skip "zsh not installed"
  fi

  local file="home/dot_zshenv.tmpl"

  # Render template
  run render_template "$file"
  [ "$status" -eq 0 ]

  # Check syntax
  echo "$output" > "$TEST_TMPDIR/.zshenv"
  run zsh -n "$TEST_TMPDIR/.zshenv"
  [ "$status" -eq 0 ]
}

@test "zshenv exposes mise shims without automatic installs in non-interactive shells" {
  if ! command -v zsh >/dev/null 2>&1; then
    skip "zsh not installed"
  fi

  local rendered_file
  rendered_file="$(render_to_temp "home/dot_zshenv.tmpl")"
  mkdir -p "$TEST_HOME_DIR/.local/share/mise/shims"
  touch "$TEST_HOME_DIR/.local/share/mise/shims/ruby"
  chmod +x "$TEST_HOME_DIR/.local/share/mise/shims/ruby"

  run env -i HOME="$TEST_HOME_DIR" PATH="/usr/bin:/bin" MISE_AUTO_INSTALL=1 /bin/zsh -dfc \
    "source \"$rendered_file\"; command -v ruby; print -r -- \"\$MISE_AUTO_INSTALL\""

  [ "$status" -eq 0 ]
  [ "$output" = "$(printf '%s\n' "$TEST_HOME_DIR/.local/share/mise/shims/ruby" 0)" ]
}

@test "zsh completions.zsh template renders and has valid syntax" {
  if ! command -v zsh >/dev/null 2>&1; then
    skip "zsh not installed"
  fi

  local file="home/dot_config/zsh/completions.zsh.tmpl"

  # Render template
  run render_template "$file"
  [ "$status" -eq 0 ]

  # Check syntax
  echo "$output" > "$TEST_TMPDIR/completions.zsh"
  run zsh -n "$TEST_TMPDIR/completions.zsh"
  [ "$status" -eq 0 ]
}

@test "zsh aliases.zsh template renders and has valid syntax" {
  if ! command -v zsh >/dev/null 2>&1; then
    skip "zsh not installed"
  fi

  local file="home/dot_config/zsh/aliases.zsh.tmpl"

  # Render template
  run render_template "$file"
  [ "$status" -eq 0 ]

  # Check syntax
  echo "$output" > "$TEST_TMPDIR/aliases.zsh"
  run zsh -n "$TEST_TMPDIR/aliases.zsh"
  [ "$status" -eq 0 ]
}

@test "zsh tools.zsh template renders and has valid syntax" {
  if ! command -v zsh >/dev/null 2>&1; then
    skip "zsh not installed"
  fi

  local file="home/dot_config/zsh/tools.zsh.tmpl"

  # Render template
  run render_template "$file"
  [ "$status" -eq 0 ]

  # Check syntax
  echo "$output" > "$TEST_TMPDIR/tools.zsh"
  run zsh -n "$TEST_TMPDIR/tools.zsh"
  [ "$status" -eq 0 ]
}

@test "osc8-hyperlinks.sh has valid bash syntax" {
  local file="home/dot_config/shell/osc8-hyperlinks.sh"

  run bash -n "$file"
  [ "$status" -eq 0 ]
}

# ==============================================================================
# Editor Configuration Tests
# ==============================================================================

@test "neovim lua config files have valid syntax" {
  if ! command -v nvim >/dev/null 2>&1; then
    skip "neovim not installed"
  fi

  # loadfile compiles without running plugin bootstrapping or config code.
  local found=0
  while IFS= read -r -d '' lua_file; do
    found=1
    run env NVIM_SYNTAX_FILE="$lua_file" nvim --headless --noplugin -u NONE -i NONE \
      -c 'lua local fn, err = loadfile(vim.env.NVIM_SYNTAX_FILE); if not fn then vim.api.nvim_err_writeln(err); vim.cmd("cquit") end' \
      -c 'qall!'
    [ "$status" -eq 0 ]
  done < <(find home/dot_config/nvim -name '*.lua' -print0)

  [ "$found" -eq 1 ]
}

@test "vimrc has valid vim syntax" {
  if ! command -v vim >/dev/null 2>&1; then
    skip "vim not installed"
  fi

  local file="home/dot_vimrc"

  # Source vimrc and quit - will catch syntax errors
  run vim -u "$file" -c 'quit' -e -s
  [ "$status" -eq 0 ]
}

# ==============================================================================
# Terminal/Multiplexer Configuration Tests
# ==============================================================================

@test "kitty config can be validated" {
  if ! command -v kitty >/dev/null 2>&1; then
    skip "kitty not installed"
  fi

  local file="home/dot_config/kitty/kitty.conf"

  # kitty 0.46 has no --debug-config flag; load_config parses the file and
  # reports errors without opening a window
  run kitty +runpy "from kitty.config import load_config; load_config('$file')"
  [ "$status" -eq 0 ]
}

# ==============================================================================
# Git Configuration Tests
# ==============================================================================

@test "git config can be parsed" {
  if ! command -v git >/dev/null 2>&1; then
    skip "git not installed"
  fi

  local file="home/dot_config/git/config.tmpl"

  # Render template
  run render_template "$file"
  [ "$status" -eq 0 ]

  # Validate git config file syntax
  echo "$output" > "$TEST_TMPDIR/gitconfig"
  run git config --file "$TEST_TMPDIR/gitconfig" --list
  [ "$status" -eq 0 ]
}

@test "git delta config can be parsed" {
  if ! command -v git >/dev/null 2>&1; then
    skip "git not installed"
  fi

  local file="home/dot_config/git/delta.gitconfig"

  run git config --file "$file" --list
  [ "$status" -eq 0 ]
}

# ==============================================================================
# Tool Configuration Tests (TOML/YAML)
# ==============================================================================

@test "mise config.toml has valid TOML syntax" {
  if ! command -v mise >/dev/null 2>&1; then
    skip "mise not installed"
  fi

  local file="home/dot_config/mise/config.toml"

  # Render template
  run render_template "$file"
  [ "$status" -eq 0 ]

  # `mise settings` takes no --file; `mise config get` reads a specific file
  echo "$output" > "$TEST_TMPDIR/mise-config.toml"
  run mise config get --file "$TEST_TMPDIR/mise-config.toml"
  [ "$status" -eq 0 ]
}

@test "atuin config.toml has valid TOML syntax" {
  # Use any TOML parser if available
  if command -v tomlq >/dev/null 2>&1; then
    local file="home/dot_config/atuin/config.toml"
    run tomlq '.' "$file"
    [ "$status" -eq 0 ]
  elif command -v python3 >/dev/null 2>&1; then
    local file="home/dot_config/atuin/config.toml"
    run python3 -c "import tomllib; tomllib.load(open('$file', 'rb'))"
    [ "$status" -eq 0 ]
  else
    skip "no TOML parser available"
  fi
}

@test "jj config.toml has valid TOML syntax" {
  local file="home/dot_config/jj/config.toml.tmpl"

  # Render template
  run render_template "$file"
  [ "$status" -eq 0 ]

  local rendered="$TEST_TMPDIR/jj-config.toml"
  echo "$output" > "$rendered"

  # Note: tomlq may have issues with certain multiline strings containing [[
  # Use python3's tomllib as the canonical TOML parser
  if command -v python3 >/dev/null 2>&1; then
    run python3 -c "import tomllib; tomllib.load(open('$rendered', 'rb'))"
    [ "$status" -eq 0 ]
  elif command -v tomlq >/dev/null 2>&1; then
    run tomlq '.' "$rendered"
    [ "$status" -eq 0 ]
  else
    skip "no TOML parser available"
  fi
}

@test "starship.toml has valid TOML syntax" {
  if ! command -v starship >/dev/null 2>&1; then
    skip "starship not installed"
  fi

  local file="home/dot_config/starship.toml"

  # `starship config` opens the file in $EDITOR and blocks forever without a
  # TTY; print-config parses and dumps it instead
  STARSHIP_CONFIG="$file" run starship print-config
  [ "$status" -eq 0 ]
}

@test "gitleaks.toml has valid TOML syntax" {
  if command -v tomlq >/dev/null 2>&1; then
    local file="home/dot_gitleaks.toml"
    run tomlq '.' "$file"
    [ "$status" -eq 0 ]
  elif command -v python3 >/dev/null 2>&1; then
    local file="home/dot_gitleaks.toml"
    run python3 -c "import tomllib; tomllib.load(open('$file', 'rb'))"
    [ "$status" -eq 0 ]
  else
    skip "no TOML parser available"
  fi
}

@test "glow.yml has valid YAML syntax" {
  if command -v yq >/dev/null 2>&1; then
    local file="home/dot_config/glow/glow.yml"
    run yq '.' "$file"
    [ "$status" -eq 0 ]
  elif command -v python3 >/dev/null 2>&1; then
    local file="home/dot_config/glow/glow.yml"
    run python3 -c "import yaml; yaml.safe_load(open('$file'))"
    [ "$status" -eq 0 ]
  else
    skip "no YAML parser available"
  fi
}

@test "docker-compose configs have valid YAML syntax" {
  if command -v yq >/dev/null 2>&1; then
    local file="home/dot_config/docker-compose/open-webui.yml"
    run yq '.' "$file"
    [ "$status" -eq 0 ]
  elif command -v python3 >/dev/null 2>&1; then
    local file="home/dot_config/docker-compose/open-webui.yml"
    run python3 -c "import yaml; yaml.safe_load(open('$file'))"
    [ "$status" -eq 0 ]
  else
    skip "no YAML parser available"
  fi
}

@test "rubocop config has valid YAML syntax" {
  if command -v yq >/dev/null 2>&1; then
    local file="home/dot_config/rubocop/config.yml"
    run yq '.' "$file"
    [ "$status" -eq 0 ]
  elif command -v python3 >/dev/null 2>&1; then
    local file="home/dot_config/rubocop/config.yml"
    run python3 -c "import yaml; yaml.safe_load(open('$file'))"
    [ "$status" -eq 0 ]
  else
    skip "no YAML parser available"
  fi
}

@test "claude settings.json has valid JSON syntax" {
  local file="home/dot_claude/settings.json.tmpl"

  run render_template "$file"
  [ "$status" -eq 0 ]

  local rendered="$TEST_TMPDIR/claude-settings.json"
  echo "$output" > "$rendered"

  if command -v jq >/dev/null 2>&1; then
    run jq empty "$rendered"
    [ "$status" -eq 0 ]
  elif command -v python3 >/dev/null 2>&1; then
    run python3 -c "import json; json.load(open('$rendered'))"
    [ "$status" -eq 0 ]
  else
    skip "no JSON parser available"
  fi
}

@test "claude settings.json has valid JSON syntax on non-work hosts" {
  # hosttype gates three blocks, and those blocks carry the commas, so a
  # personal host can render invalid JSON while a work host renders fine.
  local file="home/dot_claude/settings.json.tmpl"
  local rendered="$TEST_TMPDIR/claude-settings-personal.json"

  render_template "$file" home >"$rendered"

  if command -v jq >/dev/null 2>&1; then
    run jq empty "$rendered"
    [ "$status" -eq 0 ]
  elif command -v python3 >/dev/null 2>&1; then
    run python3 -c "import json; json.load(open('$rendered'))"
    [ "$status" -eq 0 ]
  else
    skip "no JSON parser available"
  fi

  # The else branches must actually have been taken.
  run grep -c 'GUSTO_CLAUDE_SETUP\|effortLevel' "$rendered"
  [ "$output" -eq 0 ]
}
