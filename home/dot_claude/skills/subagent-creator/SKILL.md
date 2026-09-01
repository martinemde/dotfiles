---
name: subagent-creator
description: Guide for creating Claude Code plugins including sub-agents, commands, skills, and hooks. Use when users want to create or modify Claude Code extensions, automation workflows, or specialized AI assistants.
---

# Subagent & Plugin Creator

This skill provides guidance for extending Claude Code through sub-agents, commands, skills, and hooks.

## Extension Types Overview

Claude Code supports four primary extension types:

1. **Sub-agents** - Specialized AI assistants with custom system prompts and tool access
2. **Commands** - User-invoked slash commands for explicit workflows
3. **Skills** - Model-invoked capabilities that Claude autonomously uses based on context
4. **Hooks** - Shell commands that execute automatically at lifecycle events

## When to Use Each Type

### Sub-agents
Create sub-agents when:
- Tasks require specialized expertise in a specific domain
- The workflow needs a different tool set than the main conversation
- Context isolation is beneficial (e.g., code review without polluting main context)
- Reusable specialized personas are valuable across projects

### Commands
Create commands when:
- Users need explicit, repeatable workflows
- The task follows a predictable pattern (e.g., TDD workflow, gitingest)
- Direct user invocation is preferred over model decision
- The workflow is simple enough for a single markdown file

### Skills
Create skills when:
- Claude should autonomously decide when to apply specialized knowledge
- Multiple supporting resources are needed (scripts, references, templates)
- Progressive disclosure of context is important
- The capability should be discoverable across conversations

### Hooks
Create hooks when:
- Automation must happen at specific lifecycle points
- Deterministic behavior is required (not model-dependent)
- Integration with external tools is needed (formatters, linters, notifications)
- Enforcement of policies or conventions is necessary

## Creating Sub-agents

### Quick Creation Process

1. Use `/agents` command to access the creation interface
2. Choose storage location:
   - `.claude/agents/` for project-level (team-shared, version controlled)
   - `~/.claude/agents/` for user-level (personal, cross-project)
3. Describe the sub-agent's purpose and when it should be used
4. Select available tools or inherit all tools from main conversation
5. Generate initial configuration with Claude's assistance
6. Customize the system prompt for specific requirements

### File Structure

Sub-agents use markdown files with YAML frontmatter:

```markdown
---
name: unique-lowercase-identifier
description: Natural language purpose statement that helps Claude decide when to delegate
tools: Read, Write, Bash, Grep, Glob  # Optional: omit to inherit all tools
model: sonnet  # Optional: specify 'sonnet', 'haiku', 'opus', or 'inherit'
skills: skill-name-1, skill-name-2  # Optional: auto-load specific skills
---

System prompt content here. This defines the sub-agent's expertise,
behavior, constraints, and workflow instructions.

Use imperative/infinitive form for all instructions.
```

### Required Fields

- `name` - Unique identifier using lowercase with hyphens
- `description` - Clear statement of purpose and usage context (critical for automatic delegation)

### Optional Fields

- `tools` - Comma-separated list restricting tool access (omit for full access)
- `model` - Specify model alias or use 'inherit' for parent's model
- `skills` - Comma-separated skill names to auto-load into sub-agent context

### Storage Locations Priority

1. Project agents: `.claude/agents/` (highest priority, team-shared)
2. User agents: `~/.claude/agents/` (personal, lower priority)
3. Plugin agents: Defined in plugin manifest

### Best Practices for Sub-agents

- **Single-purpose focus**: Create specialized sub-agents rather than multi-function ones
- **Detailed prompts**: Include specific instructions, examples, and constraints
- **Limit tool access**: Grant only necessary tools for security and performance
- **Clear descriptions**: Enable accurate automatic delegation with specific trigger scenarios
- **Version control**: Store project sub-agents in repositories for team collaboration

### Invocation Methods

**Automatic delegation**: Claude delegates based on task matching sub-agent description
**Explicit request**: "Use the code-reviewer sub-agent to check my recent changes"

### Advanced Features

- **Chaining**: Complex workflows can chain multiple sub-agents sequentially
- **Resumable**: Sub-agents receive unique IDs for continuation across sessions
- **Context preservation**: Each operates in isolated context, preventing main conversation pollution

## Creating Commands

### File Structure

Commands are simple markdown files without YAML frontmatter:

```markdown
Command instructions here using imperative form.

Can reference $ARGUMENTS for user-provided parameters.

Example: "Follow the Test-Driven Development workflow for implementing $ARGUMENTS."
```

### Storage Locations

- Project commands: `.claude/commands/`
- User commands: `~/.claude/commands/`
- Plugin commands: `commands/` directory in plugin structure

### Command Best Practices

- Keep commands focused on single workflows
- Use clear, actionable language
- Reference $ARGUMENTS when user input is needed
- Include structured steps for complex workflows
- Test with various argument patterns

### Examples

See existing commands:
- `home/dot_claude/commands/tdd/tdd.md` - Test-driven development workflow
- `home/dot_claude/commands/gitingest/gitingest.md` - Repository ingestion

## Creating Skills

Skills are the most complex extension type, supporting bundled resources and progressive disclosure.

### Core Structure

```
skill-name/
├── SKILL.md (required)
│   ├── YAML frontmatter metadata
│   └── Markdown instructions
└── Bundled Resources (optional)
    ├── scripts/          - Executable code
    ├── references/       - Documentation loaded as needed
    └── assets/           - Output templates and resources
```

### SKILL.md Format

