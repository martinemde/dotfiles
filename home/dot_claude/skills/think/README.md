# `/think` — Rigorous Solution Partner

A thought partner that pressure-tests assumptions, surfaces constraints, evaluates trade-offs, and holds proposals accountable to the project's stated vision and principles.

```
/think should we replace tmux plugins with a minimal config?
/think the login flow is broken — what's the best fix approach?
```

## Why this exists

Some decisions look obvious in the moment and turn out to be wrong in practice. The most common failure: a technically correct solution to the wrong interpretation of the problem. [`/think`](../think/README.md) exists to catch these before they become code.

It's not a brainstorming tool. It's an adversarial collaborator. It will:
- Challenge the framing of the problem, not just the proposed solution
- Flag when a proposal drifts from the project's stated vision or principles
- Name trade-offs that are easy to miss when you're invested in an approach
- Recommend a specific path, not a list of options to choose from

The key anti-pattern it prevents: the agent agreeing with your framing because you sound confident. [`/think`](../think/README.md) is specifically prompted to push back.

## In the [`/work-on`](../work-on/README.md) workflow

[`/think`](../think/README.md) is the handoff point — the moment where human involvement is highest and most valuable, and after which the agent works autonomously.

It runs after [`/gather-context`](../gather-context/README.md) builds the factual foundation. This is important: instead of speculating about what the code might say, the conversation starts from what it actually says. The open questions surfaced during context gathering become the framing for [`/think`](../think/README.md).

The invocation from [`/work-on`](../work-on/README.md) passes specific args — the key decisions to make, trade-offs to evaluate, and open questions that need resolution. This constrains [`/think`](../think/README.md) toward convergence rather than open-ended exploration. The goal isn't a comprehensive analysis; it's a *decision* that both the human and agent understand well enough to execute against.

Once [`/think`](../think/README.md) produces that decision, execution begins. The agent doesn't loop back for approval during implementation unless it hits a genuine blocker.

## Vision and principles alignment

[`/think`](../think/README.md) reads `docs/vision.md` and `docs/core-principles.md` at activation time. If a proposal drifts from stated principles — technically fine but architecturally wrong for this project — [`/think`](../think/README.md) will name the drift. This is intentional: the documents exist to be enforced, not consulted.

## Standalone usage

[`/think`](../think/README.md) is useful outside the [`/work-on`](../work-on/README.md) workflow for any decision with real trade-offs: tool selection, architectural changes, process design, prioritization. The same forcing function applies — it converges toward a recommendation, not a list of options.
