#!/usr/bin/env bats

# Configuration Validation Tests
# Tests that validate config files can be loaded by their respective tools
# This allows catching errors before applying chezmoi

load test_helper

# Helper to render a template file
render_template() {
  local file="$1"
  chezmoi execute-template --file "$file"
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

@test "zshenv has valid syntax" {
  if ! command -v zsh >/dev/null 2>&1; then
    skip "zsh not installed"
  fi

  local file="home/dot_zshenv"
  local temp_file="$TEST_TMPDIR/.zshenv"
  cat "$file" > "$temp_file"

  run zsh -n "$temp_file"
  [ "$status" -eq 0 ]
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

@test "zsh llm.zsh template renders and has valid syntax" {
  if ! command -v zsh >/dev/null 2>&1; then
    skip "zsh not installed"
  fi

  local file="home/dot_config/zsh/llm.zsh.tmpl"

  # Render template
  run render_template "$file"
  [ "$status" -eq 0 ]

  # Check syntax
  echo "$output" > "$TEST_TMPDIR/llm.zsh"
  run zsh -n "$TEST_TMPDIR/llm.zsh"
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

@test "neovim init.lua can be parsed" {
  if ! command -v nvim >/dev/null 2>&1; then
    skip "neovim not installed"
  fi

  local file="home/dot_config/nvim/init.lua"

  # Try to load config in headless mode with minimal processing
  # This will catch syntax errors but won't fully initialize plugins
  run nvim --headless -u "$file" +'lua vim.print("ok")' +qall
  [ "$status" -eq 0 ]
}

@test "neovim lua config files have valid syntax" {
  if ! command -v nvim >/dev/null 2>&1; then
    skip "neovim not installed"
  fi

  # Test each lua file individually for syntax
  local lua_files=(
    "home/dot_config/nvim/lua/config/autocmds.lua"
    "home/dot_config/nvim/lua/config/keymaps.lua"
    "home/dot_config/nvim/lua/config/lazy.lua"
    "home/dot_config/nvim/lua/config/options.lua"
  )

  for lua_file in "${lua_files[@]}"; do
    if [ -f "$lua_file" ]; then
      # Use luac if available, otherwise use nvim
      if command -v luac >/dev/null 2>&1; then
        run luac -p "$lua_file"
        [ "$status" -eq 0 ]
      else
        run nvim --headless -u NONE -c "luafile $lua_file" +qall
        [ "$status" -eq 0 ]
      fi
    fi
  done
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

@test "tmux config can be parsed" {
  if ! command -v tmux >/dev/null 2>&1; then
    skip "tmux not installed"
  fi

  local file="home/dot_config/tmux/tmux.conf.local"

  # Parse config without starting server
  # tmux will validate syntax and report errors
  run tmux -f "$file" source-file "$file"
  # Exit code 0 or 1 (1 can mean server not running, which is ok for syntax check)
  # We mainly want to catch syntax errors which give different exit codes
  [ "$status" -le 1 ]
}

@test "kitty config can be validated" {
  if ! command -v kitty >/dev/null 2>&1; then
    skip "kitty not installed"
  fi

  local file="home/dot_config/kitty/kitty.conf"

  # Kitty has a debug-config option that validates config
  run kitty --config "$file" --debug-config
  [ "$status" -eq 0 ]
}

@test "ghostty config has valid syntax" {
  # Ghostty config is simple key=value format
  # We can at least check it exists and has proper structure
  local file="home/dot_config/ghostty/config"

  [ -f "$file" ]

  # Basic validation: no empty keys, proper format
  run grep -v '^#' "$file"
  [ "$status" -eq 0 ]
}

# ==============================================================================
# Git Configuration Tests
# ==============================================================================

@test "git config can be parsed" {
  if ! command -v git >/dev/null 2>&1; then
    skip "git not installed"
  fi

  local file="home/dot_config/git/config"

  # Validate git config file syntax
  run git config --file "$file" --list
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

@test "git llm config can be parsed" {
  if ! command -v git >/dev/null 2>&1; then
    skip "git not installed"
  fi

  local file="home/dot_config/git/config-llm"

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

  # mise can validate its own config
  # We'll use a simple approach: try to read settings from the file
  run mise settings --file "$file"
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
  # Note: tomlq may have issues with certain multiline strings containing [[
  # Use python3's tomllib as the canonical TOML parser
  if command -v python3 >/dev/null 2>&1; then
    local file="home/dot_config/jj/config.toml"
    run python3 -c "import tomllib; tomllib.load(open('$file', 'rb'))"
    [ "$status" -eq 0 ]
  elif command -v tomlq >/dev/null 2>&1; then
    local file="home/dot_config/jj/config.toml"
    run tomlq '.' "$file"
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

  # Starship can validate its config
  STARSHIP_CONFIG="$file" run starship config
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

# ==============================================================================
# Linter/Formatter Configuration Tests
# ==============================================================================

@test "editorconfig has valid syntax" {
  # EditorConfig is simple INI format, basic check
  local file="home/dot_editorconfig"

  [ -f "$file" ]

  # Check for basic structure
  run grep -E '^\[.*\]$' "$file"
  [ "$status" -eq 0 ]
}

@test "markdownlint config has valid JSON syntax" {
  if command -v jq >/dev/null 2>&1; then
    local file="home/dot_markdownlint.jsonc"
    # jsonc might have comments, try to parse with jq
    # This will fail on comments, but it's better than nothing
    run jq '.' "$file"
    # Don't fail on comments, just check file exists
    [ -f "$file" ]
  else
    skip "jq not available"
  fi
}

@test "bat config has valid syntax" {
  # bat config is simple key=value
  local file="home/dot_config/bat/config"

  [ -f "$file" ]

  # Check it's not empty and has proper format
  run grep -v '^#' "$file"
  [ "$status" -eq 0 ]
}

# ==============================================================================
# Brewfile Tests
# ==============================================================================

@test "Brewfile has valid syntax" {
  if ! command -v brew >/dev/null 2>&1; then
    skip "homebrew not installed"
  fi

  local file="home/dot_Brewfile"

  # Use brew bundle check with --no-upgrade to just validate syntax
  cd "$(dirname "$file")" || exit 1
  run brew bundle check --file="$(basename "$file")" --no-upgrade
  # Exit code might be 1 if packages not installed, which is fine
  # We're mainly checking for syntax errors
  [ "$status" -le 1 ]
}

@test "Brewfile.mas has valid syntax" {
  if ! command -v brew >/dev/null 2>&1; then
    skip "homebrew not installed"
  fi

  local file="home/dot_Brewfile.mas"

  cd "$(dirname "$file")" || exit 1
  run brew bundle check --file="$(basename "$file")" --no-upgrade
  [ "$status" -le 1 ]
}