```markdown
---
name: lowercase-with-hyphens (max 64 chars)
description: What it does and when to use it (max 1024 chars) - CRITICAL for discovery
allowed-tools: Read, Grep, Glob  # Optional: restrict tool access
---

# Skill Name

Purpose statement and overview.

## When to Use This Skill

Specific scenarios and trigger conditions.

## How to Use

Detailed instructions referencing any bundled resources.
```

### Bundled Resources

**scripts/** - Executable code for deterministic reliability
- Use when same code is repeatedly rewritten
- Token efficient, may execute without loading into context
- Examples: `scripts/rotate_pdf.py`, `scripts/init_skill.py`

**references/** - Documentation loaded as needed
- Use for schemas, API docs, domain knowledge, policies
- Keeps SKILL.md lean while maintaining discoverability
- Examples: `references/api_docs.md`, `references/schema.md`
- For large files (>10k words), include grep search patterns in SKILL.md

**assets/** - Files used in output
- Use for templates, images, boilerplate, fonts
- Not loaded into context, used in final output
- Examples: `assets/logo.png`, `assets/template.html`

### Storage Locations

- Project skills: `.claude/skills/` (team-shared, version controlled)
- User skills: `~/.claude/skills/` (personal, cross-project)
- Plugin skills: `skills/` directory in plugin structure

### Progressive Disclosure Design

1. **Metadata** (name + description) - Always in context (~100 words)
2. **SKILL.md body** - When skill triggers (<5k words)
3. **Bundled resources** - As needed by Claude (unlimited)

### Skills Best Practices

- **Focused scope**: One capability per skill, not multi-function
- **Specific descriptions**: Include trigger terms and file types
- **Imperative form**: Use verb-first instructions throughout
- **Avoid duplication**: Information lives in SKILL.md OR references, not both
- **Test discovery**: Verify Claude activates skill for relevant queries

### Skill Creation Workflow

1. Understand concrete usage examples
2. Plan reusable resources (scripts, references, assets)
3. Initialize structure (or use `scripts/init_skill.py` if available)
4. Implement bundled resources first
5. Write SKILL.md with clear purpose and instructions
6. Test and iterate based on real usage

## Creating Hooks

Hooks provide deterministic automation at specific lifecycle points.

### Available Hook Events

- **PreToolUse** - Executes before tool calls, can block them
- **PermissionRequest** - Runs when permission dialogs appear
- **PostToolUse** - Executes after tool calls complete
- **UserPromptSubmit** - Runs when users submit prompts
- **Notification** - Triggers when Claude sends notifications
- **Stop** - Runs when Claude finishes responding
- **SubagentStop** - Executes when subagent tasks complete
- **PreCompact** - Runs before compaction operations
- **SessionStart** - Executes at session start or resumption
- **SessionEnd** - Triggers when sessions terminate

### Common Use Cases

- Automated code formatting (Prettier, gofmt, black)
- Command logging for compliance
- Custom permission controls for sensitive files
- Desktop notifications for user input requirements
- Automated feedback for code convention violations

### Configuration Storage

Hooks are configured in `~/.claude/settings.json` and can be scoped to:
- User level: Apply across all projects
- Project level: Apply only to specific project

### Hook Format

Hooks are shell commands that execute in the user's environment. They receive context through environment variables and stdin.

### Security Considerations

**CRITICAL**: Hooks run automatically with current environment credentials. Review all hook code thoroughly before registration to prevent:
- Data exfiltration
- Credential exposure
- Unintended system modifications

Only install hooks from trusted sources.

### Hooks Best Practices

- Keep hooks idempotent
- Handle errors gracefully
- Log appropriately for debugging
- Test in isolated environment first
- Document hook purpose and behavior
- Minimize execution time to avoid latency

## Plugin Structure

For distributing multiple extensions together, use the plugin system:

```
plugin-name/
├── .claude-plugin/
│   └── plugin.json          # Metadata descriptor
├── commands/                # Slash commands (optional)
├── agents/                  # Sub-agents (optional)
├── skills/                  # Agent skills (optional)
└── hooks/
    └── hooks.json           # Event handlers (optional)
```

### Plugin Development Workflow

1. Create plugin structure with desired components
2. Use local test marketplace during development
3. Install with `/plugin install`
4. Iterate through uninstall/reinstall cycles
5. Share via plugin marketplace or git repository

## Writing Style Guidelines

**All extension content should use imperative/infinitive form:**
- ✓ "To accomplish X, do Y"
- ✓ "Execute command to achieve result"
- ✗ "You should do X"
- ✗ "If you need to do X"

Use objective, instructional language for AI consumption.

## Storage Location Decision Matrix

| Extension Type | Project-Level | User-Level |
|---------------|---------------|------------|
| Sub-agents | `.claude/agents/` | `~/.claude/agents/` |
| Commands | `.claude/commands/` | `~/.claude/commands/` |
| Skills | `.claude/skills/` | `~/.claude/skills/` |
| Hooks | Project settings.json | `~/.claude/settings.json` |

**Choose project-level when:**
- Team collaboration is required
- Version control is beneficial
- Project-specific expertise is needed

**Choose user-level when:**
- Personal workflows are being automated
- Cross-project reuse is desired
- Experimental or temporary extensions

## Troubleshooting

### Sub-agents Not Being Used
- Verify description is specific enough for automatic delegation
- Check file naming and location
- Validate YAML frontmatter syntax

### Skills Not Activating
- Make description more specific with concrete trigger scenarios
- Include file types and operations in description
- Verify correct file path and valid YAML syntax
- Check for proper YAML delimiters

### Commands Not Found
- Verify file is in correct directory
- Check command name matches file/directory name
- Ensure markdown syntax is valid

### Hooks Not Executing
- Verify event name matches available hook events
- Check shell command syntax and permissions
- Review security restrictions
- Test command independently first
