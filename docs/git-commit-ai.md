# git-commit-ai

AI-powered commit message generator for git and jj using Claude Code CLI.

## Overview

`git-commit-ai` is a script that acts as an `EDITOR` for git and jj commits, automatically generating commit messages based on your staged changes using Claude Code's AI capabilities. It analyzes your diff and recent commit history to generate contextually appropriate, well-formatted commit messages following Conventional Commits format.

## Features

- **Automatic commit message generation** based on staged changes
- **Works with both git and jj** version control systems
- **Configurable prompts** via git/jj config
- **Conventional Commits format** by default (feat, fix, docs, etc.)
- **Context-aware** - analyzes recent commits to match your style
- **LLM-optimized** - can use special git config for cleaner diffs
- **Customizable** - override prompts via config or environment variables

## Installation

The script is automatically installed to `~/.local/bin/git-commit-ai` via chezmoi.

Ensure `~/.local/bin` is in your `PATH`:

```bash
export PATH="$HOME/.local/bin:$PATH"
```

## Usage

### One-time usage

Use the script as a temporary editor override:

```bash
# For git
EDITOR=git-commit-ai git commit

# For jj
EDITOR=git-commit-ai jj commit
```

### Configure as default editor

Set it as your default editor in git or jj config:

```bash
# For git
git config --global core.editor git-commit-ai

# For jj
jj config set --user ui.editor git-commit-ai
```

### Shell aliases

Add convenient aliases to your shell config:

```bash
# Zsh/Bash
alias gca='EDITOR=git-commit-ai git commit'
alias jca='EDITOR=git-commit-ai jj commit'
```

## Configuration

### Custom prompts

Customize the AI prompt via config:

```bash
# For git (using ai.commitPrompt)
git config --global ai.commitPrompt "Generate a concise commit message following our team's style guide..."

# Or using commit.aiCommitPrompt
git config --global commit.aiCommitPrompt "Your custom prompt here..."

# For jj (add to ~/.config/jj/config.toml)
[ai]
commitPrompt = "Your custom prompt here..."
```

### LLM-optimized git config

Enable the LLM-friendly git config for cleaner diffs (no colors, no pagers):

```bash
git config --global ai.useLlmConfig true
```

This uses the config at `~/.config/git/config-llm` which provides clean, parseable output ideal for AI processing.

### Environment variables

Override behavior with environment variables:

```bash
# Enable debug output
AI_COMMIT_DEBUG=1 EDITOR=git-commit-ai git commit

# Custom prompt override
AI_COMMIT_PROMPT="Your prompt" EDITOR=git-commit-ai git commit

# Limit diff size (default: 500 lines)
AI_COMMIT_MAX_DIFF=1000 EDITOR=git-commit-ai git commit

# Show the prompt that would be used (without committing)
AI_COMMIT_SHOW_PROMPT=1 git-commit-ai .git/COMMIT_EDITMSG
```

## Prompt customization examples

### Detailed format

```bash
git config --global ai.commitPrompt "Generate a commit message with:
- Type: feat/fix/docs/style/refactor/perf/test/chore
- Subject: imperative, no period, max 50 chars
- Body: detailed explanation wrapped at 72 chars
- Footer: issue references if applicable"
```

### Brief format

```bash
git config --global ai.commitPrompt "Generate a brief one-line commit message using conventional commits format. Be concise."
```

### Team-specific style

```bash
git config --global ai.commitPrompt "Follow our team conventions:
- Use emoji prefixes (✨ feat, 🐛 fix, 📝 docs, etc.)
- Reference JIRA tickets in format [PROJ-123]
- Keep under 72 characters total"
```

## How it works

1. Script is invoked as the EDITOR by git/jj with the commit message file path
2. Detects whether you're using git or jj
3. Retrieves staged changes (diff) and recent commit history
4. Reads custom prompt from config if available
5. Constructs a comprehensive prompt with context
6. Calls Claude Code CLI to generate the commit message
7. Cleans up the response (removes markdown artifacts)
8. Writes the generated message to the commit message file
9. Returns control to git/jj as if you manually edited the file

## Default prompt

The default prompt generates messages following Conventional Commits:

```
Generate a commit message following these guidelines:

1. Use Conventional Commits format: <type>: <subject>
2. Types: feat, fix, docs, style, refactor, perf, test, chore
3. Subject: imperative mood, no period, max 50 chars
4. Body (optional): explain what and why (not how), wrap at 72 chars
5. Footer (optional): breaking changes, issue references

Analyze the diff and recent commits to understand context and style.
Be concise but descriptive. Do not include comments.
```

## Examples

### Basic git workflow

```bash
# Make some changes
echo "export NEW_VAR=value" >> ~/.zshrc

# Stage changes
git add ~/.zshrc

# Commit with AI-generated message
EDITOR=git-commit-ai git commit

# Result: "feat: add NEW_VAR environment variable"
```

### JJ workflow

```bash
# Make changes
nvim config.toml

# Commit with AI-generated message
EDITOR=git-commit-ai jj commit

# Result: "chore: update configuration settings"
```

### Debugging

```bash
# See what prompt is being sent to Claude
AI_COMMIT_DEBUG=1 EDITOR=git-commit-ai git commit

# View the full prompt without committing
AI_COMMIT_SHOW_PROMPT=1 git-commit-ai .git/COMMIT_EDITMSG
```

## Tips and best practices

1. **Stage meaningful changes**: The AI generates better messages when changes are cohesive
2. **Review the message**: The script exits normally, so you can still edit the message if needed with `git commit --amend`
3. **Use custom prompts**: Tailor the AI behavior to match your team's conventions
4. **Combine with aliases**: Create convenient shortcuts for your workflow
5. **Enable LLM config**: Use `ai.useLlmConfig=true` for cleaner diffs and better AI responses

## Troubleshooting

### Claude CLI not found

Ensure Claude Code CLI is installed and in your PATH:

```bash
which claude
# Should output: /path/to/claude
```

### No changes to commit

The script requires staged changes (for git) or modifications (for jj):

```bash
# For git, stage changes first
git add .

# For jj, changes are automatically tracked
```

### Custom prompt not working

Check your config:

```bash
# For git
git config --get ai.commitPrompt

# For jj
jj config list | grep commitPrompt
```

### Diff too large

If your diff is very large, limit it:

```bash
AI_COMMIT_MAX_DIFF=200 EDITOR=git-commit-ai git commit
```

## Integration with existing workflows

### Pre-commit hooks

You can use this in pre-commit hooks, but be aware it requires user interaction with Claude:

```bash
#!/bin/bash
# .git/hooks/prepare-commit-msg

if [ -z "$2" ]; then
  git-commit-ai "$1"
fi
```

### Git aliases

Add to your git config:

```gitconfig
[alias]
    aic = "!git add -p && EDITOR=git-commit-ai git commit"
    aica = "!git add . && EDITOR=git-commit-ai git commit"
```

### JJ aliases

Add to your jj config:

```toml
[aliases]
aic = ["util", "exec", "--", "bash", "-c", "EDITOR=git-commit-ai jj commit"]
```

## Security and privacy

- The script sends your diff and recent commits to Claude's API
- Ensure you're comfortable with your changes being sent to Claude
- For sensitive repositories, consider using custom prompts that exclude certain information
- Review generated messages before pushing to ensure no sensitive data is included

## See also

- [Conventional Commits](https://www.conventionalcommits.org/)
- [Git commit message guidelines](https://cbea.ms/git-commit/)
- [JJ documentation](https://martinvonz.github.io/jj/)
- [Claude Code CLI](https://docs.claude.com/claude-code)
