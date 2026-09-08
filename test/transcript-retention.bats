#!/usr/bin/env bats

load test_helper

@test "Claude retains local transcripts for 100 years" {
  run chezmoi execute-template --file home/dot_claude/settings.json.tmpl
  [ "$status" -eq 0 ]

  local settings="$output"
  run jq -e '.cleanupPeriodDays == 36500' <<<"$settings"
  [ "$status" -eq 0 ]
}

@test "Codex history modifier enables uncapped persistence" {
  local modifier="home/dot_codex/modify_private_config.toml"
  local original="$TEST_TMPDIR/config.toml"
  local modified="$TEST_TMPDIR/modified.toml"
  local reapplied="$TEST_TMPDIR/reapplied.toml"

  cat >"$original" <<'EOF'
model = "gpt-5.6-sol"

[history]
persistence = "none"
max_bytes = 104857600

[tui]
notifications = true
EOF

  sh "$modifier" <"$original" >"$modified"

  run python3 -c '
import pathlib
import sys
import tomllib

config = tomllib.loads(pathlib.Path(sys.argv[1]).read_text())
assert config["model"] == "gpt-5.6-sol"
assert config["history"] == {"persistence": "save-all"}
assert config["tui"]["notifications"] is True
' "$modified"
  [ "$status" -eq 0 ]

  sh "$modifier" <"$modified" >"$reapplied"
  run cmp "$modified" "$reapplied"
  [ "$status" -eq 0 ]
}

@test "Codex history modifier initializes an empty config" {
  local modifier="home/dot_codex/modify_private_config.toml"
  local modified="$TEST_TMPDIR/config.toml"

  sh "$modifier" </dev/null >"$modified"

  run python3 -c '
import pathlib
import sys
import tomllib

config = tomllib.loads(pathlib.Path(sys.argv[1]).read_text())
assert config == {"history": {"persistence": "save-all"}}
' "$modified"
  [ "$status" -eq 0 ]
}
