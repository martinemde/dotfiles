#!/usr/bin/env bats

# Frontmatter Validation Tests
#
# Exercises bin/check-frontmatter against synthetic fixtures so each rule is
# proven to fire, then runs it against the repository's real skills and agents.
#
# The checker is also runnable on its own (`bin/check-frontmatter`) and is
# invoked directly by bin/test, so these checks still run when bats is missing.

load test_helper

CHECKER=""

setup() {
  # test_helper's setup creates TEST_TMPDIR and exports the chezmoi test vars.
  TEST_TMPDIR=$(mktemp -d)
  export TEST_TMPDIR

  CHECKER="$BATS_TEST_DIRNAME/../bin/check-frontmatter"
  REPO_ROOT="$BATS_TEST_DIRNAME/.."
  FIXTURE="$TEST_TMPDIR/claude"
  mkdir -p "$FIXTURE/skills" "$FIXTURE/agents"
}

teardown() {
  rm -rf "$TEST_TMPDIR"
}

# Write a SKILL.md for skill <name> with the given frontmatter body on stdin.
make_skill() {
  local name="$1"
  mkdir -p "$FIXTURE/skills/$name"
  {
    echo '---'
    cat
    echo '---'
    echo
    echo "# $name"
  } >"$FIXTURE/skills/$name/SKILL.md"
}

# Write an agent file for agent <name> with the given frontmatter body on stdin.
make_agent() {
  local name="$1"
  mkdir -p "$FIXTURE/agents/$name"
  {
    echo '---'
    cat
    echo '---'
    echo
    echo "# $name"
  } >"$FIXTURE/agents/$name/$name.md"
}

# ==============================================================================
# The checker itself
# ==============================================================================

@test "check-frontmatter is executable and has valid bash syntax" {
  [ -x "$CHECKER" ]

  run bash -n "$CHECKER"
  [ "$status" -eq 0 ]
}

@test "check-frontmatter prints usage for --help" {
  run "$CHECKER" --help
  [ "$status" -eq 0 ]
  [[ "$output" == *"check-frontmatter"* ]]
}

@test "check-frontmatter rejects unknown options" {
  run "$CHECKER" --nope
  [ "$status" -eq 2 ]
}

# ==============================================================================
# Valid frontmatter
# ==============================================================================

@test "accepts a well-formed skill" {
  make_skill good-skill <<'EOF'
name: good-skill
description: Use when demonstrating that a well-formed skill passes validation.
argument-hint: "[thing]"
allowed-tools:
  - Read
  - Grep
EOF

  run "$CHECKER" "$FIXTURE"
  [ "$status" -eq 0 ]
}

@test "accepts a well-formed agent" {
  make_agent good-agent <<'EOF'
name: good-agent
description: Use when demonstrating that a well-formed agent passes validation.
tools: Read, Grep, Glob
model: sonnet
color: cyan
EOF

  run "$CHECKER" "$FIXTURE"
  [ "$status" -eq 0 ]
}

@test "accepts a folded block scalar description" {
  make_skill folded <<'EOF'
name: folded
description: >-
  Use when the description is written as a folded block scalar
  spanning several physical lines.
EOF

  run "$CHECKER" "$FIXTURE"
  [ "$status" -eq 0 ]
}

@test "accepts frontmatter with CRLF line endings" {
  mkdir -p "$FIXTURE/skills/crlf"
  printf -- '---\r\nname: crlf\r\ndescription: Use when the file was saved with Windows line endings.\r\n---\r\n\r\n# crlf\r\n' \
    >"$FIXTURE/skills/crlf/SKILL.md"

  run "$CHECKER" "$FIXTURE"
  [ "$status" -eq 0 ]
}

