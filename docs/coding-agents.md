# Portable coding-agent configuration

Claude Code, Codex, and Pi overlap on instruction and skill concepts but do not share one complete native format. This repository keeps behavior in portable canonical files and limits product-specific configuration to thin adapters.

## Design

Canonical project files live under `.agents/`; canonical user files are installed from `home/dot_agents/` to `~/.agents/`.

- `AGENTS.md` is the project instruction source. The root `CLAUDE.md` symlink lets Claude load it without maintaining a second copy.
- `~/.agents/AGENTS.md` is the user instruction source. Chezmoi installs native instruction-name symlinks for Claude, Codex, and Pi.
- `.agents/skills/` and `~/.agents/skills/` are canonical skill roots. Codex and Pi discover them directly. Claude receives `.claude/skills` and `~/.claude/skills` symlinks because its native roots use a different name.
- `.agents/agents/` and `~/.agents/agents/` contain reusable agent instruction bodies. Pi's `pi-subagents` extension discovers these Markdown files directly.
- `.claude/agents/`, `~/.claude/agents/`, `.codex/agents/`, and `~/.codex/agents/` contain thin native wrappers. They retain native tool, model, sandbox, and skill-preload settings while directing the agent to the canonical body.

The wrappers are intentional duplication boundaries: identity and permissions belong to each harness; operating behavior belongs in one canonical Markdown file.

## Native loading behavior

| Concern              | Claude Code                        | Codex                        | Pi                                        |
| -------------------- | ---------------------------------- | ---------------------------- | ----------------------------------------- |
| Project instructions | `CLAUDE.md` symlink to `AGENTS.md` | `AGENTS.md`                  | `AGENTS.md`                               |
| User instructions    | `~/.claude/CLAUDE.md` symlink      | `~/.codex/AGENTS.md` symlink | `~/.pi/agent/AGENTS.md` symlink           |
| Project skills       | `.claude/skills` symlink           | `.agents/skills`             | `.agents/skills`                          |
| User skills          | `~/.claude/skills` symlink         | `~/.agents/skills`           | `~/.agents/skills`                        |
| Custom agents        | Markdown wrapper                   | TOML wrapper                 | canonical Markdown through `pi-subagents` |

## Constraints and trade-offs

- Shared skills use only `name` and `description` frontmatter. Harness-only fields such as model, tool permissions, argument hints, and dynamic command interpolation stay out of canonical skills.
- Shared skills remain self-contained or depend only on capabilities available across the target harnesses. Harness- or plugin-specific enrichment must be optional rather than a prerequisite for the workflow.
- Claude account skill sync is disabled with `syncClaudeAiSkills: false`. Its native skills path points into the shared root, so downloaded account skills otherwise enter Codex and Pi discovery too. Chezmoi removes existing `.agents/skills/synced` downloads.
- Agent bodies may use Pi-compatible metadata because Pi loads them directly. Claude and Codex wrappers ignore that frontmatter and apply their native settings.
- The Pi extension packages are exact npm pins in `home/dot_pi/private_agent/settings.json`. The `private_` directory preserves the existing `0700` permissions on `~/.pi/agent`, which also holds credentials and session state. `pi update --extensions` deliberately does not move exact pins; Renovate owns extension upgrades.
- Claude agent wrappers remain real files instead of symlinks because native agent metadata differs materially and recursive symlink behavior is not part of the compatibility contract.
- Local transcripts are deliberately long-lived: Claude uses a 36,500-day cleanup window, while Codex persists history without a byte cap. Chezmoi modifies only Codex's history table because the CLI and desktop app own the rest of `~/.codex/config.toml`. Both tools store transcripts as plaintext, so local disk access remains the privacy boundary.

## Sources

- [Claude Code memory and `CLAUDE.md` imports](https://docs.anthropic.com/en/docs/claude-code/memory)
- [Claude Code skills](https://docs.anthropic.com/en/docs/claude-code/skills)
- [Claude Code subagents](https://docs.anthropic.com/en/docs/claude-code/sub-agents)
- [Claude Code settings](https://code.claude.com/docs/en/settings)
- [Codex skills](https://developers.openai.com/codex/skills/)
- [Codex multi-agent configuration](https://developers.openai.com/codex/multi-agent/)
- [Codex advanced configuration](https://learn.chatgpt.com/docs/config-file/config-advanced)
- [Pi package documentation](https://github.com/badlogic/pi-mono/tree/main/packages/coding-agent)

This structure favors one editable behavioral source over perfectly identical native capabilities. New shared behavior belongs in the canonical file; adapter changes should be limited to discovery, permissions, model choice, or preload syntax.
