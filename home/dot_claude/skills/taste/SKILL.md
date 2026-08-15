---
name: taste
description: Martin's judgement on task-shaped decisions — how to debug, how far to build, what to simplify, what to delete, how to test, what to spend, how to roll out, and how to ask him a question. Load before asking him anything with AskUserQuestion, at any fork where two reasonable approaches diverge, when deciding how much to build, or when a request could be read as either "fix it properly" or "just make it go away".
---

# Taste

Reverse-engineered from 636 recorded sessions (`~/lode/taste`). `CLAUDE.md` already carries
the rules that hold regardless of task. This carries the ones that need a task to be true.

## Debugging

Nearly half of all sessions open with "this thing I own is misbehaving," so assume this
until told otherwise.

**He wants the cause, not relief.** He will live with a broken system for days to fix it
upstream properly. A diagnosis that does not mechanically produce the symptom he observed
is not accepted — "I don't see how that would cause this effect?"

- He arrives having already looked: log pasted untrimmed, doc URL found, file pinned with
  `@`, SSH credentials volunteered. Extracting the signal from the paste is your job.
- **He states his hypothesis hedged and wants it overturned.** Contradicting his guess with
  evidence is the point. Restating his guess back to him is worthless.
- A bare pasted error log is a complete request. So is one clause: "plan fails".
- The one thing he withholds is the fix.
- Sanity-check the layer below before blaming the layer above.
- Never offer a menu of remediations while the cause is still unknown. He rejects the whole
  menu and redirects to diagnosis.
- Destruction doesn't scare him; losing evidence does. He'll wipe a disk or delete 40M rows
  without blinking, but ask before a reboot that clears the state you were about to read.

## How much to build

| Situation                                          | Which way                                                                                                                                                        |
| -------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Upstream, someone else's repo                      | Surgical. Minimal diff. "Nothing more or less."                                                                                                                  |
| His own repo                                       | Refactor freely; structural rewrites are welcome.                                                                                                                |
| The shipped surface, or anything a user configures | Ruthlessly simple. A settled fact ships as a constant, not a knob.                                                                                               |
| Measurement, analysis, investigation, content      | As elaborate as it takes. He'll ask for a twelve-phase calibration harness the same week he demands the result ship as one hardcoded number.                     |
| Considering an abstraction                         | Only if the piece becomes independently testable. "That way we can test it on its own" is the justification he accepts. Generality alone is not.                 |
| Designing a command                                | Narrow what it does, widen what it accepts. `--write` should only write, and should take a file path, not just a dir.                                            |
| Flags on a tool                                    | Human-invoked: keep `-h/--help` for discoverability. Invisible in a pipeline, "like `cat`": delete help entirely.                                                |
| A dependency is broken                             | If he still wants the thing: fork and fix it, however many lines. If it's optional and blocking a bootstrap: delete it. **Ask which before proposing a repair.** |
| Starting to build                                  | If he can see the result and undo it in seconds (dashboards, YAML): iterate, no planning. A library, integration, or protocol client: spec it and test it first. |
| Picking a model or paying for compute              | Cheapest thing that clears the bar for infrastructure he operates. Quality is non-negotiable in the thing he's building.                                         |

## Architecture

- **Fix it at the layer that owns it.** Push the decision down to whatever has the most
  local information; the upper layer expresses intent only. "I think we should let it
  manage, never call — the mitsubishi is most efficient when it makes the call and we just
  give it a goal."
- **Ground truth is never misrepresented.** A base layer reports reality; abstractions may
  translate it, never replace it. If the heat pump is heating, the module says heating —
  the dual-setpoint behavior is a translator placed over the top of the reality.
- A metric that can't be trusted says so rather than lying.
- **Everything must earn its existence.** One test, applied to config lines, entities, docs,
  dependencies, PRs: does this change a decision? If not, delete it — including things he
  added himself.
- Named failure modes, in his words: overengineered, DRY for the sake of DRY, magic numbers,
  magic booleans, kitchen sink dump, noise, weirdness, brittle, ceremony, fanfare.
- If you're automating around something structural, say so. "It makes me think there's
  something structurally wrong about our approach."
- Own the stack locally. A dependency on someone else's server is a defect to design out.

## Testing

- Outside-in. "This is a true integration test, no mocks, no checking partial output or
  checking for a certain string."
- Mocks are a smell. He accepts one only when there is genuinely no other way to know it
  worked, and he says so explicitly when he does.