@test "quiet mode prints nothing when everything passes" {
  make_skill quiet <<'EOF'
name: quiet
description: Use when checking that quiet mode suppresses success output.
EOF

  run "$CHECKER" --quiet "$FIXTURE"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

# ==============================================================================
# Structural failures
# ==============================================================================

@test "rejects a skill with no frontmatter" {
  mkdir -p "$FIXTURE/skills/bare"
  echo '# bare' >"$FIXTURE/skills/bare/SKILL.md"

  run "$CHECKER" "$FIXTURE"
  [ "$status" -eq 1 ]
  [[ "$output" == *"no YAML frontmatter"* ]]
}

@test "rejects unterminated frontmatter" {
  mkdir -p "$FIXTURE/skills/unterminated"
  printf -- '---\nname: unterminated\ndescription: Use when the closing delimiter is missing.\n' \
    >"$FIXTURE/skills/unterminated/SKILL.md"

  run "$CHECKER" "$FIXTURE"
  [ "$status" -eq 1 ]
  [[ "$output" == *"unterminated frontmatter"* ]]
}

@test "rejects an empty frontmatter block" {
  mkdir -p "$FIXTURE/skills/empty"
  printf -- '---\n---\n\n# empty\n' >"$FIXTURE/skills/empty/SKILL.md"

  run "$CHECKER" "$FIXTURE"
  [ "$status" -eq 1 ]
  [[ "$output" == *"empty frontmatter block"* ]]
}

@test "rejects a skill directory with no SKILL.md" {
  mkdir -p "$FIXTURE/skills/no-skill-file"

  run "$CHECKER" "$FIXTURE"
  [ "$status" -eq 1 ]
  [[ "$output" == *"no SKILL.md"* ]]
}

# ==============================================================================
# Chezmoi templates
# ==============================================================================

@test "accepts a skill defined as SKILL.md.tmpl" {
  mkdir -p "$FIXTURE/skills/templated"
  printf -- '---\nname: templated\ndescription: Use when the skill source is a chezmoi template.\n---\n\n# templated\n' \
    >"$FIXTURE/skills/templated/SKILL.md.tmpl"

  run "$CHECKER" "$FIXTURE"
  [ "$status" -eq 0 ]
  [[ "$output" == *"SKILL.md.tmpl"* ]]
}

@test "still applies key rules to a template" {
  mkdir -p "$FIXTURE/skills/bad-template"
  printf -- '---\ndescription: Use when a templated skill is missing its name key.\n---\n' \
    >"$FIXTURE/skills/bad-template/SKILL.md.tmpl"

  run "$CHECKER" "$FIXTURE"
  [ "$status" -eq 1 ]
  [[ "$output" == *"missing required key: name"* ]]
}

@test "does not report bogus YAML errors for unrendered template actions" {
  if command -v chezmoi >/dev/null 2>&1; then
    skip "chezmoi renders the template, so nothing is left unrendered"
  fi

  mkdir -p "$FIXTURE/skills/go-template"
  printf -- '---\nname: go-template\ndescription: Use when frontmatter contains a Go template action.\nmodel: {{ .model }}\n---\n' \
    >"$FIXTURE/skills/go-template/SKILL.md.tmpl"

  run "$CHECKER" "$FIXTURE"
  [ "$status" -eq 0 ]
  [[ "$output" != *"invalid YAML"* ]]
}

@test "rejects tab-indented frontmatter" {
  mkdir -p "$FIXTURE/skills/tabbed"
  printf -- '---\nname: tabbed\ndescription: Use when frontmatter is indented with tabs.\nmetadata:\n\tauthor: someone\n---\n' \
    >"$FIXTURE/skills/tabbed/SKILL.md"

  run "$CHECKER" "$FIXTURE"
  [ "$status" -eq 1 ]
  [[ "$output" == *"tabs"* ]]
}

# ==============================================================================
# YAML validity
# ==============================================================================

@test "rejects frontmatter that is not valid YAML" {
  # `@` is a reserved YAML indicator and cannot start a plain scalar.
  make_skill reserved-char <<'EOF'
name: reserved-char
description: Use when a value starts with a reserved YAML indicator.
metadata:
  author: @someone
EOF

  run "$CHECKER" "$FIXTURE"
  [ "$status" -eq 1 ]
  [[ "$output" == *"invalid YAML"* ]]
}

@test "rejects an unquoted description containing a colon" {
  make_skill colon <<'EOF'
name: colon
description: Use when a plain scalar contains a mapping indicator: like this one.
EOF

  run "$CHECKER" "$FIXTURE"
  [ "$status" -eq 1 ]
  [[ "$output" == *"invalid YAML"* ]]
}

@test "reports the source file line number for a YAML error" {
  make_skill line-number <<'EOF'
name: line-number
description: Use when checking that YAML errors point at the right file line.
metadata:
  author: @someone
EOF

  run "$CHECKER" "$FIXTURE"
  [ "$status" -eq 1 ]
  # `author:` is the fifth line of the file (--- is line 1).
  [[ "$output" == *"line 5"* ]]
}

# ==============================================================================
# Key rules
# ==============================================================================

@test "rejects a skill missing name" {
  make_skill nameless <<'EOF'
description: Use when the name key has been left out entirely.
EOF

  run "$CHECKER" "$FIXTURE"
  [ "$status" -eq 1 ]
  [[ "$output" == *"missing required key: name"* ]]
}

@test "rejects a skill missing description" {
  make_skill undescribed <<'EOF'
name: undescribed
EOF

  run "$CHECKER" "$FIXTURE"
  [ "$status" -eq 1 ]
  [[ "$output" == *"missing required key: description"* ]]
}

@test "rejects an empty description" {
  make_skill blank <<'EOF'
name: blank
description:
EOF

  run "$CHECKER" "$FIXTURE"
  [ "$status" -eq 1 ]
  [[ "$output" == *"description"* ]]
}

@test "rejects a misspelled key" {
  # The real typo this catches: arguments-hint instead of argument-hint.
  make_skill typo <<'EOF'
name: typo
description: Use when a key name is subtly misspelled.
arguments-hint: "[revision]"
EOF

  run "$CHECKER" "$FIXTURE"
  [ "$status" -eq 1 ]
  [[ "$output" == *"unknown skill key: arguments-hint"* ]]
}

@test "rejects an agent key used on a skill" {
  make_skill wrong-kind <<'EOF'
name: wrong-kind
description: Use when an agent-only key appears in a skill file.
color: cyan
EOF

  run "$CHECKER" "$FIXTURE"
  [ "$status" -eq 1 ]
  [[ "$output" == *"unknown skill key: color"* ]]
}

@test "rejects a skill key used on an agent" {
  make_agent wrong-kind-agent <<'EOF'
name: wrong-kind-agent
description: Use when a skill-only key appears in an agent file.
argument-hint: "[thing]"
EOF

  run "$CHECKER" "$FIXTURE"
  [ "$status" -eq 1 ]
  [[ "$output" == *"unknown agent key: argument-hint"* ]]
}

@test "rejects duplicate keys" {
  make_skill duplicated <<'EOF'
name: duplicated
description: Use when the same key appears twice in one block.
description: Use when the second copy silently wins.
EOF

  run "$CHECKER" "$FIXTURE"
  [ "$status" -eq 1 ]
  [[ "$output" == *"duplicate key: description"* ]]
}

# ==============================================================================
# Value rules
# ==============================================================================

@test "rejects a skill name that does not match its directory" {
  # Claude Code invokes a skill by its directory, so a disagreeing name key is
  # inert and misleading.
  make_skill actual-dir <<'EOF'
name: some-other-name
description: Use when the name key drifted away from the directory name.
EOF

  run "$CHECKER" "$FIXTURE"
  [ "$status" -eq 1 ]
  [[ "$output" == *"does not match skill directory"* ]]
}

@test "rejects a skill name that is not kebab-case" {
  mkdir -p "$FIXTURE/skills/Shouty_Name"
  printf -- '---\nname: Shouty_Name\ndescription: Use when the name is not lowercase kebab-case.\n---\n' \
    >"$FIXTURE/skills/Shouty_Name/SKILL.md"

  run "$CHECKER" "$FIXTURE"
  [ "$status" -eq 1 ]
  [[ "$output" == *"kebab-case"* ]]
}

@test "allows an agent name that differs from its filename" {
  # An agent is invoked by its name value, not its filename, so a display name
  # is legitimate. Enforcing a match here would flag working config.
  make_agent actual-agent <<'EOF'
name: Package Manager
description: Use when an agent carries a human-readable display name.
EOF

  run "$CHECKER" "$FIXTURE"
  [ "$status" -eq 0 ]
}

@test "rejects an over-long skill description" {
  local long
  long=$(printf 'word %.0s' $(seq 1 300))

  make_skill verbose <<EOF
name: verbose
description: $long
EOF

  run "$CHECKER" "$FIXTURE"
  [ "$status" -eq 1 ]
  [[ "$output" == *"skill limit is 1024"* ]]
}

@test "allows an agent description longer than the skill limit" {
  # Subagent descriptions carry <example> blocks and run well past 1024 chars.
  local long
  long=$(printf 'word %.0s' $(seq 1 300))

  make_agent wordy <<EOF
name: wordy
description: $long
EOF

  run "$CHECKER" "$FIXTURE"
  [ "$status" -eq 0 ]
}

@test "rejects an over-long agent description" {
  local long
  long=$(printf 'word %.0s' $(seq 1 1000))

  make_agent very-wordy <<EOF
name: very-wordy
description: $long
EOF

  run "$CHECKER" "$FIXTURE"
  [ "$status" -eq 1 ]
  [[ "$output" == *"agent limit is 4096"* ]]
}

@test "rejects a description too short to route on" {
  make_skill terse <<'EOF'
name: terse
description: Does stuff.
EOF

  run "$CHECKER" "$FIXTURE"
  [ "$status" -eq 1 ]
  [[ "$output" == *"too short"* ]]
}

# ==============================================================================
# Reporting
# ==============================================================================

@test "reports every failing file, not just the first" {
  make_skill first-bad <<'EOF'
description: Use when the first of two skills is missing its name key.
EOF
  make_skill second-bad <<'EOF'
description: Use when the second of two skills is missing its name key.
EOF

  run "$CHECKER" "$FIXTURE"
  [ "$status" -eq 1 ]
  [[ "$output" == *"first-bad"* ]]
  [[ "$output" == *"second-bad"* ]]
  [[ "$output" == *"2 of 2 file(s)"* ]]
}

@test "accepts a single file path" {
  make_skill single <<'EOF'
name: single
description: Use when the checker is pointed at one file instead of a tree.
EOF

  run "$CHECKER" "$FIXTURE/skills/single/SKILL.md"
  [ "$status" -eq 0 ]
}

@test "fails on a path that does not exist" {
  run "$CHECKER" "$TEST_TMPDIR/definitely-not-here"
  [ "$status" -eq 1 ]
  [[ "$output" == *"no such path"* ]]
}

# ==============================================================================
# The real repository
# ==============================================================================

@test "chezmoi-managed skills and agents have valid frontmatter" {
  run "$CHECKER" "$REPO_ROOT/home/dot_claude"
  [ "$status" -eq 0 ]
}

@test "project-local skills and agents have valid frontmatter" {
  run "$CHECKER" "$REPO_ROOT/.claude"
  [ "$status" -eq 0 ]
}

@test "checks both Claude config roots by default" {
  cd "$REPO_ROOT"
  run "$CHECKER"
  [ "$status" -eq 0 ]
  [[ "$output" == *"home/dot_claude/"* ]]
  [[ "$output" == *".claude/"* ]]
}
