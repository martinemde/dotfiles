# Claude Plugin Marketplace

Personal dotfiles Claude Code extensions including agents, skills, and commands for enhanced development workflows.

## Overview

This marketplace provides a collection of Claude Code extensions organized into three categories:

- **Agents**: Specialized subagents for complex tasks (PR review, code review, shell scripting)
- **Skills**: Domain expertise modules (Jujutsu VCS, skill creation, package management)
- **Commands**: Utility slash commands (gitingest for repository documentation)

## Installation

To add this marketplace to your Claude Code instance:

```bash
/plugin marketplace add martinemde/dotfiles
```

Or using a direct URL:

```bash
/plugin marketplace add https://github.com/martinemde/dotfiles
```

## Available Plugins

### Agents

#### PR Feedback Reviewer

Analyzes pull request feedback and comments, validates their validity, and provides prioritized recommendations for addressing concerns.

**Keywords**: agent, pr, review, feedback, github

#### Code Reviewer

Senior-engineer level code and document reviewer that enforces modern patterns, scope boundaries, and code quality standards. Review-only mode writes reports to `scratch/` folder.

**Keywords**: agent, review, code-quality, documentation

#### Shell Wizard

Writes production-quality shell scripts following best practices with safety headers, error handling, and modern patterns.

**Keywords**: agent, shell, bash, scripting

### Skills

#### Jujutsu Skill

Comprehensive guidance for using Jujutsu (jj) version control system instead of Git, including concepts, commands, and GitHub integration. Includes extensive reference documentation.

**Keywords**: skill, jujutsu, jj, vcs, version-control

#### Skill Creator

Guide for creating new skills that extend Claude's capabilities with progressive disclosure design and bundled resources. Includes helper scripts for skill initialization and packaging.

**Keywords**: skill, meta, creation, extension

#### Chezmoi Package Manager

Manages packages and external dependencies in chezmoi dotfiles across Homebrew, mise, Python, Docker, and chezmoi externals with version pinning and Renovate integration.

**Keywords**: skill, chezmoi, package-management, renovate

### Commands

#### gitingest

Fetch and contextualize GitHub repositories for future reference, generating structured documentation in `docs/reference/`.

**Usage**: `/gitingest <repo-url|user/repo|repo-name>`

**Keywords**: command, github, repository, documentation

#### tdd

Guide implementation using Test-Driven Development red-green-refactor cycle. Enforces writing failing tests first, minimal implementation, and continuous refactoring.

**Usage**: `/tdd <feature-description>`

**Keywords**: command, tdd, testing, red-green-refactor, test-driven-development

## Plugin Structure

Each plugin is organized in its own directory:

```
home/dot_claude/
├── agents/
│   ├── pr-feedback-reviewer/
│   ├── reviewer/
│   └── shell-wizard/
├── commands/
│   ├── gitingest/
│   └── tdd/
└── skills/
    ├── skill-creator/
    └── use-jj-not-git/
```

Root-level plugins:

```
.claude/
└── skills/
    └── chezmoi/
```

## Development

### Adding New Plugins

1. Create plugin directory in appropriate category (`agents/`, `skills/`, or `commands/`)
2. Add plugin files (agents/_.md, skills/SKILL.md, commands/_.md)
3. Update `.claude-plugin/marketplace.json` with plugin entry
4. Run chezmoi apply to sync changes

### Plugin Format

Plugins use Claude Code's standard format:

- **Agents**: Single markdown file with agent instructions
- **Skills**: SKILL.md with optional bundled reference files
- **Commands**: Single markdown file with command expansion prompt

## License

This marketplace is part of a personal dotfiles repository. Individual plugins may have different licenses - see individual plugin directories for details.

## Support

For issues or questions about these plugins, please open an issue at https://github.com/martinemde/dotfiles/issues
