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
  python3 - <<'PY'
from pathlib import Path
import yaml

for root in (Path(".agents/skills"), Path("home/dot_agents/skills")):
    for skill in sorted(root.rglob("SKILL.md*")):
        if skill.name not in ("SKILL.md", "SKILL.md.tmpl"):
            continue
        frontmatter = yaml.safe_load(skill.read_text().split("---", 2)[1])
        assert set(frontmatter) == {"description", "name"}, skill
        assert frontmatter["name"] == skill.parent.name, skill
PY
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
  python3 - <<'PY'
from pathlib import Path
import yaml

for root in (Path(".agents/agents"), Path("home/dot_agents/agents")):
    for agent in sorted(root.rglob("*.md")):
        frontmatter = yaml.safe_load(agent.read_text().split("---", 2)[1])
        assert frontmatter["name"] == agent.stem, agent
        assert frontmatter["description"], agent
PY
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
  command -v bun >/dev/null 2>&1 || skip "Bun is not installed"
  run env REPO_ROOT="$BATS_TEST_DIRNAME/.." bun --eval '
    import { strict as assert } from "node:assert";
    import { readFileSync } from "node:fs";
    import { join } from "node:path";
    import { runInNewContext } from "node:vm";

    const root = process.env.REPO_ROOT;
    const file = "home/dot_pi/private_agent/settings.json";
    const contents = readFileSync(join(root, file), "utf8");
    const settings = JSON.parse(contents);
    assert.equal(Object.hasOwn(settings, "lastChangelogVersion"), false);
    const packages = settings.packages.map(pkg => {
      const match = pkg.match(/^npm:(.+)@(\d+\.\d+\.\d+)$/);
      assert(match, "Pi extensions must use exact npm version pins: " + pkg);
      return { depName: match[1], currentValue: match[2] };
    });
    assert.deepEqual(packages.map(pkg => pkg.depName).sort(), ["pi-subagents", "pi-web-access"]);

    const config = runInNewContext("(" + readFileSync(join(root, "renovate.json5"), "utf8") + ")");
    const filePatterns = manager => (manager.managerFilePatterns ?? manager.fileMatch ?? [])
      .map(pattern => new RegExp(pattern.startsWith("/") && pattern.endsWith("/")
        ? pattern.slice(1, -1) : pattern));
    assert(config.enabledManagers.includes("custom.regex"));
    const managers = config.customManagers.filter(manager =>
      filePatterns(manager).some(pattern => pattern.test(file)));
    assert.equal(managers.length, 1);
    const manager = managers[0];
    assert.equal(manager.customType, "regex");
    assert.equal(manager.datasourceTemplate, "npm");
    assert.equal(manager.versioningTemplate, "npm");
    const extracted = Array.from(manager.matchStrings).flatMap(pattern =>
      [...contents.matchAll(new RegExp(pattern, "g"))].map(match => ({
        depName: match.groups.depName,
        currentValue: match.groups.currentValue,
      })));
    assert.deepEqual(extracted, packages);
    assert(config.packageRules.some(rule =>
      rule.matchManagers?.includes("custom.regex") &&
      rule.matchDatasources?.includes("npm") &&
      rule.matchFileNames?.includes(file) && rule.groupName === "pi-extensions"));
  '
  printf '%s\n' "$output"
  [ "$status" -eq 0 ]
}
