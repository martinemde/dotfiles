# Complexity Tiers: Decision Matrix

How to assess issue complexity and select the right workflow.

## Signals

Fetch the issue and its labels. If the project has labels, use `gh label list --json name,description` to understand the project's label taxonomy. Score these signals:

| Signal | Weight | How to check |
|--------|--------|-------------|
| **Labels: type/nature** | High | Bug/fix labels → simpler; feature/workflow labels → more complex |
| **Labels: readiness** | High | Agent-ready labels → well-specified; human-required labels → needs clarification first |
| **Labels: scope** | Medium | Single scope/area label → focused; multiple → cross-cutting |
| **Body length** | Medium | Short + specific → simpler; long + discursive → complex |
| **Comment count** | Medium | Many comments → unresolved discussion, likely complex |
| **Linked issues** | High | Links to other issues → dependencies, broader scope |
| **File references** | Low | Body names specific files → clearer scope |
| **Design decisions** | High | Body asks "should we X or Y?" → needs `/think` |
| **Sub-tasks** | High | Checkboxes, "Phase 1/2/3", multiple deliverables → epic |

## Tier Definitions

### Quick Fix
**Profile**: Single-file change, exact description, no design decisions.

Examples:
- Fix a typo in a config file
- Update a version pin
- Add a missing label
- Fix a broken link in docs

Signals: Bug/chore-type labels, single scope, body describes the exact change, marked as agent-ready (if the project uses readiness labels).

### Small
**Profile**: Clear scope, few files, no architectural decisions.

Examples:
- Add a new alias to zsh config
- Update a skill's instructions
- Fix a broken shell function
- Add a missing test case

Signals: Clear scope, body references specific files, no "should we" questions, 1-3 files affected.

### Medium
**Profile**: Multiple components, design choices, needs discussion.

Examples:
- Add a new skill with supporting files
- Refactor a config to use a new pattern
- Integrate a new tool across the stack
- Fix a complex bug spanning multiple files

Signals: Multiple areas or components, body discusses tradeoffs, 4-10 files affected, benefits from planning.

### Large
**Profile**: Cross-cutting, architectural implications, multiple workstreams.

Examples:
- Replace a tool across the entire stack
- Redesign how plugins are managed
- Add a new layer to the stack (e.g., container support)
- Major refactor touching 10+ files

Signals: Cross-cutting concerns, linked issues, architectural implications, benefits from parallel execution.

### Epic
**Profile**: Multi-issue, multi-PR, potentially multi-session.

Examples:
- Implement an entire new subsystem
- Migration from one tool ecosystem to another
- Series of related improvements tracked as an umbrella issue

Signals: Issue contains multiple sub-tasks (checkboxes), links to implementation issues, "Phase 1/2/3" language, too large for a single PR.

## When in Doubt

- If torn between two tiers, pick the higher one. Over-planning wastes minutes; under-planning wastes hours.
- If labels indicate the issue needs human judgment (not agent-ready), start with `/gather-context` and `/think` regardless of apparent simplicity.
- If the issue has no labels, assess from body content alone and note that labels should be added.
