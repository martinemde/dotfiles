# Git Editor Mechanism: How git-commit-ai Works

This document explains how Git's EDITOR mechanism works and how `git-commit-ai` integrates with it.

## Table of Contents

- [How Git Invokes Editors](#how-git-invokes-editors)
- [The EDITOR Priority Chain](#the-editor-priority-chain)
- [How git-commit-ai Works](#how-git-commit-ai-works)
- [Configuration Strategies](#configuration-strategies)
- [Troubleshooting](#troubleshooting)

## How Git Invokes Editors

When Git needs to open an editor (for commits, rebases, etc.), it follows a specific process:

### 1. Git Creates a Temporary File

Git creates a temporary file with content depending on the operation:

```bash
# For commits
.git/COMMIT_EDITMSG

# For interactive rebases
.git/rebase-merge/git-rebase-todo

# For tag messages
.git/TAG_EDITMSG
```

### 2. Git Pre-populates the File

For commit messages, Git pre-populates the file with:
- The commit template (from `commit.template` config)
- Commented status information (files changed, etc.)
- Previous commit message (for amend operations)

Example `.git/COMMIT_EDITMSG`:
```
# Please enter the commit message for your changes. Lines starting
# with '#' will be ignored, and an empty message aborts the commit.
#
# On branch main
# Changes to be committed:
#   modified:   file.txt
#
```

### 3. Git Invokes the Editor

Git calls the configured editor with the file path as the first argument:

```bash
$EDITOR /path/to/.git/COMMIT_EDITMSG
```

The editor is expected to:
1. Open the file for editing
2. Allow the user to modify it
3. Save changes and exit

### 4. Git Reads the Modified File

After the editor exits (with status code 0), Git:
1. Reads the modified file
2. Strips out comment lines (starting with `#`)
3. Uses the remaining content as the commit message
4. Aborts if the message is empty

### 5. Git Completes the Operation

If the message is valid, Git creates the commit with the message.

## The EDITOR Priority Chain

Git determines which editor to use by checking these sources in order:

### Priority 1: GIT_EDITOR Environment Variable

```bash
GIT_EDITOR=nvim git commit
```

**Use case**: One-time override for a single command

### Priority 2: core.editor Git Configuration

```bash
git config --global core.editor "nvim -f"
```

**Use case**: Your standard Git editor

### Priority 3: VISUAL Environment Variable

```bash
export VISUAL=nvim
git commit
```

**Use case**: System-wide visual editor preference

### Priority 4: EDITOR Environment Variable

```bash
export EDITOR=vim
git commit
```

**Use case**: System-wide default editor

### Priority 5: Fallback Editors

Git falls back to: `vi` → `nano` → `notepad` (Windows)

### Complete Priority Chain

```
GIT_EDITOR > core.editor > VISUAL > EDITOR > fallback
```

## How git-commit-ai Works

`git-commit-ai` is a **script that masquerades as an editor**. Here's the detailed flow:

### Step-by-Step Process

#### 1. Git Invokes git-commit-ai

```bash
# User runs (with AI editor configured)
git commit

# Git internally calls
git-commit-ai /path/to/.git/COMMIT_EDITMSG
```

#### 2. Script Detects VCS Type

```bash
if [[ -d .git ]] || git rev-parse --git-dir >/dev/null 2>&1; then
    vcs="git"
elif [[ -d .jj ]] || jj root >/dev/null 2>&1; then
    vcs="jj"
fi
```

#### 3. Script Gathers Context

The script collects information for Claude:

```bash
# Get staged changes
diff=$(git diff --staged)

# Get recent commits for style context
recent_commits=$(git log --oneline -10)

# Read custom prompt from config
custom_prompt=$(git config --get ai.commitPrompt)
```

#### 4. Script Builds AI Prompt

```bash
prompt="$custom_prompt

## Context

Recent commits:
\`\`\`
$recent_commits
\`\`\`

## Changes to commit

\`\`\`diff
$diff
\`\`\`

Generate the commit message now:"
```

#### 5. Script Calls Claude Code CLI

```bash
response=$(claude -c "$prompt")
```

Claude analyzes the diff and generates an appropriate commit message.

#### 6. Script Writes Message to File

```bash
# Clean up Claude's response (remove markdown, etc.)
commit_message=$(clean_commit_message "$response")

# Write to the file Git expects
echo "$commit_message" > /path/to/.git/COMMIT_EDITMSG
```

#### 7. Script Exits Successfully

```bash
exit 0
```

#### 8. Git Reads the Modified File

Git reads `.git/COMMIT_EDITMSG` and finds the AI-generated message.

#### 9. Git Creates the Commit

Git proceeds as if you manually wrote the message.

### Visual Flow Diagram

```
┌─────────────────────────────────────────────────────────────┐
│ User: git commit                                             │
└───────────────────┬─────────────────────────────────────────┘
                    ▼
┌─────────────────────────────────────────────────────────────┐
│ Git: Create .git/COMMIT_EDITMSG                              │
└───────────────────┬─────────────────────────────────────────┘
                    ▼
┌─────────────────────────────────────────────────────────────┐
│ Git: Invoke $EDITOR .git/COMMIT_EDITMSG                      │
│      → git-commit-ai .git/COMMIT_EDITMSG                     │
└───────────────────┬─────────────────────────────────────────┘
                    ▼
┌─────────────────────────────────────────────────────────────┐
│ git-commit-ai: Detect VCS (git/jj)                           │
└───────────────────┬─────────────────────────────────────────┘
                    ▼
┌─────────────────────────────────────────────────────────────┐
│ git-commit-ai: Get diff (git diff --staged)                  │
└───────────────────┬─────────────────────────────────────────┘
                    ▼
┌─────────────────────────────────────────────────────────────┐
│ git-commit-ai: Get recent commits (git log --oneline -10)    │
└───────────────────┬─────────────────────────────────────────┘
                    ▼
┌─────────────────────────────────────────────────────────────┐
│ git-commit-ai: Build prompt with context                     │
└───────────────────┬─────────────────────────────────────────┘
                    ▼
┌─────────────────────────────────────────────────────────────┐
│ git-commit-ai: Call Claude Code CLI                          │
│      → claude -c "$prompt"                                   │
└───────────────────┬─────────────────────────────────────────┘
                    ▼
┌─────────────────────────────────────────────────────────────┐
│ Claude: Analyze diff, generate commit message                │
└───────────────────┬─────────────────────────────────────────┘
                    ▼
┌─────────────────────────────────────────────────────────────┐
│ git-commit-ai: Clean response, write to file                 │
│      → echo "$message" > .git/COMMIT_EDITMSG                 │
└───────────────────┬─────────────────────────────────────────┘
                    ▼
┌─────────────────────────────────────────────────────────────┐
│ git-commit-ai: Exit 0 (success)                              │
└───────────────────┬─────────────────────────────────────────┘
                    ▼
┌─────────────────────────────────────────────────────────────┐
│ Git: Read .git/COMMIT_EDITMSG                                │
└───────────────────┬─────────────────────────────────────────┘
                    ▼
┌─────────────────────────────────────────────────────────────┐
│ Git: Strip comments, validate message                        │
└───────────────────┬─────────────────────────────────────────┘
                    ▼
┌─────────────────────────────────────────────────────────────┐
│ Git: Create commit with AI-generated message                 │
└─────────────────────────────────────────────────────────────┘
```

## Configuration Strategies

There are several ways to configure `git-commit-ai` depending on your needs.

### Strategy 1: Always Use AI (Default Editor)

Make AI the default for all commits:

```bash
# Enable globally
git ai-commit-enable

# Or manually
git config --global core.editor git-commit-ai
```

**Pros**:
- Automatic for all commits
- Consistent behavior
- No need to remember special commands

**Cons**:
- Always calls Claude (may be slow/costly)
- Requires internet connection
- Can't easily bypass for quick commits

### Strategy 2: Opt-in Per Commit (Recommended)

Keep your normal editor, use AI when needed:

```bash
# Normal commits
git commit                    # Uses nvim

# AI commits (use aliases)
git cia                       # Commit with AI
git ciaa                      # Commit all with AI
```

Or shell aliases:
```bash
gca                           # git commit with AI
gcaa                          # git commit all with AI
```

**Pros**:
- Full control over when to use AI
- Fast normal commits
- Can review/edit if needed

**Cons**:
- Need to remember aliases
- Two different workflows

### Strategy 3: Per-Repository Configuration

Enable AI for specific projects:

```bash
cd ~/projects/important-project
git config core.editor git-commit-ai
```

**Pros**:
- Automatic for specific repos
- Normal editor elsewhere
- Good for critical projects

**Cons**:
- Need to configure each repo
- Easy to forget which repos use AI

### Strategy 4: Temporary Override

Use AI for a single commit:

```bash
EDITOR=git-commit-ai git commit
GIT_EDITOR=git-commit-ai git commit
```

**Pros**:
- Maximum flexibility
- No configuration needed
- Quick one-off usage

**Cons**:
- Verbose command
- Easy to mistype
- No convenience

### Strategy 5: Conditional via Git Hooks

Use `prepare-commit-msg` hook to conditionally invoke AI:

```bash
#!/bin/bash
# .git/hooks/prepare-commit-msg

# Only use AI for non-merge, non-amend commits
if [ -z "$2" ]; then
    # Get AI message
    temp_msg=$(mktemp)
    git-commit-ai "$1" > "$temp_msg" 2>&1
    if [ $? -eq 0 ]; then
        cat "$temp_msg" > "$1"
    fi
    rm "$temp_msg"
fi
```

**Pros**:
- Intelligent conditional usage
- Can customize logic
- Transparent to user

**Cons**:
- Complex setup
- Per-repository
- Harder to debug

## Troubleshooting

### AI Editor Not Being Used

Check the editor priority chain:

```bash
# Check git config
git config --get core.editor
# Expected: git-commit-ai

# Check environment
echo $GIT_EDITOR
echo $VISUAL
echo $EDITOR
# These override core.editor if set

# Check if script is in PATH
which git-commit-ai
# Expected: /home/user/.local/bin/git-commit-ai

# Test the script directly
git-commit-ai .git/COMMIT_EDITMSG
```

### Script Fails to Generate Message

Debug the script:

```bash
# Enable debug mode
AI_COMMIT_DEBUG=1 git commit

# Check if Claude CLI is available
which claude

# Test Claude directly
echo "test" | claude -c "Summarize this"

# See the prompt without committing
AI_COMMIT_SHOW_PROMPT=1 git-commit-ai .git/COMMIT_EDITMSG
```

### Git Uses Wrong Editor

Override environment variables:

```bash
# Unset environment editors
unset GIT_EDITOR VISUAL EDITOR

# Use git config only
git commit
```

Or use the explicit alias:

```bash
git cia   # Forces git-commit-ai
```

### Can't Disable AI Editor

```bash
# Disable via helper
git ai-commit-disable

# Or manually
git config --global --unset core.editor
git config --global --unset include.path

# Verify
git config --get core.editor
# Should show: (empty) or your previous editor
```

### Want to Edit AI-Generated Message

The AI generates the initial message, but you can always amend:

```bash
# Commit is created with AI message
git commit

# Edit if needed
git commit --amend
# Opens in your configured editor (likely nvim)
```

Or use interactive mode:

```bash
# Generate with AI, then edit
git cia && git commit --amend
```

## Advanced Usage

### Custom Prompts for Different Repos

```bash
# In repo A: detailed messages
cd ~/projects/repo-a
git config ai.commitPrompt "Generate detailed commit message with body and footer"

# In repo B: brief messages
cd ~/projects/repo-b
git config ai.commitPrompt "Generate brief one-line commit message"
```

### Chain with Pre-commit Hooks

```bash
#!/bin/bash
# .git/hooks/pre-commit

# Run tests
npm test || exit 1

# Format code
npm run format

# Stage formatted changes
git add -u
```

Then commit with AI:
```bash
git cia  # Tests run, code formatted, AI generates message
```

### Integration with Commit Templates

Git merges the template with AI output:

```bash
# Set a template
git config commit.template ~/.config/git/message

# Template has footers like:
#
# Refs: #

# AI generates the message, template adds structure
```

## See Also

- [git-commit-ai Documentation](git-commit-ai.md)
- [Git Documentation - git-commit](https://git-scm.com/docs/git-commit)
- [Git Configuration - core.editor](https://git-scm.com/book/en/v2/Customizing-Git-Git-Configuration)
