# Testing Strategy

## Overview

This repository includes comprehensive configuration validation tests that catch errors **before** applying configurations with chezmoi. This provides rapid feedback and prevents broken configurations from being deployed.

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
