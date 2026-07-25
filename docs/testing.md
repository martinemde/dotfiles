# Testing Strategy

## Overview

This repository includes comprehensive configuration validation tests that catch errors **before** applying configurations with chezmoi. This provides rapid feedback and prevents broken configurations from being deployed.

## Test Runner

`bin/test` is the entry point. It runs standalone checks first, then the bats
suite if bats is installed.

The split exists because bats is not always available. Containers, minimal CI
images, and one-shot chezmoi bootstraps have a shell and little else, and a
suite that can only run under bats simply does not run there. Checks that need
nothing but a POSIX shell live in `bin/` as their own executables, so they work
in any environment and are also usable directly (in a pre-commit hook, or on a
single file while editing). The bats suite then wraps them to prove each
individual rule fires, which is what bats is actually good at.

`bin/test` reports a missing bats as a skip, not a failure, and still exits
non-zero if any standalone check fails.

## Frontmatter Validation

`bin/check-frontmatter` validates the YAML frontmatter in Claude skill
(`SKILL.md`) and subagent files, across both config roots in this repo:
`home/dot_claude/`, which chezmoi installs to `~/.claude`, and `.claude/`,
which applies to this checkout. `test/frontmatter.bats` exercises it against
synthetic fixtures.

### Why this needs a test

Claude Code fails _silently_ here. A skill whose frontmatter does not parse is
not reported as broken — it just never appears, and the failure shows up as a
model that mysteriously ignores a skill mid-session. There is no error message
to search for and nothing in the file looks wrong.

The failure modes are non-obvious YAML rules and dead keys, not typos a reader
would spot:

- `author: @ivy` is invalid. `@` is a reserved YAML indicator and cannot start
  a plain scalar; the value has to be quoted.
- An unquoted description containing `: ` parses as a nested mapping, not a
  string.
- `arguments-hint` instead of `argument-hint` is accepted by the YAML parser
  and ignored by Claude Code.
- A skill `name` that disagrees with its directory is silently ignored, so the
  file describes one identity while Claude Code uses another.

All four were present in this repository, and none were visible by reading the
files.

### What it checks

Structure (delimiters, non-empty block, tabs), YAML validity, required keys,
unknown keys against a per-kind allowlist, and description length bounds.

Skills and agents are validated as distinct kinds, because Claude Code treats
them differently in three ways:

- **Key sets** differ (`allowed-tools` and `argument-hint` versus `tools` and
  `color`), so each kind gets its own allowlist.
- **Description limits** differ. Skills are capped at 1024 characters; agent
  descriptions carry `<example>` blocks and legitimately run longer, so they
  get a looser bound that only catches a whole document pasted into the key.
- **Identity** differs, which is the subtle one. A skill is invoked by its
  containing directory, so its `name` must agree with that directory and be
  kebab-case. An agent is invoked by the `name` value itself, so the filename
  is only a convention and a display name like `Package Manager` is correct.
  Checking an agent's name against its filename would flag working config, so
  the name rules apply to skills only.

### Degradation

YAML syntax validation needs a parser (python3 + PyYAML, else yq). Without one,
the structural and key checks still run and the script says what it skipped
rather than passing silently.

Chezmoi templates (`SKILL.md.tmpl`) are rendered through `chezmoi
execute-template` when chezmoi is available, so the frontmatter that gets
validated is the one that ends up in `~`. Without chezmoi, frontmatter
containing template actions skips only the YAML parse — reporting a Go template
action as a YAML syntax error would be noise, not a finding.

### Updating the allowlists

`SKILL_KEYS` and `AGENT_KEYS` at the top of the script are the source of truth
for permitted keys. Unknown keys are errors rather than warnings because the
whole point is catching the silent typo; when Claude Code adds a field, add it
there.

## Configuration Validation Tests

The `test/config-validation.bats` suite validates configuration files by loading them with their respective tools using command-line options. This approach catches syntax errors, invalid options, and other configuration issues without requiring full deployment.

