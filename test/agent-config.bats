#!/usr/bin/env bats

load test_helper

@test "Claude account skill sync is disabled on personal and work hosts" {
  local hosttype
  for hosttype in personal work; do
    run chezmoi --config /dev/null --config-format toml \
      --source "$TEST_SOURCE_DIR" \
      --override-data "{\"hosttype\":\"$hosttype\"}" \
      execute-template --file home/dot_claude/settings.json.tmpl
    [ "$status" -eq 0 ]

    local settings="$output"
    run jq -e '.syncClaudeAiSkills == false' <<<"$settings"
    [ "$status" -eq 0 ]
  done
}

@test "chezmoi removes synced skills while preserving personal skills" {
  cp home/.chezmoiremove "$TEST_SOURCE_DIR/.chezmoiremove"
  local skills="$TEST_HOME_DIR/.agents/skills"
  mkdir -p "$skills/synced/account/pdf" "$skills/taste"
  printf 'downloaded skill\n' >"$skills/synced/account/pdf/SKILL.md"
  printf 'personal skill\n' >"$skills/taste/SKILL.md"

  run chezmoi --config /dev/null --config-format toml \
    --source "$TEST_SOURCE_DIR" --destination "$TEST_HOME_DIR" \
    --persistent-state "$TEST_TMPDIR/chezmoi-state.boltdb" \
    apply --dry-run "$skills/synced"
  [ "$status" -eq 0 ]
  [ -f "$skills/synced/account/pdf/SKILL.md" ]

  run chezmoi --config /dev/null --config-format toml \
    --source "$TEST_SOURCE_DIR" --destination "$TEST_HOME_DIR" \
    --persistent-state "$TEST_TMPDIR/chezmoi-state.boltdb" \
    apply "$skills/synced"
  [ "$status" -eq 0 ]
  [ ! -e "$skills/synced" ]
  [ "$(cat "$skills/taste/SKILL.md")" = "personal skill" ]

  run chezmoi --config /dev/null --config-format toml \
    --source "$TEST_SOURCE_DIR" --destination "$TEST_HOME_DIR" \
    --persistent-state "$TEST_TMPDIR/chezmoi-state.boltdb" apply
  [ "$status" -eq 0 ]
  [ ! -e "$skills/synced" ]
  [ -f "$skills/taste/SKILL.md" ]
}

@test "shared skills have portable frontmatter and matching directory names" {
  while IFS= read -r skill; do
    local keys name directory
    keys=$(yq --front-matter=extract -r 'keys | sort | join(",")' "$skill")
    name=$(yq --front-matter=extract -r '.name' "$skill")
    directory=$(basename "$(dirname "$skill")")

    [ "$keys" = "description,name" ]
    [ "$name" = "$directory" ]
  done < <(
    find .agents/skills home/dot_agents/skills \
      \( -name SKILL.md -o -name SKILL.md.tmpl \) -print | sort
  )
}

@test "shared skills avoid harness-specific command metadata" {
  run rg -n \
    '^(argument-hint|allowed-tools|context|agent|model|color|metadata):|!`|Task(Create|Update|List)|subagent_type|EnterPlanMode|ExitPlanMode' \
    .agents/skills home/dot_agents/skills \
    --glob SKILL.md \
    --glob SKILL.md.tmpl

  [ "$status" -eq 1 ]
}

@test "skill directories contain no auxiliary README files" {
  run find .agents/skills home/dot_agents/skills -name README.md -print
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "canonical agent names match their filenames" {
  while IFS= read -r agent; do
    local name filename
    name=$(yq --front-matter=extract -r '.name' "$agent")
    filename=$(basename "$agent" .md)

    [ "$name" = "$filename" ]
    [ "$(yq --front-matter=extract -r '.description | length > 0' "$agent")" = "true" ]
  done < <(find .agents/agents home/dot_agents/agents -name '*.md' -print | sort)
}

@test "Claude and Codex adapters reference canonical agent bodies" {
  local name
  for name in prompt-engineer shell-wizard leeroy-jenkins plan-reviewer; do
    rg -F "~/.agents/agents/$name.md" "home/dot_claude/agents/$name/$name.md"
    rg -F ".agents/agents/$name.md" "home/dot_codex/agents/$name.toml"
  done

  rg -F '.agents/agents/package-manager.md' .claude/agents/package-manager.md
  rg -F '.agents/agents/package-manager.md' .codex/agents/package-manager.toml
}

@test "Codex agent adapters are valid TOML" {
  while IFS= read -r agent; do
    python3 -c 'import pathlib, sys, tomllib; data = tomllib.loads(pathlib.Path(sys.argv[1]).read_text()); assert data["name"] and data["description"] and data["developer_instructions"]' "$agent"
  done < <(find .codex/agents home/dot_codex/agents -name '*.toml' -print | sort)
}

@test "instruction and skill compatibility links point at canonical files" {
  [ "$(readlink CLAUDE.md)" = "AGENTS.md" ]
  [ "$(readlink .claude/skills)" = "../.agents/skills" ]
  [ "$(tr -d '\n' <home/dot_claude/symlink_CLAUDE.md)" = "../.agents/AGENTS.md" ]
  [ "$(tr -d '\n' <home/dot_claude/symlink_skills)" = "../.agents/skills" ]
  [ ! -e home/dot_claude/skills ]
  [ "$(tr -d '\n' <home/dot_codex/symlink_AGENTS.md)" = "../.agents/AGENTS.md" ]
  [ "$(tr -d '\n' <home/dot_codex/skills/symlink_taste)" = "../../.agents/skills/taste" ]
  [ "$(tr -d '\n' <home/dot_pi/private_agent/symlink_AGENTS.md)" = "../../.agents/AGENTS.md" ]
}

@test "Pi settings use exact extension pins managed by Renovate" {
  jq -e '
    .packages == [
      "npm:pi-subagents@0.44.0",
      "npm:pi-web-access@0.19.0"
    ] and
    has("lastChangelogVersion") == false
  ' home/dot_pi/private_agent/settings.json

  rg -F "'custom.regex'" renovate.json5
  rg -F 'home\\/dot_pi\\/private_agent\\/settings\\.json' renovate.json5
  rg -F "groupName: 'pi-extensions'" renovate.json5
}