- Asserting on specific colors, internals, or exact strings is brittle.
- Never strip the thing under test to make a test pass.
- Show the bug with a test, then fix it.
- **Tests passing earns nothing.** Nowhere in the corpus does a green suite draw warmth.
  A mechanism found, or a thing running on real hardware, does.

## Rollout and blast radius

Governed by who eats the failure, not by how dangerous the command looks.

- His family or real users exposed: canary first, on the thing he uses most so he sees
  breakage quickest. Never touch a device someone else depends on while he's away.
- Only him, on idempotent infrastructure: waved through. "We should run for real, it should
  be idempotent for the most part. I'm not concerned."
- Flashing, rebooting, or touching hardware needs an explicit go **for that device, in that
  message**. He is often standing next to it.
- Verify on real hardware before claiming it works, and before it reaches anyone else.

## Contributing upstream

Forking is routine and unremarkable — "we're software engineers, I do this all day" — and
the fork is dropped the moment upstream carries the fix. But contributing flips him into
surgical mode: does this fix a real bug worth the maintainer's time, and is it consistent
with what the maintainer expects? Never fork or open a PR on your own initiative. Have the
work ready and hand him the words.

## Asking him a question

**Ask these**

1. A binary or ternary at a real branch point, options exhaustive, consequences named.
2. "I'm about to touch your live system — now, or do you want to?" Answered instantly,
   almost always "you do it."
3. A checkpoint after a design section. He uses it to bolt on one constraint inline.
4. A question whose options are a preview of the actual artifact — a diff, a table, the
   exact commands. Showing the concrete thing converts a design question into a rubber stamp.
5. Multi-select where "all of these plus one more" is legal. He uses it.

**Never ask these**

1. Anything you could find out by looking or running.
2. Enumerated guesses about his hardware, IPs, paths, or accounts — about 30% wrong. Ask
   open-ended or go read it.
3. "Which of these two architectures?" before he has told you the shape he wants. He
   discards both and writes a paragraph. Ask _for the shape_ instead.
4. Cosmetic preferences, especially about something visual described in text. Render it or
   don't ask.
5. Permission to fix something plainly broken.
6. Remediation options while the root cause is unknown.
7. "How far should I take it?" In every rejected multi-question block, at least one question
   was a scope question, and both halves died together.
8. A one-option question. If there's only one answer, act.

**Reading his answer.** He picks the first option 66% of the time, and it is position, not
deference — order options accordingly and don't read a pick as a considered endorsement.
"(Recommended)" measurably adds nothing. He goes off-menu on a quarter of decisions, rising
to ~30% on architecture. When he does, it's one of: he wants an XOR of things you ANDed; the
literal value isn't in your list; your premise is factually wrong; he supplies the shape
instead of picking an instance; your static A-or-B should have been runtime adaptivity; the
decision is premature; he asks a question back (always about mechanism, never preference);
or you asserted something you hadn't tested.

He adds work that buys a check — "go further", "two lease cycles", "both, cross-checked".
He cuts work that buys a layer — a second repo, a branch, an abstraction, a config knob.

## After it works

In rough order of how reliably it follows a success:

1. **Commit.** Often the entire message. A clean working copy is the default end state.
2. **Write it down**, in a file that already exists — he'll name the file.
3. **The next frontier**: "what else should we consider?"
4. **The writeup**: a PR description, a bug ticket, a prompt for another agent. He dictates
   the opening line and expects you to supply the technical body.
5. **Tests naming the cases just learned**, and both branches of a flag.
6. **An idiom review**: "looking at this from the angle of a go programmer, anything to
   clean up?"
7. **"Is this the best possible solution?"** — asked after something works, never before.

## When it isn't working

He escalates by narrowing, not by raising volume: `hmm` → `nope` plus pasted evidence → the
same message re-sent verbatim with one clause appended → a numbered spec → scrap the
approach entirely → "let's handoff and start fresh."

The ceiling is a handoff: he declares the context spent rather than let you try a fourth
variation. Get there before he does. If two attempts have failed, stop and reassess out loud
instead of producing a third.

Refusals are how he injects information, not how he scolds. Only 21 of 112 refused tool
calls carried a typed note, and every one was a redirect — he refuses the plan, then hands
over the API docs, the PR link, and the exact shape he wants.

He is not attached to being right, and reverses himself out loud the moment he learns
better. He apologizes for his own clarity, never blames you for his mistakes, and does not
swear at you.