### What Gets Tested

1. **Shell Configurations**
   - Zsh configs (`.zshrc`, `.zshenv`, sourced files)
   - Bash scripts (syntax validation)
   - Templates rendered through chezmoi

2. **Editor Configurations**
   - Neovim: Lua configs loaded headless
   - Vim: Config sourced in batch mode

3. **Terminal & Multiplexer**
   - Tmux: Config parsing
   - Kitty: `--debug-config` validation
   - Ghostty: Basic syntax check

4. **Version Control**
   - Git configs: `git config --file --list`
   - Git delta configs
   - Git LLM-specific configs

5. **Tool Configurations**
   - TOML files: mise, atuin, jj, starship, gitleaks
   - YAML files: glow, docker-compose, rubocop
   - Other formats: editorconfig, bat, markdownlint

6. **Package Managers**
   - Brewfile syntax validation

### Running Tests

```bash
# Run all tests
bats test/*.bats

# Run only config validation tests
bats test/config-validation.bats

# Run specific test
bats test/config-validation.bats --filter "git config"

# Verbose output
bats -t test/config-validation.bats
```

### Test Design Principles

**Tool-native validation**: Tests use the actual tools to validate configs (e.g., `git config --file`, `nvim --headless`), ensuring validation matches production behavior.

**Graceful degradation**: Tests skip when tools aren't installed rather than failing. This allows tests to run in various environments (CI, containers, local dev).

**Template rendering**: Chezmoi templates are rendered before validation to catch template syntax errors and variable issues.

**Fast feedback**: Tests run in seconds, providing rapid validation during development.

## Why This Approach

Traditional approaches to testing dotfiles include:

1. **Apply and pray**: Deploy to production and hope nothing breaks
2. **Manual testing**: Check each config by hand after changes
3. **Syntax-only checks**: Run linters but don't validate configs are loadable

This test suite improves on these by:

- **Catching errors early**: Find issues before `chezmoi apply`
- **Real validation**: Actually load configs with their tools
- **Automated**: Run on every change, no manual work
- **Comprehensive**: Covers shells, editors, terminals, and tools

## Integration with Development Workflow

### Pre-apply validation

```bash
# Before applying changes
bats test/config-validation.bats

# If tests pass, apply
chezmoi apply
```

### CI Integration

The repository includes a GitHub Actions workflow (`.github/workflows/ci.yml`) that runs configuration validation tests on every push and pull request. The `config-validation` job:

1. Installs necessary validation tools (vim, tmux, python3, yq, bats)
2. Runs `bats test/config-validation.bats`
3. Reports results in the GitHub Actions UI

This ensures all configuration changes are validated before merge, catching errors early in the development process.

### Pre-commit Hook

Create `.git/hooks/pre-commit`:

```bash
#!/bin/sh
exec bats test/config-validation.bats
```

## Extending Tests

To add validation for new configs:

1. Identify the tool and its validation command
2. Add a test using the pattern:

   ```bash
   @test "config description" {
     if ! command -v tool >/dev/null 2>&1; then
       skip "tool not installed"
     fi

     local file="home/path/to/config"
     run tool --validate "$file"
     [ "$status" -eq 0 ]
   }
   ```

3. For templates, render first:
   ```bash
   run render_template "$file"
   [ "$status" -eq 0 ]
   ```

## Known Limitations

- **Tool-specific**: Requires tools to be installed for validation
- **Syntax-focused**: Doesn't test runtime behavior or integration
- **Parser variations**: Different TOML/YAML parsers may have slight differences (see jj config note)

## Trade-offs

**What we gain**: Fast, automated validation that catches most config errors before deployment.

**What we exclude**: Runtime integration testing (how configs interact with system state), performance testing, full end-to-end testing in production environments.

This is intentional - these tests focus on the 80% case (syntax and basic validation) that can be automated quickly. Complex integration issues still require manual testing or full system tests.
