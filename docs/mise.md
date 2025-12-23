# Mise

## Context and Problem Statement

The dotfiles repository currently uses Homebrew to install development tools like Python, Node.js, and associated tooling. While working on a project requiring Ansible and other Python CLI tools, inconsistencies emerged: Python was installed via Homebrew, but Python tool management (via uv) needed to align with the Python runtime managed by Mise for consistency. This creates a fragmented tool management approach where some tools come from package managers and others from version managers.

## Decision Drivers

- **Project-specific version requirements**: Need to switch between Python/Node.js versions based on project requirements
- **Reproducibility**: Pinned versions ensure consistent environments across machines and time
- **Performance**: Faster dotfile provisioning by avoiding unnecessary tool reinstallations
- **Consistency**: Single tool management approach reduces complexity
- **Toolchain integration**: Tools like uv, npm globals should use the same runtime they're installed for

## Considered Options

- **Continue with Homebrew-only approach**: Install all tools via package managers
- **Hybrid Homebrew + Mise approach**: Use Homebrew for some tools, Mise for others
- **Mise-first approach**: Use Mise for globally versioned tooling, Homebrew for system utilities

## Decision Outcome

Chosen option: "Mise-first approach", because it provides project-specific version management while maintaining fast provisioning through granular update triggers.

### Consequences

- Good, because tools are pinned to specific versions improving reproducibility
- Good, because project-specific version switching is seamless
- Good, because dotfile updates only reinstall affected toolchains
- Good, because toolchain integration (Python + uv) is consistent
- Bad, because pinned versions require ongoing maintenance
- Bad, because adds complexity to the chezmoi template system

### Confirmation

Implementation success will be confirmed by:

- Fast dotfile provisioning (no unnecessary tool reinstalls)
- Successful project-specific Python version switching
- Consistent toolchain behavior (uv using Mise-managed Python)
- Granular run_onchange script execution

## Pros and Cons of the Options

### Continue with Homebrew-only approach

Install all development tools including Python, Node.js via Homebrew packages.

- Good, because simple single package manager approach
- Good, because automatic dependency management
- Bad, because no project-specific version switching
- Bad, because uv/npm tools don't align with runtime versions
- Bad, because system-wide version conflicts

### Hybrid Homebrew + Mise approach

Use Homebrew for system tools, Mise for development runtimes, with mixed approaches for associated tooling.

- Good, because leverages strengths of both tools
- Neutral, because maintains some Homebrew simplicity
- Bad, because creates inconsistent toolchain integration
- Bad, because unclear decision boundaries for new tools
- Bad, because complex mental model for contributors

### Mise-first approach

Use Mise for globally versioned development tooling (Python, Node.js, etc.) and their associated packages, Homebrew for system utilities.

- Good, because consistent toolchain integration
- Good, because project-specific version management
- Good, because pinned versions improve reproducibility
- Good, because granular update triggers improve provisioning performance
- Bad, because requires version maintenance overhead
- Bad, because more complex chezmoi template patterns

## More Information

### Implementation Strategy

Tool-specific `run_onchange` scripts will be created using regex-based version extraction for granular triggering:

```bash
# python version hash: {{ include "dot_config/mise/config.toml" | regexFind "python = \"[^\"]*\"" | sha256sum }}
```

This ensures scripts only execute when their specific tool version changes, not when any part of the mise config is modified.

**Script execution order**: The base mise installation script is prefixed with `00-` to ensure tools are installed before language-specific scripts run:

- `run_onchange_00-install-mise-tools.sh.tmpl` - Installs all mise-defined tools
- `run_onchange_install-python-tools.sh.tmpl` - Installs Python ecosystem tools (via uv tool install)
- Future: `run_onchange_install-nodejs-tools.sh.tmpl`, etc.

### Technical Implementation Notes

**Chezmoi template patterns**: Using `regexFind` with `include` allows extraction of specific configuration lines for targeted change detection. This is more precise than hashing entire config files.

**Path resolution**: Template paths are relative to the `.chezmoiroot` directory (`home/`), so `dot_config/mise/config.toml` maps to `.config/mise/config.toml` in the target system.

### Future Considerations

- **Renovate integration**: Automated version updates will address maintenance overhead
- **Tool categorization**: Clear guidelines for when to use Mise vs Homebrew
- **Documentation**: Update CLAUDE.md with new tool management patterns
- **Testing**: Consider adding BATS tests for tool installation script logic

### Migration Path

1. Migrate from pipx to uv for Python tool management (uv installed via Homebrew)
2. Establish tool-specific script patterns
3. Migrate other development tooling incrementally
4. Document patterns for future tool additions
